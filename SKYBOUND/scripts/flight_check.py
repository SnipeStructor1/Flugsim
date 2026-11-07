"""Render a flight-scene screenshot on the project-local CPU Vulkan stack."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import selectors
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--view', choices=['chase', 'cockpit', 'lake', 'far', 'aircraft', 'sunset', 'lake_jet'], default='chase')
    parser.add_argument('--frame', type=int, default=30, help='Capture after this many fixed simulation frames')
    parser.add_argument('--output', type=Path, required=True, help='New output directory')
    args = parser.parse_args()
    if args.frame < 1 or args.frame > 3600:
        parser.error('--frame must be between 1 and 3600')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    tools = ROOT / '.tools'
    binary = tools / 'godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
    portable = tools / 'portable/root'
    runtime = output / 'runtime'
    runtime.mkdir(mode=0o700)
    env = os.environ.copy()
    env.update({'XDG_RUNTIME_DIR': str(runtime), 'XDG_DATA_HOME': str(tools / 'flight-data'),
                'XDG_CONFIG_HOME': str(tools / 'flight-config'), 'XDG_CACHE_HOME': str(tools / 'flight-cache'),
                'VK_DRIVER_FILES': str(portable / 'usr/share/vulkan/icd.d/lvp_icd.json'),
                'LD_LIBRARY_PATH': str(portable / 'usr/lib/x86_64-linux-gnu') + (os.pathsep + env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else ''),
                'SKYBOUND_FLIGHT_SCREENSHOT': str(output / 'flight.png'), 'SKYBOUND_FLIGHT_CAPTURE_VIEW': args.view, 'SKYBOUND_FLIGHT_CAPTURE_FRAME': str(args.frame)})
    check = subprocess.run([str(binary), '--headless', '--path', str(ROOT / 'benchmarks/godot'), '--check-only', '--script', 'res://flight/flight_scene.gd'], capture_output=True, text=True, env=env, timeout=60)
    if check.returncode != 0 or 'ERROR:' in check.stdout + check.stderr:
        print(check.stdout + check.stderr, file=sys.stderr)
        return 1
    sources = sorted(p for p in (ROOT / 'benchmarks/godot/flight').glob('*') if p.suffix in ['.gd', '.gdshader', '.tscn'])
    source_sha256 = hashlib.sha256(b''.join(p.read_bytes() for p in sources)).hexdigest()
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
            command = [str(binary), '--display-driver', 'x11', '--audio-driver', 'Dummy', '--fixed-fps', '60', '--path', str(ROOT / 'benchmarks/godot'), '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', 'res://flight/flight.tscn']
            result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=180)
            text = result.stdout + result.stderr
            (output / 'flight.log').write_text(text, encoding='utf-8')
            if result.returncode or 'ERROR:' in text or 'FLIGHT_READY ' not in text or 'FLIGHT_CAPTURE_OK ' not in text:
                raise RuntimeError('Flight screenshot failed; inspect flight.log')
            data = (output / 'flight.png').read_bytes()
            if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (1920, 1080):
                raise RuntimeError('Unexpected screenshot format or dimensions')
            info = {'status': 'PASS', 'mode': 'software visual check; not a benchmark', 'view': args.view, 'simulation_frame': args.frame, 'width': 1920, 'height': 1080,
                    'image_sha256': hashlib.sha256(data).hexdigest(), 'flight_source_sha256': source_sha256, 'command': command}
            (output / 'summary.json').write_text(json.dumps(info, indent=2) + '\n', encoding='utf-8')
            print('FLIGHT_RENDER_PASS', output / 'flight.png')
        finally:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
