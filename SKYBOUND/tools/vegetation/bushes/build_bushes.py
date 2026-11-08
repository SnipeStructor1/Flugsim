"""Build 25 original, stylized alpine shrubs as independently selectable GLBs.

Usage: blender --background --python tools/vegetation/bushes/build_bushes.py
No external models or textures are used. Blender Z-up is exported to Godot +Y.
The models are inspired by vegetation types, not botanical reconstructions.
After this step run build_external.py to replace variants 00–09 with the
attributed JalapeñoSeed generated models and update the catalog.
"""
import bpy
import math
import random
import hashlib
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'benchmarks/godot/flight/assets/vegetation/bushes'
OUT.mkdir(parents=True, exist_ok=True)

FAMILIES = [
    dict(name='alpenrose', height=1.05, radius=0.72, branches=13, leaf_length=0.15, leaf_width=0.055, needle=False, flower='rose', greens=[(0.055,0.13,0.055), (0.09,0.21,0.07), (0.14,0.25,0.09)]),
    dict(name='heidelbeere', height=0.67, radius=0.70, branches=15, leaf_length=0.075, leaf_width=0.033, needle=False, flower='berry', greens=[(0.07,0.15,0.045), (0.13,0.24,0.06), (0.18,0.29,0.09)]),
    dict(name='wacholder', height=1.00, radius=0.83, branches=21, leaf_length=0.12, leaf_width=0.030, needle=True, flower='none', greens=[(0.045,0.105,0.075), (0.07,0.15,0.11), (0.11,0.19,0.14)]),
    dict(name='weide', height=1.45, radius=0.76, branches=16, leaf_length=0.14, leaf_width=0.038, needle=False, flower='none', greens=[(0.12,0.18,0.095), (0.18,0.25,0.14), (0.23,0.29,0.17)]),
    dict(name='latsche', height=0.90, radius=1.00, branches=17, leaf_length=0.14, leaf_width=0.024, needle=True, flower='none', greens=[(0.035,0.095,0.045), (0.06,0.15,0.065), (0.09,0.19,0.08)]),
]
FORMS = [
    dict(name='kompakt', h=1.0, r=1.0, branches=1.0, sparse=1.0),
    dict(name='breit', h=0.66, r=1.38, branches=1.15, sparse=1.0),
    dict(name='aufrecht', h=1.43, r=0.69, branches=0.90, sparse=1.0),
    dict(name='offen', h=1.10, r=1.08, branches=0.74, sparse=0.72),
    dict(name='polster', h=0.48, r=1.12, branches=1.32, sparse=1.18),
]


def make_material(name, color, roughness=0.9):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1.0)
    m.use_nodes = True
    m.use_backface_culling = False
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1.0)
    shader.inputs['Roughness'].default_value = roughness
    return m


def basis_for(direction):
    axis = direction.normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(axis.z) < 0.85 else Vector((1.0, 0.0, 0.0))
    u = axis.cross(ref).normalized()
    return u, axis.cross(u).normalized()


class PlantMesh:
    def __init__(self):
        self.vertices = []
        self.faces = []
        self.indices = []
    def triangle(self, a, b, c, material):
        i = len(self.vertices)
        self.vertices.extend([tuple(a), tuple(b), tuple(c)])
        self.faces.append((i, i+1, i+2))
        self.indices.append(material)
    def branch(self, start, end, r0, r1):
        d = end - start
        if d.length < 0.001: return
        u,v = basis_for(d)
        for i in range(5):
            a=math.tau*i/5; b=math.tau*(i+1)/5
            p0=start+(u*math.cos(a)+v*math.sin(a))*r0
            p1=start+(u*math.cos(b)+v*math.sin(b))*r0
            q0=end+(u*math.cos(a)+v*math.sin(a))*r1
            q1=end+(u*math.cos(b)+v*math.sin(b))*r1
            self.triangle(p0,p1,q0,0);self.triangle(p1,q1,q0,0)
    def leaf(self, base, tip, width, color):
        d=tip-base
        if d.length<0.001:return
        u,v=basis_for(d)
        side=u*width
        center=base+d*0.53+v*width*.15
        self.triangle(base,center-side,center,color)
        self.triangle(base,center,center+side,color)
        self.triangle(center-side,tip,center,color)
        self.triangle(center,tip,center+side,color)
    def jewel(self, center, radius, color):
        p=[center+Vector((radius,0,0)),center+Vector((-radius,0,0)),center+Vector((0,radius,0)),center+Vector((0,-radius,0)),center+Vector((0,0,radius)),center+Vector((0,0,-radius))]
        for a,b,c in [(0,2,4),(2,1,4),(1,3,4),(3,0,4),(2,0,5),(1,2,5),(3,1,5),(0,3,5)]:self.triangle(p[a],p[b],p[c],color)


def build(index, family, form):
    rng=random.Random(71931+index*1009)
    mesh=PlantMesh()
    height=family['height']*form['h']; radius=family['radius']*form['r']
    n=max(5,round(family['branches']*form['branches']))
    for j in range(n):
        angle=math.tau*(j/n)+rng.uniform(-.2,.2)
        radial=Vector((math.cos(angle),math.sin(angle),0))
        side=Vector((-radial.y,radial.x,0))
        start=Vector((rng.uniform(-.07,.07)*radius,rng.uniform(-.07,.07)*radius,rng.uniform(0,.07)*height))
        tip=radial*radius*rng.uniform(.55,1.05)+Vector((0,0,height*rng.uniform(.57,1.10)))
        tip+=side*radius*rng.uniform(-.10,.10)
        mesh.branch(start,tip, max(.008,.028*height),.004)
        for k in range(5):
            fraction=.25+k*.145+rng.uniform(-.035,.035)
            root=start.lerp(tip,fraction)
            twist=rng.choice([-1,1])*rng.uniform(.4,1.0)
            fork=radial*radius*rng.uniform(.12,.27)+side*radius*twist*.22+Vector((0,0,height*rng.uniform(.10,.27)))
            fork_tip=root+fork
            mesh.branch(root,fork_tip,max(.004,.010*height),.002)
            leaf_count=max(4,round((16 if family['needle'] else 12)*form['sparse']))
            for leaf in range(leaf_count):
                t=.20+.78*(leaf/max(1,leaf_count-1))
                anchor=root.lerp(fork_tip,t)
                turn=angle+leaf*2.4+rng.uniform(-.35,.35)
                leaf_dir=Vector((math.cos(turn),math.sin(turn),rng.uniform(.15,.8))).normalized()
                length=family['leaf_length']*rng.uniform(.80,1.30)
                if family['needle']:
                    # Needles grow in paired sprays, not a single pointed cone.
                    for sign in (-1,1):
                        direction=(leaf_dir+side*sign*.55).normalized()
                        mesh.leaf(anchor,anchor+direction*length,family['leaf_width']*rng.uniform(.8,1.2),rng.randint(1,3))
                else:
                    mesh.leaf(anchor,anchor+leaf_dir*length,family['leaf_width']*rng.uniform(.75,1.25),rng.randint(1,3))
            if family['flower']=='berry' and (j+k)%4==0:
                mesh.jewel(fork_tip,.018,4)
            if family['flower']=='rose' and (j+k)%4==0:
                mesh.jewel(fork_tip,.035,4)
                for petal in range(5):
                    a=petal*math.tau/5
                    base=fork_tip+Vector((math.cos(a)*.022,math.sin(a)*.022,0))
                    mesh.leaf(base,base+Vector((math.cos(a)*.06,math.sin(a)*.06,.012)),.025,4)
    return mesh, height, radius

catalog=[]
for idx in range(25):
    family=FAMILIES[idx//5]; form=FORMS[idx%5]
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    # Materials are recreated per export to keep the asset independently usable.
    mats=[make_material('bark',(.115,.085,.048))]
    for i,color in enumerate(family['greens']):mats.append(make_material('foliage_%d'%i,color))
    accent=(.46,.13,.20) if family['flower']=='rose' else ((.025,.045,.11) if family['flower']=='berry' else (.15,.19,.09))
    mats.append(make_material('blossom_or_berry',accent))
    geometry,height,radius=build(idx,family,form)
    datablock=bpy.data.meshes.new('bush_%02d'%idx)
    datablock.from_pydata(geometry.vertices,[],geometry.faces);datablock.update()
    ob=bpy.data.objects.new('bush_%02d'%idx,datablock);bpy.context.collection.objects.link(ob)
    for material in mats:datablock.materials.append(material)
    for polygon,material in zip(datablock.polygons,geometry.indices):polygon.material_index=material
    target=OUT/('bush_%02d.glb'%idx)
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_yup=True,export_apply=True)
    catalog.append(dict(id='bush_%02d'%idx, family=family['name'], form=form['name'], estimated_height_m=round(height*1.1,2), estimated_radius_m=round(radius*1.15,2), faces=len(geometry.faces), sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
(OUT/'catalog.json').write_text(json.dumps({'version':1,'source':'Original procedural geometry; no third-party assets','units':'meters','up_axis':'Y (glTF)','variants':catalog},indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('BUSH_BUILD_PASS',len(catalog),str(OUT))
