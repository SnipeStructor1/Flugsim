"""Run flight-model and scene checks without running the frozen terrain tests."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    local = ROOT / '.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=str(local) if local.is_file() else (shutil.which('godot') or shutil.which('godot4')))
    args = parser.parse_args()
    if not args.godot:
        parser.error('Godot is missing; pass --godot')
    env = os.environ.copy()
    if sys.platform == 'linux':
        for name, part in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[name] = str(ROOT / '.tools/flight-validation' / part)
    common = [args.godot, '--headless', '--path', str(ROOT / 'benchmarks/godot')]
    checks = [
        (common + ['--script', 'res://flight/test_flight_model.gd'], {}, 'FLIGHT_MODEL_TEST_PASS'),
        (common + ['--fixed-fps', '60', '--quit-after', '1000', 'res://flight/flight.tscn'], {'SKYBOUND_FLIGHT_AUTOTEST': '1'}, 'FLIGHT_SCENE_TEST_PASS'),
        (common + ['--fixed-fps', '60', '--quit-after', '5000', 'res://flight/flight.tscn'], {'SKYBOUND_FLIGHT_JOURNEY': '1'}, 'FLIGHT_JOURNEY_TEST_PASS'),
    ]
    for preset in ['Medium', 'High', 'Ultra', 'Cinematic']:
        checks.append((common + ['--fixed-fps', '60', '--quit-after', '1000', 'res://flight/flight.tscn'],
                       {'SKYBOUND_FLIGHT_AUTOTEST': '1', 'SKYBOUND_GRAPHICS_PRESET': preset}, 'FLIGHT_SCENE_TEST_PASS'))
    for command, extra, marker in checks:
        run_env = env.copy()
        run_env.update(extra)
        result = subprocess.run(command, capture_output=True, text=True, env=run_env, timeout=60)
        output = result.stdout + result.stderr
        if result.returncode or 'ERROR:' in output or marker not in output:
            print(output, file=sys.stderr)
            return 1
        if 'SKYBOUND_GRAPHICS_PRESET' in extra and f"FLIGHT_GRAPHICS_PRESET {extra['SKYBOUND_GRAPHICS_PRESET']} " not in output:
            print(output, file=sys.stderr)
            return 1
        print(next(line for line in output.splitlines() if line.startswith(marker)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
