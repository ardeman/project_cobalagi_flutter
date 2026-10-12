# Builds the robot (Koba) in 3D from simple shapes, measured from its
# front and back pictures (assets/images/robot_front.png, robot_back.png),
# in the colours of branding/robot.svg with drawn-looking outlines. Saves the
# model and renders it from several angles to compare with the pictures.
#
#   blender -b -P tool/robot/build_model.py -- <out_dir> [angles...]
#
# Angles are degrees around the robot: 0 faces the viewer, 90 shows its left
# side. Units: 1 = 100 px of the 512 px pictures; the ground is z = 0, the
# robot faces -y.
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
out = args[0] if args else "build/robot3d/koba"
angles = [float(a) for a in args[1:]] or [0, 45, 90, 180, 270]
os.makedirs(out, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def srgb(r, g, b):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (lin(r), lin(g), lin(b), 1)


def material(name, rgb, cull=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    emit = nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = srgb(*rgb)
    output = nodes.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(emit.outputs[0], output.inputs["Surface"])
    mat.diffuse_color = srgb(*rgb)
    mat.use_backface_culling = cull
    return mat


TEAL = material("teal", (146, 220, 207))
DARK_TEAL = material("dark_teal", (92, 176, 153))
YELLOW = material("yellow", (250, 231, 144))
SCREEN = material("screen", (69, 69, 83))
NAVY = material("navy", (34, 34, 68))
OUTLINE = material("outline", (34, 34, 68), cull=True)

robot = bpy.data.objects.new("Koba", None)
scene.collection.objects.link(robot)


def finish(obj, mat, outline=0.05, parent=robot):
    """Colours a part, outlines it like the drawing and hangs it on parent."""
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if outline:
        obj.data.materials.append(OUTLINE)
        shell = obj.modifiers.new("outline", "SOLIDIFY")
        shell.thickness = outline
        shell.offset = 1
        shell.use_flip_normals = True
        shell.material_offset = 1
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.parent = parent
    return obj


def rounded_box(name, size, centre, radius, mat, outline=0.05, parent=robot):
    bpy.ops.mesh.primitive_cube_add(location=centre)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("round", "BEVEL")
    bevel.width = radius
    bevel.segments = 10
    bevel.limit_method = "NONE"
    return finish(obj, mat, outline, parent)


def cylinder(name, radius, depth, centre, axis, mat, outline=0.05, parent=robot, vertices=48, round=0.25):
    rotation = {"x": (0, math.pi / 2, 0), "y": (math.pi / 2, 0, 0), "z": (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=centre, rotation=rotation
    )
    obj = bpy.context.object
    obj.name = name
    bevel = obj.modifiers.new("round", "BEVEL")
    bevel.width = min(radius, depth) * round
    bevel.segments = 4
    return finish(obj, mat, outline, parent)


def ball(name, scale, centre, mat, outline=0.05, parent=robot):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=centre)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, outline, parent)


# Head: helmet, visor rim, screen, ears and antenna. Everything on it hangs on
# the "head" empty, so the game can bob it.
head = bpy.data.objects.new("head", None)
scene.collection.objects.link(head)
head.parent = robot
head.location = (0, 0, 1.75)
H = 1.75  # the head's parts are placed in robot units, then offset by this

helmet = rounded_box("helmet", (2.76, 2.5, 2.34), (0, 0, 2.92 - H), 1.15, TEAL, outline=0.065, parent=head)


def visor_patch(name, size, grow, mat, outline):
    """The part of the helmet's front inside a rounded rectangle, lifted off
    it a little, so the rim and screen follow the helmet's curve."""
    cutter = rounded_box(f"{name}_cut", (size[0], 3, size[1]), (0, -1.5, 2.95 - H), 0.5, NAVY, outline=0, parent=head)
    patch = helmet.copy()
    patch.data = helmet.data.copy()
    patch.modifiers.clear()
    patch.name = name
    scene.collection.objects.link(patch)
    patch.scale = (grow, grow, grow)
    bevel = patch.modifiers.new("round", "BEVEL")
    bevel.width, bevel.segments, bevel.limit_method = 1.15 / grow, 10, "NONE"
    cut = patch.modifiers.new("cut", "BOOLEAN")
    cut.operation, cut.object, cut.solver = "INTERSECT", cutter, "EXACT"
    bpy.context.view_layer.objects.active = patch
    for m in list(patch.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.data.objects.remove(cutter)
    patch.data.materials.clear()
    return finish(patch, mat, outline, parent=head)


visor_patch("rim", (2.54, 2.0), 1.012, TEAL, 0)
visor_patch("screen", (2.26, 1.72), 1.024, SCREEN, 0)
for side in (-1, 1):
    cylinder(f"ear_ring_{side}", 0.44, 0.16, (side * 1.36, 0, 2.78 - H), "x", TEAL, parent=head)
    cylinder(f"ear_{side}", 0.34, 0.2, (side * 1.44, 0, 2.78 - H), "x", YELLOW, parent=head)
cylinder("antenna_base", 0.24, 0.12, (0, 0, 4.06 - H), "z", TEAL, parent=head)
cylinder("antenna", 0.045, 0.5, (0, 0, 4.33 - H), "z", TEAL, outline=0.02, parent=head)
ball("antenna_ball", (0.15, 0.15, 0.15), (0, 0, 4.72 - H), YELLOW, parent=head)
# Two small lights above the visor, on the helmet's rounded top edge (its
# front-top curve has radius 1.15 around y = -0.10, z = 2.94).
for z in (3.96, 4.04):
    y = -0.10 - math.sqrt(1.15**2 - (z - 2.94) ** 2) - 0.01
    ball(f"dot_{z}", (0.035, 0.03, 0.035), (0.0, y, z - H), YELLOW, outline=0.012, parent=head)

# Body, neck, arms and hands.
cylinder("neck", 0.42, 0.3, (0, 0, 1.7), "z", DARK_TEAL)
body = rounded_box("body", (1.45, 1.05, 1.25), (0, 0, 1.15), 0.38, TEAL, outline=0.06)
# Wider at the bottom, like the drawing.
for v in body.data.vertices:
    v.co.x *= 1.0 - v.co.z * 0.1
for side in (-1, 1):
    arm = ball(f"arm_{side}", (0.17, 0.24, 0.46), (side * 0.8, 0, 1.12), YELLOW)
    arm.rotation_euler = (0, side * -0.18, 0)
    for i, z in enumerate((-0.27, -0.12, 0.03, 0.18)):
        bpy.ops.mesh.primitive_torus_add(major_radius=1, minor_radius=0.012)
        rib = bpy.context.object
        rib.name = f"rib_{side}_{i}"
        width = math.sqrt(max(0.0, 1 - (z / 0.46) ** 2))
        rib.scale = (0.17 * width + 0.006, 0.24 * width + 0.006, 1)
        rib.location = (0, 0, z)
        finish(rib, NAVY, outline=0, parent=arm)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.1, minor_radius=0.045, rotation=(0, math.pi / 2, 0)
    )
    hand = bpy.context.object
    hand.name = f"hand_{side}"
    hand.location = (side * 0.05, -0.14, -0.48)
    finish(hand, TEAL, parent=arm)

# Wheels: each on its own empty so the game can spin it.
for side in (-1, 1):
    wheel = bpy.data.objects.new(f"wheel_{side}", None)
    scene.collection.objects.link(wheel)
    wheel.parent = robot
    wheel.location = (side * 0.56, 0, 0.3)
    cylinder("tyre", 0.3, 0.3, (0, 0, 0), "x", TEAL, parent=wheel, round=0.45)
    cylinder("hub", 0.15, 0.36, (0, 0, 0), "x", DARK_TEAL, outline=0.015, parent=wheel)
    for i in range(10):
        a = i * math.tau / 10
        bpy.ops.mesh.primitive_cube_add(
            size=1, location=(0, math.sin(a) * 0.295, math.cos(a) * 0.295), rotation=(-a, 0, 0)
        )
        tread = bpy.context.object
        tread.scale = (0.26, 0.016, 0.02)
        finish(tread, NAVY, outline=0, parent=wheel)



def rounded_rect(cx, cz, w, h, r, steps=8):
    points = []
    for corner, (sx, sz) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        ox, oz = cx + sx * (w / 2 - r), cz + sz * (h / 2 - r)
        for i in range(steps + 1):
            a = math.pi / 2 * (corner + i / steps)
            points.append((ox + math.cos(a) * r, oz + math.sin(a) * r))
    return points


def drawn_line(name, points, side, parent, cyclic=True, width=0.017):
    """A navy line lying on the robot's surface, like the drawing's inner
    lines: each point is dropped onto the surface from the front (side -1) or
    the back (side 1)."""
    dense = []
    ring = points + points[:1] if cyclic else points
    for (x0, z0), (x1, z1) in zip(ring, ring[1:]):
        steps = max(1, int(math.hypot(x1 - x0, z1 - z0) / 0.03))
        dense += [(x0 + (x1 - x0) * i / steps, z0 + (z1 - z0) * i / steps) for i in range(steps)]
    if not cyclic:
        dense.append(points[-1])
    points = dense
    # Drop onto the parts themselves, not their outline shells.
    shells = [m for o in scene.objects for m in getattr(o, "modifiers", []) if m.name == "outline"]
    for m in shells:
        m.show_viewport = False
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    placed = []
    for x, z in points:
        origin = Vector((x, side * 10, z))
        hit, location, normal, *_ = scene.ray_cast(depsgraph, origin, Vector((0, -side, 0)))
        if hit:
            placed.append(location + normal * 0.045)
    for m in shells:
        m.show_viewport = True
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = width
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(len(placed) - 1)
    for point, co in zip(spline.points, placed):
        point.co = (*co, 1)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    scene.collection.objects.link(obj)
    obj.data.materials.append(NAVY)
    bpy.context.view_layer.objects.active = obj
    for o in bpy.context.selected_objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    bpy.context.view_layer.update()
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
    return obj


# Inner lines, measured from the pictures (x = (px - 256) / 100,
# z = (500 - py) / 100).
drawn_line("rim_line", rounded_rect(0, 2.95, 2.46, 1.92, 0.48), -1, head)
drawn_line("screen_line", rounded_rect(0, 2.95, 2.18, 1.64, 0.42), -1, head)
drawn_line("back_panel", rounded_rect(0, 3.0, 1.9, 1.6, 0.35), 1, head)
drawn_line("neck_panel", rounded_rect(0, 2.06, 0.7, 0.42, 0.06), 1, head)
drawn_line("back_button_line", rounded_rect(0, 1.2, 0.34, 0.22, 0.06), 1, robot, width=0.012)
for side in (-1, 1):
    drawn_line(f"seam_{side}", [(x / 20, 0.78) for x in range(-14, 15)], side, robot, cyclic=False)
for i, (x, z) in enumerate(((0.12, 1.45), (0.18, 1.2))):
    circle = [(x + math.cos(a / 16 * math.tau) * 0.075, z + math.sin(a / 16 * math.tau) * 0.075) for a in range(16)]
    drawn_line(f"button_line_{i}", circle, -1, robot, width=0.012)
drawn_line("front_seam", [(0.0, 1.7 - z / 20) for z in range(0, 16)], -1, robot, cyclic=False)

head.rotation_euler = (math.radians(-5), 0, 0)

# The soft shadow on the ground, its own part so the game can leave it out.
bpy.ops.mesh.primitive_circle_add(vertices=64, radius=1, fill_type="NGON", location=(0, 0, 0.004))
shadow = bpy.context.object
shadow.name = "shadow"
shadow.scale = (0.95, 0.55, 1)
finish(shadow, material("shadow", (170, 196, 196)), outline=0)

bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(os.path.join(out, "koba.blend")))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(out, "koba.glb"), export_apply=True, export_yup=True
)

# Render: an orthographic camera in front; the robot turns on the spot.
camera = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
camera.data.type = "ORTHO"
camera.data.ortho_scale = 5.4
# A little from above, like the drawings and the game's board.
tilt = math.radians(12)
camera.location = (0, -20 * math.cos(tilt), 2.4 + 20 * math.sin(tilt))
camera.rotation_euler = (math.pi / 2 - tilt, 0, 0)
scene.collection.objects.link(camera)
scene.camera = camera
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.view_settings.view_transform = "Standard"
for a in angles:
    robot.rotation_euler = (0, 0, math.radians(-a))
    scene.render.filepath = os.path.abspath(os.path.join(out, f"view_{int(a):03d}.png"))
    bpy.ops.render.render(write_still=True)
