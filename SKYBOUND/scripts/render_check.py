"""Real Forward+ screenshots on portable llvmpipe; never produce performance data."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import selectors
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profiles', nargs='+', choices=['Medium', 'High', 'Ultra'], default=['Medium', 'High', 'Ultra'])
    parser.add_argument('--pipeline-check', action='store_true', help='Also exercise real CSV collection: Medium/1080p, 30s warmup + 60s capture, 3 repetitions')
    parser.add_argument('--output', type=Path, required=True, help='New output folder')
    args = parser.parse_args()
    tools = ROOT / '.tools'
    binary = tools / 'godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
    portable = tools / 'portable/root'
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    runtime = output / 'runtime'
    runtime.mkdir(mode=0o700)
    env = os.environ.copy()
    env.update({'XDG_RUNTIME_DIR': str(runtime), 'XDG_DATA_HOME': str(tools / 'render-data'),
                'XDG_CONFIG_HOME': str(tools / 'render-config'), 'XDG_CACHE_HOME': str(tools / 'render-cache'),
                'VK_DRIVER_FILES': str(portable / 'usr/share/vulkan/icd.d/lvp_icd.json'),
                'LD_LIBRARY_PATH': str(portable / 'usr/lib/x86_64-linux-gnu') + (os.pathsep + env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else '')})
    report = {'mode': 'SOFTWARE_RENDER_CHECK', 'performance_measured': False, 'runs': []}
    with (output / 'xvfb.log').open('w') as log:
        server = subprocess.Popen([str(portable / 'usr/bin/Xvfb'), '-displayfd', '1', '-screen', '0', '1920x1080x24', '-nolisten', 'tcp', '-ac'], stdout=subprocess.PIPE, stderr=log, env=env)
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(server.stdout, selectors.EVENT_READ)
                if not selector.select(timeout=15):
                    raise RuntimeError('Xvfb readiness timeout')
            number = server.stdout.readline().decode().strip()
            if not number.isdecimal():
                raise RuntimeError('Xvfb did not return a display number')
            env['DISPLAY'] = ':' + number
            for profile in args.profiles:
                image = output / f'{profile}.png'
                command = [str(binary), '--display-driver', 'x11', '--audio-driver', 'Dummy', '--path', str(ROOT / 'benchmarks/godot'), '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', '--', '--render-check=true', f'--profile={profile}', '--warmup=0', f'--capture={image}']
                start = time.monotonic()
                result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=300)
                text = result.stdout + result.stderr
                (output / f'{profile}.log').write_text(text, encoding='utf-8')
                if result.returncode or 'ERROR:' in text or 'SKYBOUND_COMPLETE ' not in text or not image.exists():
                    raise RuntimeError(f'{profile}: engine render check failed; inspect log')
                data = image.read_bytes()
                if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (1920, 1080):
                    raise RuntimeError('Unexpected screenshot format or actual resolution')
                ready = json.loads(next(line.split('SKYBOUND_READY ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_READY ')))
                complete = json.loads(next(line.split('SKYBOUND_COMPLETE ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_COMPLETE ')))
                if not ready['render_check'] or not complete['render_check'] or complete['total_frames'] < 4:
                    raise RuntimeError('Not a valid render-check run')
                report['runs'].append({'profile': profile, 'status': 'PASS', 'wall_seconds_including_shader_compilation': time.monotonic()-start,
                                       'engine_settings': ready, 'completion': complete, 'screenshot': image.name, 'sha256': hashlib.sha256(data).hexdigest()})
                print(profile, 'render PASS (not a performance benchmark)', flush=True)
            if args.pipeline_check:
                import sys
                subprocess.run([sys.executable, str(ROOT / 'benchmarks/tools/run.py'), '--godot', str(binary), '--software-validation', '--profiles', 'Medium', '--resolutions', '1920x1080', '--output', str(output / 'pipeline')], env=env, check=True)
        finally:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
            report['status'] = 'PASS' if len(report['runs']) == len(args.profiles) else 'FAIL'
            (output / 'render_summary.json').write_text(json.dumps(report, indent=2) + '\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
