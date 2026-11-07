"""Validate the shared scene and run existing benchmark-tool regression tests."""
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
scene = json.loads((root / 'assets/shared/scene.json').read_text())
assert scene['schema_version'] == 1
assert scene['camera']['positions_m'][0] == scene['camera']['positions_m'][-1]
assert scene['camera']['duration_s'] == 60
assert scene['terrain']['grid_cells'] == 128
assert set(scene['profiles']) == {'Medium', 'High', 'Ultra'}
assert scene['resolutions'] == [[1920,1080], [2560,1440], [3840,2160]]
result = subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', str(root / 'simulation/tests'), '-v'], cwd=root)
if result.returncode:
    raise SystemExit(result.returncode)
local_godot = root / '.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
godot = str(local_godot) if local_godot.is_file() else (shutil.which('godot') or shutil.which('godot4'))
if not godot:
    print('SKIP: Godot unavailable; terrain, LOD and chunk tests were not run', flush=True)
    raise SystemExit(0)
env = os.environ.copy()
if sys.platform == 'linux':
    for name, part in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        env[name] = str(root / '.tools/validation' / part)
for test in ['test_terrain.gd', 'test_lod.gd', 'test_chunk_mesh.gd']:
    result = subprocess.run([godot, '--headless', '--path', str(root / 'benchmarks/godot'), '--script', 'res://' + test], env=env, timeout=60)
    if result.returncode:
        raise SystemExit(result.returncode)
raise SystemExit(0)
