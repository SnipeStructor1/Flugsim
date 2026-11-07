"""Validate the shared scene and run existing benchmark-tool regression tests."""
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
scene = json.loads((root / 'assets/shared/scene.json').read_text())
views = json.loads((root / 'assets/shared/visual_views.json').read_text())
assert set(views['views']) == {'mountains', 'sunset', 'lake', 'forest', 'clouds', 'ground', 'high_altitude'}
assert all(len(v['position_m']) == 3 and len(v['look_at_m']) == 3 and v['position_m'] != v['look_at_m'] for v in views['views'].values())
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
    print('SKIP: Godot unavailable; terrain, LOD, chunk, stream-planning, lifecycle, worker and async tests were not run', flush=True)
    raise SystemExit(0)
env = os.environ.copy()
if sys.platform == 'linux':
    for name, part in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        env[name] = str(root / '.tools/validation' / part)
check = subprocess.run([godot, '--headless', '--path', str(root / 'benchmarks/godot'), '--check-only', '--script', 'res://benchmark.gd'], capture_output=True, text=True, env=env, timeout=60)
if check.returncode != 0 or 'ERROR:' in check.stdout + check.stderr:
    print(check.stdout + check.stderr, file=sys.stderr)
    raise SystemExit(1)
print('BENCHMARK_SCRIPT_CHECK_PASS', flush=True)
for test in ['test_terrain.gd', 'test_lod.gd', 'test_chunk_mesh.gd', 'test_stream_plan.gd', 'test_stream_manager.gd', 'test_chunk_job.gd', 'test_stream_async.gd']:
    result = subprocess.run([godot, '--headless', '--path', str(root / 'benchmarks/godot'), '--script', 'res://' + test], env=env, timeout=60)
    if result.returncode:
        raise SystemExit(result.returncode)
for asynchronous in [False, True]:
    args = [godot, '--headless', '--path', str(root / 'benchmarks/godot'), '--rendering-method', 'gl_compatibility', '--', '--smoke=true', '--terrain-stream=true', '--stream-journey=true', '--profile=Medium', '--warmup=0', '--duration=20']
    if asynchronous:
        args.append('--stream-async=true')
    journey = subprocess.run(args, capture_output=True, text=True, env=env, timeout=60)
    output = journey.stdout + journey.stderr
    if journey.returncode != 0 or 'ERROR:' in output or 'STREAM_JOURNEY_PASS phases=5' not in output or output.count('STREAM_JOURNEY_PHASE ') != 5:
        print(output, file=sys.stderr)
        raise SystemExit(1)
    print(f'STREAM_JOURNEY_TEST_PASS async={asynchronous}: loading, unloading, high/extreme altitude, LOD, object visibility and placement', flush=True)
raise SystemExit(0)
