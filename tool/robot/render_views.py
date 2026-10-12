# Renders a robot model (.glb) from several angles in its texture's own
# colours (unlit), transparent, 512 x 512, to compare with the 2D pictures.
#
#   blender -b -P tool/robot/render_views.py -- <model.glb> <out_dir> [angles...]
#
# Angles are degrees around the robot: 0 faces the viewer, 90 shows its left.
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
model, out = args[0], args[1]
angles = [float(a) for a in args[2:]] or [0, 45, 90, 135, 180, 270]
os.makedirs(out, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=model)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

# Unlit: show each material's base colour as it is.
for mat in {s.material for o in meshes for s in o.material_slots if s.material}:
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
    output = next(n for n in nodes if n.type == "OUTPUT_MATERIAL")
    emit = nodes.new("ShaderNodeEmission")
    base = bsdf.inputs["Base Color"] if bsdf else None
    if base is not None and base.links:
        links.new(base.links[0].from_socket, emit.inputs["Color"])
    elif base is not None:
        emit.inputs["Color"].default_value = base.default_value
    links.new(emit.outputs["Emission"], output.inputs["Surface"])

# Frame the model: a pivot at its centre turns, the camera stays put.
bpy.context.view_layer.update()
points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
lo = Vector([min(p[i] for p in points) for i in range(3)])
hi = Vector([max(p[i] for p in points) for i in range(3)])
print("bounds", tuple(lo), tuple(hi))
centre, size = (lo + hi) / 2, max(hi - lo)
pivot = bpy.data.objects.new("pivot", None)
bpy.context.scene.collection.objects.link(pivot)
pivot.location = centre
bpy.context.view_layer.update()
for o in [o for o in bpy.context.scene.objects if o.parent is None and o != pivot]:
    o.parent = pivot
    o.matrix_parent_inverse = pivot.matrix_world.inverted()

cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = size * 1.08
cam = bpy.data.objects.new("cam", cam_data)
bpy.context.scene.collection.objects.link(cam)
# glTF is Y-up, imported as Z-up with the front facing -Y.
cam.location = centre + Vector((0, -size * 3, 0))
cam.rotation_euler = (math.pi / 2, 0, 0)
scene = bpy.context.scene
scene.camera = cam
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.view_settings.view_transform = "Standard"

for a in angles:
    pivot.rotation_euler = (0, 0, math.radians(-a))
    scene.render.filepath = os.path.join(out, f"view_{int(a):03d}.png")
    bpy.ops.render.render(write_still=True)
