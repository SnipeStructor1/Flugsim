"""Validate the shared scene and run existing benchmark-tool regression tests."""
import json
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
raise SystemExit(subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', str(root / 'simulation/tests'), '-v'], cwd=root).returncode)
