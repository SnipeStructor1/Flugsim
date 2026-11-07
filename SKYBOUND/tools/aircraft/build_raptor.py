"""Generate SKYBOUND's original, unarmed jet. Run with Blender 4.3+ in background."""
import bpy
import math
from pathlib import Path
from mathutils import Vector

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def mat(name, color, metallic=0.0, rough=0.5):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Roughness'].default_value = rough
    return m
skin = mat('satin grey composite', (0.25, 0.29, 0.31), 0.38, 0.46)
light = mat('leading edges', (0.39, 0.42, 0.42), 0.48, 0.4)
dark = mat('dark intake and seams', (0.055, 0.065, 0.067), 0.25, 0.5)
glass = mat('gold tinted canopy', (0.19, 0.16, 0.095), 0.65, 0.12)
steel = mat('nozzle alloy', (0.16, 0.17, 0.17), 0.75, 0.31)

def mesh(name, verts, faces, material, smooth=False):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(material)
    if smooth:
        for p in me.polygons: p.use_smooth = True
    return ob

def slab(name, xy, z, thickness, material):
    n = len(xy)
    verts = [(x,y,z+thickness/2) for x,y in xy] + [(x,y,z-thickness/2) for x,y in xy]
    faces = [tuple(range(n)), tuple(range(n,2*n))[::-1]]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name, verts, faces, material)

def sphere(name, location, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=location)
    ob = bpy.context.object
    ob.name = name
    ob.scale = scale
    ob.data.materials.append(material)
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def box(name, center, size, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    ob=bpy.context.object
    ob.name=name
    ob.dimensions=size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(material)
    return ob

# Rings in x/y/z coordinates: positive Y points forward in Blender.
stations = [(9.45,.025,.03,.03),(7.5,.45,.26,.22),(5.2,.92,.48,.40),(2.5,1.40,.68,.62),(0,1.95,.74,.76),(-3.5,2.05,.68,.77),(-6.4,1.85,.54,.62),(-8.4,1.58,.42,.46),(-9.45,1.48,.25,.34)]
verts=[]
for y,w,top,bottom in stations:
    verts += [(-w,y,0),(-.78*w,y,top*.75),(0,y,top),(.78*w,y,top*.75),(w,y,0),(.76*w,y,-bottom*.7),(0,y,-bottom),(-.76*w,y,-bottom*.7)]
faces=[]
for i in range(len(stations)-1):
    for j in range(8): faces.append((i*8+j,i*8+(j+1)%8,(i+1)*8+(j+1)%8,(i+1)*8+j))
faces += [tuple(reversed(range(8))), tuple((len(stations)-1)*8+j for j in range(8))]
mesh('Fuselage', verts, faces, skin, True)
sphere('Canopy frame', (0,3.8,.68), (1.10,2.15,.57), dark)
sphere('Canopy tinted glass', (0,3.8,.77), (1.01,2.05,.52), glass)
for side in (-1,1):
    slab('Wing L' if side<0 else 'Wing R', [(side*1.0,4.1),(side*6.78,-1.2),(side*6.78,-2.0),(side*2.0,-4.4)], .05,.22,skin)
    slab('Tailplane L' if side<0 else 'Tailplane R', [(side*1.3,-4.9),(side*5.1,-7.45),(side*4.7,-8.2),(side*1.7,-7.8)], .20,.16,skin)
    control = slab('Flaperon L' if side<0 else 'Flaperon R', [(side*2.35,-3.48),(side*6.05,-1.92),(side*5.75,-2.24),(side*2.43,-3.80)], .12,.06,light)
    pivot = Vector((side*4.0, -2.7, .12))
    for vert in control.data.vertices: vert.co -= pivot
    control.location = pivot
    # Both outward canted fins are proper, closed meshes.
    pts=[(side*1.15, -4.0,.42),(side*2.2,-6.0,3.0),(side*2.2,-7.35,3.0),(side*1.62,-8.0,.42)]
    mesh('Vertical fin', pts+[(x+side*.10,y,z) for x,y,z in pts], [(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)], skin)
    slab('Wing leading edge', [(side*1.15,4.08),(side*6.78,-1.2),(side*6.58,-1.30),(side*1.15,3.91)], .18,.035,light)
    box('Intake', (side*1.48,.9,-.13), (.75,2.15,.65), dark)
    box('Nozzle surround', (side*.78,-9.1,-.05), (1.33,.78,.61), steel)
    box('Nozzle opening', (side*.78,-9.51,-.05), (1.14,.05,.45), dark)
    for j in range(5):
        box('Nozzle vane', (side*(.36+j*.21),-9.55,-.05), (.035,.06,.40), steel)
    # Fine strip on top surface, intentionally part of the material layout.
    slab('Panel marking', [(side*.48,-.2),(side*.52,-.2),(side*.52,-6.6),(side*.48,-6.6)], .745,.012,light)

# Front-to-back scale is approximately 18.9 m. No third-party assets.
out = Path(__file__).resolve().parents[2] / 'benchmarks/godot/flight/assets/raptor.glb'
bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', export_yup=True, export_apply=True)
print('GENERATED', out)
