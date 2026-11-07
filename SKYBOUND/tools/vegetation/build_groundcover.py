"""Create original low-poly groundcover; run with Blender in background."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
random.seed(44172)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.95
 m.use_backface_culling=False
 return m
colors=[mat('grass deep',(.055,.115,.035)),mat('grass',(.10,.20,.055)),mat('grass tips',(.17,.26,.075)),mat('herb',(.06,.15,.055)),mat('flower white',(.72,.72,.52)),mat('flower yellow',(.70,.49,.09))]
verts=[];faces=[];indices=[]
def tri(a,b,c,color):
 base=len(verts);verts.extend([a,b,c]);faces.append((base,base+1,base+2));indices.append(color)
# Multiple individual blades; one instance represents a loose clump of plants.
for i in range(72):
 r=2.4*math.sqrt(random.random());a=random.uniform(0,math.tau)
 base=Vector((r*math.cos(a),r*math.sin(a),0));h=random.uniform(.32,.83)
 outward=Vector((math.cos(a),math.sin(a),0));side=Vector((-outward.y,outward.x,0))
 w=random.uniform(.025,.065);bend=random.uniform(.06,.27)
 top=base+Vector((0,0,h))+outward*bend
 mid=base+Vector((0,0,h*.55))+outward*bend*.3
 color=random.randrange(3)
 tri(base-side*w,base+side*w,mid+side*w*.35,color)
 tri(base-side*w,mid+side*w*.35,mid-side*w*.35,color)
 tri(mid-side*w*.35,mid+side*w*.35,top,color)
# Taller, broad herb rosettes and small pale/yellow meadow flowers.
for i in range(12):
 a=random.uniform(0,math.tau);r=random.uniform(0,2.2);center=Vector((r*math.cos(a),r*math.sin(a),0))
 for j in range(5):
  b=j*math.tau/5+a;d=Vector((math.cos(b),math.sin(b),0));side=Vector((-d.y,d.x,0))
  tip=center+d*random.uniform(.20,.38)+Vector((0,0,random.uniform(.15,.30)))
  tri(center,center+d*.10+side*.06+Vector((0,0,.10)),tip,3)
  tri(center,tip,center+d*.10-side*.06+Vector((0,0,.10)),3)
 if i%2==0:
  top=center+Vector((0,0,random.uniform(.35,.62))); petal=.075
  for j in range(5):
   b=j*math.tau/5;d=Vector((math.cos(b),math.sin(b),0));side=Vector((-d.y,d.x,0))
   tri(top,top+d*petal+side*petal*.4,top+d*petal-side*petal*.4,4 if i%4==0 else 5)
mesh=bpy.data.meshes.new('Meadow groundcover');mesh.from_pydata(verts,[],faces);mesh.update()
obj=bpy.data.objects.new('Meadow groundcover',mesh);bpy.context.collection.objects.link(obj)
for m in colors:mesh.materials.append(m)
for p,c in zip(mesh.polygons,indices):p.material_index=c
out=Path(__file__).resolve().parents[2]/'benchmarks/godot/flight/assets/vegetation/groundcover.glb'
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_yup=True,export_apply=True)
print('GENERATED',out)
