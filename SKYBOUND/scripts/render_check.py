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
    parser.add_argument('--resolution', choices=['1920x1080', '2560x1440', '3840x2160'], default='1920x1080')
    parser.add_argument('--compare-dir', type=Path, help='Compare against same-named reference PNGs')
    parser.add_argument('--max-mean-difference', type=float, help='Optional explicit comparison failure threshold (0–255)')
    parser.add_argument('--preview', action='store_true', help='Use 960x540 for quicker visual diagnostics; not a benchmark resolution')
    parser.add_argument('--views', nargs='+', choices=['benchmark', 'mountains', 'sunset', 'lake', 'forest', 'clouds', 'ground', 'high_altitude'], default=['benchmark'])
    parser.add_argument('--profiles', nargs='+', choices=['Medium', 'High', 'Ultra'], default=['Medium', 'High', 'Ultra'])
    parser.add_argument('--terrain-stream', action='store_true', help='Exercise experimental chunk streaming instead of the baseline mesh')
    parser.add_argument('--pipeline-check', action='store_true', help='Also exercise real CSV collection: Medium/1080p, 30s warmup + 60s capture, 3 repetitions')
    parser.add_argument('--output', type=Path, required=True, help='New output folder')
    args = parser.parse_args()
    if args.max_mean_difference is not None and (args.compare_dir is None or not 0 <= args.max_mean_difference <= 255):
        parser.error('--max-mean-difference requires --compare-dir and a value between 0 and 255')
    if args.pipeline_check and (args.terrain_stream or args.views != ['benchmark']):
        parser.error('Performance pipeline checks require the baseline terrain and benchmark view')
    if args.preview and args.resolution != '1920x1080':
        parser.error('--preview cannot be combined with --resolution')
    width, height = (960, 540) if args.preview else map(int, args.resolution.split('x'))
    compare = None
    if args.compare_dir:
        import compare_images
        compare = compare_images.compare
        for profile in args.profiles:
            for view in args.views:
                label = profile if view == 'benchmark' else f'{profile}_{view}'
                if not (args.compare_dir / f'{label}.png').is_file():
                    parser.error(f'Missing reference image: {label}.png')
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
    check = subprocess.run([str(binary), '--headless', '--path', str(ROOT / 'benchmarks/godot'), '--check-only', '--script', 'res://benchmark.gd'], capture_output=True, text=True, env=env, timeout=60)
    if check.returncode != 0 or 'ERROR:' in check.stdout + check.stderr:
        raise RuntimeError('Benchmark script validation failed: ' + check.stdout + check.stderr)
    source_files = sorted(p for p in (ROOT / 'benchmarks/godot').glob('*') if p.is_file() and p.suffix in ['.gd', '.gdshader', '.tscn', '.godot'])
    code_sha256 = hashlib.sha256(b''.join(p.read_bytes() for p in source_files)).hexdigest()
    report = {'mode': 'SOFTWARE_RENDER_CHECK', 'performance_measured': False, 'resolution': [width, height], 'code_sha256': code_sha256, 'scene_sha256': hashlib.sha256((ROOT / 'assets/shared/scene.json').read_bytes()).hexdigest(), 'views_sha256': hashlib.sha256((ROOT / 'assets/shared/visual_views.json').read_bytes()).hexdigest(), 'runs': []}
    comparisons_ok = True
    with (output / 'xvfb.log').open('w') as log:
        server = subprocess.Popen([str(portable / 'usr/bin/Xvfb'), '-displayfd', '1', '-screen', '0', f'{width}x{height}x24', '-nolisten', 'tcp', '-ac'], stdout=subprocess.PIPE, stderr=log, env=env)
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(server.stdout, selectors.EVENT_READ)
                if not selector.select(timeout=15):
                    raise RuntimeError('Xvfb readiness timeout')
            number = server.stdout.readline().decode().strip()
            if not number.isdecimal():
                raise RuntimeError('Xvfb did not return a display number')
            env['DISPLAY'] = ':' + number
            for profile, view in ((p, v) for p in args.profiles for v in args.views):
                label = profile if view == 'benchmark' else f'{profile}_{view}'
                image = output / f'{label}.png'
                command = [str(binary), '--display-driver', 'x11', '--audio-driver', 'Dummy', '--path', str(ROOT / 'benchmarks/godot'), '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', '--', '--render-check=true', f'--profile={profile}', '--warmup=0', f'--capture={image}', f'--view={view}']
                if args.terrain_stream:
                    command.append('--terrain-stream=true')
                command.extend([f'--width={width}', f'--height={height}'])
                start = time.monotonic()
                result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=300)
                text = result.stdout + result.stderr
                (output / f'{label}.log').write_text(text, encoding='utf-8')
                if result.returncode or 'ERROR:' in text or 'SKYBOUND_COMPLETE ' not in text or not image.exists():
                    raise RuntimeError(f'{profile}: engine render check failed; inspect log')
                data = image.read_bytes()
                if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (width, height):
                    raise RuntimeError('Unexpected screenshot format or actual resolution')
                ready = json.loads(next(line.split('SKYBOUND_READY ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_READY ')))
                complete = json.loads(next(line.split('SKYBOUND_COMPLETE ', 1)[1] for line in text.splitlines() if line.startswith('SKYBOUND_COMPLETE ')))
                if not ready['render_check'] or not complete['render_check'] or complete['total_frames'] < 4 or ready['view'] != view or ready['terrain_stream'] != args.terrain_stream or (args.terrain_stream and complete['resident_chunks'] == 0):
                    raise RuntimeError('Not a valid render-check run')
                run = {'profile': profile, 'view': view, 'status': 'PASS', 'wall_seconds_including_shader_compilation': time.monotonic()-start,
                       'engine_settings': ready, 'completion': complete, 'screenshot': image.name, 'sha256': hashlib.sha256(data).hexdigest()}
                if compare is not None:
                    comparison = compare(args.compare_dir / image.name, image)
                    comparison['max_mean_difference'] = args.max_mean_difference
                    comparison['within_limit'] = None if args.max_mean_difference is None else comparison['mean_absolute_rgb_difference_0_255'] <= args.max_mean_difference
                    run['comparison'] = comparison
                    if comparison['within_limit'] is False:
                        comparisons_ok = False
                report['runs'].append(run)
                print(label, 'render PASS; comparison FAIL' if run.get('comparison', {}).get('within_limit') is False else 'render PASS (not a performance benchmark)', flush=True)
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
            report['status'] = 'PASS' if len(report['runs']) == len(args.profiles) * len(args.views) and comparisons_ok else 'FAIL'
            (output / 'render_summary.json').write_text(json.dumps(report, indent=2) + '\n')
    return 0 if comparisons_ok else 1


if __name__ == '__main__':
    raise SystemExit(main())
