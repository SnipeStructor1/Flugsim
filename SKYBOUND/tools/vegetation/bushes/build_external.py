"""Replace bush_00..09 with reproducible, attributed MIT bush assets.

1. Run `blender -b --python tools/vegetation/bushes/build_bushes.py` first.
2. Check out https://github.com/jalapenoseed/groundcover-gift at the pinned
   commit below; install that project's dependencies in a separate environment.
3. Run `python tools/vegetation/bushes/build_external.py /path/to/checkout`.

This runs the pinned upstream generator locally, with no network access. Check
that project's source and dependencies before running it. The output models
remain derived MIT material, not original SKYBOUND geometry.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

PIN = '848a3416d6d347077d330443e6419578302b357e'
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'benchmarks/godot/flight/assets/vegetation/bushes'
SOURCE = 'https://github.com/jalapenoseed/groundcover-gift'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('checkout', type=Path)
    args = parser.parse_args()
    source = args.checkout.resolve()
    commit = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if commit != PIN:
        parser.error('Upstream checkout must be exactly ' + PIN)
    catalog_path = OUT / 'catalog.json'
    catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
    if len(catalog.get('variants', [])) != 25:
        parser.error('Build the original 25 variants first')
    with tempfile.TemporaryDirectory(prefix='skybound-bush-gen-') as temp:
        root = Path(temp)
        for base, preset, seed in [(0, 'scrub_oak', 8300), (5, 'willow_bush', 8400)]:
            dest = root / preset
            subprocess.run([sys.executable, str(source / 'generate.py'), '--preset', preset,
                            '--seed', str(seed), '--variants', '5', '--cell', '256',
                            '--density', '1.25', '--out', str(dest)], check=True, cwd=source)
            generated = json.loads((dest / 'manifest.json').read_text(encoding='utf-8'))
            by_seed = {a['seed']: a for a in generated['assets'] if a['lod'] == 0}
            for i in range(5):
                record = by_seed[seed+i]
                asset_id = f'bush_{base+i:02d}'
                target = OUT / (asset_id + '.glb')
                shutil.copyfile(dest / record['path'], target)
                catalog['variants'][base+i] = {
                    'id': asset_id, 'family': preset, 'form': 'seed_' + str(seed+i),
                    'source': SOURCE, 'source_commit': PIN, 'license': 'MIT',
                    'seed': seed+i, 'atlas_cell': 256, 'density': 1.25,
                    'estimated_height_m': record['dimensions_m'][1],
                    'triangles': record['triangles'],
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                }
    shutil.copyfile(source / 'LICENSE', OUT / 'JALAPENOSEED-MIT.txt')
    shutil.copyfile(source / 'ASSET-LICENSE.md', OUT / 'JALAPENOSEED-ASSET-LICENSE.md')
    catalog['source'] = 'Variants 00–09: JalapeñoSeed Groundcover Gift (MIT); variants 10–24: original procedural geometry.'
    for record in catalog['variants'][10:]:
        record['source'] = 'SKYBOUND original procedural geometry'
        record['license'] = 'project-authored; project license not yet specified'
    catalog_path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('EXTERNAL_BUSH_BUILD_PASS variants=10 source=' + PIN)

if __name__ == '__main__':
    main()
