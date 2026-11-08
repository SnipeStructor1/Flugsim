"""Render a 25-bush visual audit on the local software-Vulkan stack."""
import argparse
import os
from pathlib import Path
import selectors
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    tools = ROOT / '.tools'
    portable = tools / 'portable/root'
    binary = tools / 'godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
    runtime = output / 'runtime'
    runtime.mkdir(mode=0o700)
    env = os.environ.copy()
    env.update({'XDG_RUNTIME_DIR': str(runtime), 'XDG_DATA_HOME': str(tools / 'flight-data'),
                'XDG_CONFIG_HOME': str(tools / 'flight-config'), 'XDG_CACHE_HOME': str(tools / 'flight-cache'),
                'VK_DRIVER_FILES': str(portable / 'usr/share/vulkan/icd.d/lvp_icd.json'),
                'LD_LIBRARY_PATH': str(portable / 'usr/lib/x86_64-linux-gnu') + (os.pathsep + env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else ''),
                'SKYBOUND_BUSH_SHOWCASE': str(output / 'bushes.png')})
    with (output / 'xvfb.log').open('w') as log:
        server = subprocess.Popen([str(portable / 'usr/bin/Xvfb'), '-displayfd', '1', '-screen', '0', '1920x1080x24', '-nolisten', 'tcp', '-ac'], stdout=subprocess.PIPE, stderr=log, env=env)
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(server.stdout, selectors.EVENT_READ)
                if not selector.select(timeout=15): raise RuntimeError('Xvfb did not start')
            display = server.stdout.readline().decode().strip()
            if not display.isdecimal(): raise RuntimeError('Xvfb returned invalid display')
            env['DISPLAY'] = ':' + display
            command = [str(binary), '--display-driver', 'x11', '--audio-driver', 'Dummy', '--fixed-fps', '60', '--path', str(ROOT / 'benchmarks/godot'), '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', '--script', 'res://flight/bush_showcase.gd']
            result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=240)
            text = result.stdout + result.stderr
            (output / 'showcase.log').write_text(text, encoding='utf-8')
            image = output / 'bushes.png'
            if result.returncode or 'ERROR:' in text or 'BUSH_SHOWCASE_CAPTURED ' not in text or not image.exists(): raise RuntimeError('Visual audit failed; see showcase.log')
            data = image.read_bytes()
            if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (1920, 1080): raise RuntimeError('Unexpected image dimensions')
            print('BUSH_SHOWCASE_PASS', image)
        finally:
            server.terminate()
            try: server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill(); server.wait()
    return 0

if __name__ == '__main__': main()
