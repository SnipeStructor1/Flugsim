"""Make a conifer-shaped CC-BY tree variant from Ricardo Sanchez's tree.
Usage: blender -b --python tools/vegetation/build_conifer.py -- path/to/scene.gltf
See assets/licenses/README.md for source and attribution.
"""
import bpy, sys
from pathlib import Path
from mathutils import Matrix
source = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
if not meshes: raise RuntimeError('Missing source geometry')
for obj in meshes:
 transform=obj.matrix_world.copy()
 is_leaves='leaves' in obj.name.lower()
 for vertex in obj.data.vertices:
  v=(transform @ vertex.co)*(15.0/2470.546)
  if is_leaves:
   factor=max(0.12,min(1.15,1.40-(v.z/15.0)*1.35))
   v.x*=factor;v.y*=factor
  v.z*=1.15
  vertex.co=v
 obj.parent=None;obj.matrix_world=Matrix.Identity(4)
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();meshes[0].name='AlpineTreeVariant'
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH': bpy.data.objects.remove(obj,do_unlink=True)
out=Path(__file__).resolve().parents[2]/'benchmarks/godot/flight/assets/vegetation/alpine_fir.glb'
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_yup=True,export_apply=True)
print('GENERATED',out)
