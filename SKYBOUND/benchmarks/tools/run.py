"""Launch isolated Godot repetitions, collect evidence, fail on runtime errors."""
import argparse
import ctypes
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time
from analyze import analyze, write_report

ROOT = Path(__file__).resolve().parents[2]
LOCAL_GODOT = ROOT / '.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'


def hardware():
    memory = None
    cpu = platform.processor() or None
    if sys.platform == 'linux':
        for line in Path('/proc/meminfo').read_text().splitlines():
            if line.startswith('MemTotal:'):
                memory = int(line.split()[1]) * 1024
        for line in Path('/proc/cpuinfo').read_text().splitlines():
            if line.startswith('model name'):
                cpu = line.split(':', 1)[1].strip()
                break
    elif sys.platform == 'win32':
        class MemoryStatus(ctypes.Structure):
            _fields_ = [('length', ctypes.c_ulong), ('load', ctypes.c_ulong)] + [(name, ctypes.c_ulonglong) for name in ['total', 'avail', 'page_total', 'page_avail', 'virtual_total', 'virtual_avail', 'extended']]
        status = MemoryStatus()
        status.length = ctypes.sizeof(status)
        if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
            memory = status.total
    return {'os': platform.platform(), 'cpu': cpu, 'logical_cpus': os.cpu_count(),
            'ram_bytes': memory, 'gpu_target': 'RTX 5070 Desktop 12 GB (user target, not detected hardware)'}


def gpu_sample():
    executable = shutil.which('nvidia-smi')
    if not executable:
        return None
    try:
        result = subprocess.run([executable, '--query-gpu=index,name,driver_version,utilization.gpu,memory.used,temperature.gpu', '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=3, check=True)
        import csv
        rows = []
        for row in csv.reader(result.stdout.splitlines(), skipinitialspace=True):
            def number(value):
                try:
                    return float(value)
                except ValueError:
                    return None
            rows.append(dict(zip(['index', 'name', 'driver', 'gpu_utilization_percent', 'vram_used_mib', 'temperature_c'], row[:3] + [number(v) for v in row[3:]])))
        return rows
    except (OSError, subprocess.SubprocessError):
        return None


def process_sample(pid, previous):
    """Process RSS and CPU, normalized to all logical CPUs, not total system load."""
    try:
        if sys.platform == 'linux':
            fields = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
            ticks = (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')
            rss = int(fields[21]) * os.sysconf('SC_PAGE_SIZE')
        elif sys.platform == 'win32':
            from ctypes import wintypes
            kernel = ctypes.WinDLL('kernel32', use_last_error=True)
            kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
            kernel.OpenProcess.restype = wintypes.HANDLE
            kernel.CloseHandle.argtypes = [wintypes.HANDLE]
            kernel.GetProcessTimes.argtypes = [wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4
            class Counters(ctypes.Structure):
                _fields_ = [('cb', wintypes.DWORD), ('faults', wintypes.DWORD)] + [(name, ctypes.c_size_t) for name in ['peak_working', 'working', 'peak_paged', 'paged', 'peak_nonpaged', 'nonpaged', 'pagefile', 'peak_pagefile']]
            handle = kernel.OpenProcess(0x410, False, pid)
            if not handle:
                return None, previous
            try:
                times = [wintypes.FILETIME() for _ in range(4)]
                counters = Counters()
                counters.cb = ctypes.sizeof(counters)
                psapi = ctypes.WinDLL('psapi')
                psapi.GetProcessMemoryInfo.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
                if not kernel.GetProcessTimes(handle, *(ctypes.byref(t) for t in times)) or not psapi.GetProcessMemoryInfo(handle, ctypes.byref(counters), counters.cb):
                    return None, previous
                ticks = sum((t.dwHighDateTime << 32) + t.dwLowDateTime for t in times[2:]) / 10_000_000
                rss = counters.working
            finally:
                kernel.CloseHandle(handle)
        else:
            return None, previous
        now = time.monotonic()
        cpu = None if previous is None else max(0, (ticks - previous[1]) / (now - previous[0]) * 100 / (os.cpu_count() or 1))
        return {'process_rss_bytes': rss, 'process_cpu_normalized_percent': cpu}, (now, ticks)
    except (OSError, ValueError, IndexError):
        return None, previous


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=str(LOCAL_GODOT) if LOCAL_GODOT.is_file() else (shutil.which('godot') or shutil.which('godot4')))
    parser.add_argument('--smoke', action='store_true')
    parser.add_argument('--software-validation', action='store_true', help='Explicit CPU-renderer pipeline check; never target-hardware evidence')
    parser.add_argument('--profiles', nargs='+', choices=['Medium', 'High', 'Ultra'], default=['Medium', 'High', 'Ultra'])
    parser.add_argument('--resolutions', nargs='+', choices=['1920x1080', '2560x1440', '3840x2160'], default=['1920x1080', '2560x1440', '3840x2160'])
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--warmup', type=float)
    parser.add_argument('--duration', type=float)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.smoke and args.software_validation:
        parser.error('Smoke and software validation are separate modes')
    if not args.godot:
        parser.error('Godot executable missing; supply --godot. No automatic downloads.')
    warmup = args.warmup if args.warmup is not None else (0.1 if args.smoke else 30)
    duration = args.duration if args.duration is not None else (0.5 if args.smoke else 60)
    if args.repeats < 3 or warmup < (0 if args.smoke else 30) or duration < (0.1 if args.smoke else 60):
        parser.error('At least 3 repeats; measured runs need warmup >=30s and duration >=60s')
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    folder = (args.output or ROOT / 'benchmarks/results/runs' / stamp).resolve()
    # Avoid mixing measurements from different invocations.
    folder.mkdir(parents=True, exist_ok=False)
    version = subprocess.run([args.godot, '--version'], capture_output=True, text=True, timeout=10, check=True).stdout.strip()
    scene_hash = hashlib.sha256((ROOT / 'assets/shared/scene.json').read_bytes()).hexdigest()
    source_hash = hashlib.sha256(b''.join(p.read_bytes() for p in sorted((ROOT / 'benchmarks/godot').glob('*')) if p.is_file() and p.suffix in ['.gd', '.tscn', '.godot'])).hexdigest()
    summary = {'schema_version': 1, 'created_utc': stamp, 'engine': version, 'mode': 'smoke' if args.smoke else ('software-validation' if args.software_validation else 'measured'),
               'hardware': hardware(), 'gpu_observation': gpu_sample(), 'scene_sha256': scene_hash, 'source_sha256': source_hash,
               'frame_generation': False, 'upscaling': 'native', 'render_scale': 1.0,
               'warmup_s': warmup, 'duration_s': duration, 'status': 'RUNNING', 'runs': []}
    env = os.environ.copy()
    if sys.platform == 'linux':
        for name, part in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[name] = str(folder / 'userdata' / part)
    failed = False
    for profile in args.profiles:
        for resolution in args.resolutions:
            width, height = map(int, resolution.split('x'))
            for repeat in range(1, args.repeats + 1):
                name = f'{profile}_{resolution}_{repeat}'
                csv_path = folder / f'{name}.csv'
                command = [args.godot, '--path', str(ROOT / 'benchmarks/godot'), '--audio-driver', 'Dummy']
                command += ['--headless', '--max-fps', '120', '--rendering-method', 'gl_compatibility'] if args.smoke else ['--rendering-method', 'forward_plus']
                command += ['--', f'--profile={profile}', f'--width={width}', f'--height={height}', f'--warmup={warmup}', f'--duration={duration}', f'--smoke={str(args.smoke).lower()}']
                if not args.smoke:
                    command.append(f'--output={csv_path}')
                run = {'profile': profile, 'width': width, 'height': height, 'repeat': repeat, 'command': command, 'metrics': None, 'telemetry': []}
                print(name, flush=True)
                try:
                    with (folder / f'{name}.log').open('w', encoding='utf-8') as log:
                        start = time.monotonic()
                        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=env)
                        previous = None
                        while child.poll() is None:
                            if time.monotonic() - start > warmup + duration + 300:
                                child.kill()
                                child.wait()
                                raise RuntimeError('Engine timeout')
                            sample, previous = process_sample(child.pid, previous)
                            run['telemetry'].append({'since_launch_s': time.monotonic()-start, 'process': sample, 'gpus': gpu_sample() if not args.smoke else None})
                            time.sleep(.25 if args.smoke else 1)
                    text = (folder / f'{name}.log').read_text(encoding='utf-8')
                    if child.returncode != 0 or 'ERROR:' in text or 'SKYBOUND_COMPLETE ' not in text:
                        raise RuntimeError(f'Engine failure (exit {child.returncode}); inspect {name}.log')
                    ready = json.loads(next(line.split('SKYBOUND_READY ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_READY ')))
                    complete = json.loads(next(line.split('SKYBOUND_COMPLETE ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_COMPLETE ')))
                    is_software = any(name in ready['adapter'].lower() for name in ['llvmpipe', 'lavapipe', 'softpipe', 'microsoft basic render'])
                    if not args.smoke and is_software != args.software_validation:
                        raise RuntimeError('Software renderer requires --software-validation; do not label it as a hardware benchmark')
                    run['engine_settings'] = ready
                    run['completion'] = complete
                    if ready['smoke'] != args.smoke or complete['frames'] < 2:
                        raise RuntimeError('Invalid engine completion evidence')
                    if not args.smoke:
                        run['metrics'] = analyze(csv_path)
                        if run['metrics']['sampled_seconds'] < duration * .95 or run['metrics']['frames'] != complete['frames']:
                            raise RuntimeError('Incomplete measured interval')
                    run['status'] = 'PASS'
                except (OSError, ValueError, subprocess.SubprocessError, RuntimeError, StopIteration) as error:
                    run['status'] = 'FAIL'
                    run['error'] = str(error)
                    failed = True
                summary['runs'].append(run)
                (folder / 'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=False), encoding='utf-8')
                if failed:
                    break
            if failed:
                break
        if failed:
            break
    summary['status'] = 'FAIL' if failed else ('FUNCTIONAL_PASS_NOT_A_GPU_BENCHMARK' if args.smoke else ('SOFTWARE_PIPELINE_VALIDATED_NOT_TARGET_HARDWARE' if args.software_validation else 'MEASURED'))
    (folder / 'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=False) + '\n', encoding='utf-8')
    write_report(summary, folder / 'report.md')
    print(folder)
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
