# Builds Koba's star ship in 3D from simple shapes, in Koba's colours with
# drawn-looking navy outlines (like tool/robot/build_model.py), and renders
# the views the story's scenes use:
#
#   landed   standing on its fins, engine off
#   launch   taking off: upright, a big flame
#   landing  coming down: upright, a small flame
#   flying   between planets: nose to the right, tipped up, a long flame
#
# Each view is <out>/<view>.png (1024 x 1024, transparent) with
# <out>/<view>_tank.png, a mask of the star tank's window (white where it
# shows), so the game can draw the tank's fill at any level, clipped to it.
# <out>/ship.json says, for each view, in pixels: where the ship's base (the
# middle of its engine, on the ground) is, the tank's fill axis (its bottom and
# top, so the fill rises from bottom towards top) and the cockpit window's
# middle and radius (for drawing Koba in it).
#
#   blender -b -P tool/ship/build_ship.py -- branding/ship [ship.blend]
#
# Units: the ground is z = 0, the ship's axis is z, its front (cockpit and
# tank) faces -y. Every view uses the same scale, PX pixels per unit.
import json
import math
import os
import sys

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
out = os.path.abspath(args[0] if args else "branding/ship")
blend = args[1] if len(args) > 1 else None
os.makedirs(out, exist_ok=True)

SIZE = 1024
PX = 140

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def srgb(r, g, b):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (lin(r), lin(g), lin(b), 1)


def flat(name, rgb, cull=False):
    """A colour that ignores light, like Koba's."""
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


def toon(name, rgb, shade):
    """A colour with one flat shade on the side away from the light, so the
    round hull reads as round while staying drawn-looking."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    tree = mat.node_tree
    tree.nodes.clear()
    diffuse = tree.nodes.new("ShaderNodeBsdfDiffuse")
    to_rgb = tree.nodes.new("ShaderNodeShaderToRGB")
    ramp = tree.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].color = srgb(*shade)
    ramp.color_ramp.elements[1].position = 0.18
    ramp.color_ramp.elements[1].color = srgb(*rgb)
    emit = tree.nodes.new("ShaderNodeEmission")
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    tree.links.new(diffuse.outputs[0], to_rgb.inputs[0])
    tree.links.new(to_rgb.outputs["Color"], ramp.inputs[0])
    tree.links.new(ramp.outputs["Color"], emit.inputs["Color"])
    tree.links.new(emit.outputs[0], output.inputs["Surface"])
    mat.diffuse_color = srgb(*rgb)
    return mat


CORAL = toon("coral", (255, 154, 107), (240, 116, 80))
TEAL = toon("teal", (146, 220, 207), (110, 192, 174))
DARK_TEAL = toon("dark_teal", (92, 176, 153), (70, 148, 128))
YELLOW = toon("yellow", (250, 231, 144), (238, 200, 96))
SCREEN = flat("screen", (69, 69, 83))
NAVY = flat("navy", (34, 34, 68))
OUTLINE = flat("outline", (34, 34, 68), cull=True)


def flame_colour():
    """Pale in the middle, where it faces the viewer, and orange round its
    edge, from any side."""
    mat = bpy.data.materials.new("flame")
    mat.use_nodes = True
    tree = mat.node_tree
    tree.nodes.clear()
    facing = tree.nodes.new("ShaderNodeLayerWeight")
    ramp = tree.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].color = srgb(255, 244, 196)
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = srgb(255, 190, 80)
    emit = tree.nodes.new("ShaderNodeEmission")
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    tree.links.new(facing.outputs["Facing"], ramp.inputs[0])
    tree.links.new(ramp.outputs["Color"], emit.inputs["Color"])
    tree.links.new(emit.outputs[0], output.inputs["Surface"])
    return mat


FLAME = flame_colour()
WHITE = flat("mask", (255, 255, 255))

ship = bpy.data.objects.new("Ship", None)
scene.collection.objects.link(ship)


def finish(obj, mat, outline=0.05, parent=ship, smooth=True):
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
        poly.use_smooth = smooth
    obj.parent = parent
    return obj


def smooth_profile(points, steps=8):
    """Catmull-Rom through (radius, z) points, ends kept."""
    padded = [points[0]] + points + [points[-1]]
    result = []
    for i in range(1, len(padded) - 2):
        p0, p1, p2, p3 = padded[i - 1 : i + 3]
        for s in range(steps):
            t = s / steps
            result.append(
                tuple(
                    0.5
                    * (
                        2 * p1[k]
                        + (-p0[k] + p2[k]) * t
                        + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t
                        + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t**3
                    )
                    for k in range(2)
                )
            )
    result.append(points[-1])
    return result


def lathe(name, profile, mat, outline=0.05, parent=ship, segments=64):
    """Turns a (radius, z) profile round the z axis; a radius of 0 at either
    end closes it."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r <= 1e-6:
            rings.append([bm.verts.new((0, 0, z))])
        else:
            rings.append(
                [
                    bm.verts.new((math.cos(a) * r, math.sin(a) * r, z))
                    for a in (i * math.tau / segments for i in range(segments))
                ]
            )
    for lower, upper in zip(rings, rings[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            if len(lower) == 1:
                bm.faces.new((lower[0], upper[i], upper[j]))
            elif len(upper) == 1:
                bm.faces.new((lower[i], lower[j], upper[0]))
            else:
                bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
    for ring in (rings[0], rings[-1]):
        if len(ring) > 1:
            bm.faces.new(ring)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    return finish(obj, mat, outline, parent)


def radius_at(profile, z):
    for (r0, z0), (r1, z1) in zip(profile, profile[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    raise ValueError(z)


def place(obj, origin, normal):
    """Stands obj's local z on normal at origin."""
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = normal.to_track_quat("Z", "Y")
    obj.location = origin


def hull_point(z, angle=0.0, lift=0.0):
    """A point on the hull's skin at height z, angle round from the front
    (positive towards +x), with the outward normal."""
    r = radius_at(HULL, z)
    dr = (radius_at(HULL, z + 0.02) - radius_at(HULL, z - 0.02)) / 0.04
    out_dir = Vector((math.sin(angle), -math.cos(angle), 0))
    normal = (out_dir - Vector((0, 0, dr))).normalized()
    return out_dir * r + Vector((0, 0, z)) + normal * lift, normal


# The hull: a round-bellied rocket, a little wider low down.
HULL = smooth_profile(
    [(0.0, 0.62), (0.5, 0.66), (0.86, 0.95), (0.98, 1.55), (0.94, 2.25), (0.78, 2.9), (0.5, 3.45), (0.0, 3.82)]
)
NOSE = 3.08  # above this the hull is teal
hull = lathe("hull", HULL, CORAL, outline=0.07)
# Two colours, so the outline shell takes slots 2 and 3.
hull.data.materials.clear()
for mat in (CORAL, TEAL, OUTLINE, OUTLINE):
    hull.data.materials.append(mat)
hull.modifiers["outline"].material_offset = 2
for poly in hull.data.polygons:
    if poly.center.z > NOSE:
        poly.material_index = 1
for z in (NOSE,):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=radius_at(HULL, z) + 0.008, minor_radius=0.022, location=(0, 0, z),
        major_segments=96, minor_segments=8,
    )
    finish(bpy.context.object, NAVY, outline=0)
# A teal belt low down, where the fins meet the hull.
belt = lathe(
    "belt",
    [(radius_at(HULL, z) + 0.035, z) for z in (0.9, 0.94, 1.0, 1.06, 1.1)],
    TEAL,
    outline=0.04,
)
for poly in belt.data.polygons:
    poly.use_smooth = True

# Nose antenna, like Koba's.
bpy.ops.mesh.primitive_cylinder_add(radius=0.045, depth=0.42, location=(0, 0, 3.98))
finish(bpy.context.object, TEAL, outline=0.02)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, segments=32, ring_count=16, location=(0, 0, 4.24))
finish(bpy.context.object, YELLOW, outline=0.04)

# Engine bell under the hull.
lathe("engine", [(0.0, 0.7), (0.3, 0.68), (0.36, 0.5), (0.5, 0.32), (0.5, 0.28), (0.0, 0.3)], DARK_TEAL, outline=0.05)

# The cockpit: a round window with a yellow ring, where Koba sits.
COCKPIT_Z, COCKPIT_R = 2.64, 0.32
centre, normal = hull_point(COCKPIT_Z)
bpy.ops.mesh.primitive_torus_add(major_radius=COCKPIT_R + 0.04, minor_radius=0.075, major_segments=64)
ring = bpy.context.object
place(ring, centre + normal * 0.03, normal)
finish(ring, YELLOW, outline=0.035)
bpy.ops.mesh.primitive_cylinder_add(radius=COCKPIT_R, depth=0.08, vertices=64)
cockpit = bpy.context.object
cockpit.name = "cockpit"
place(cockpit, centre + normal * 0.01, normal)
finish(cockpit, SCREEN, outline=0, smooth=False)
cockpit_centre = centre + normal * 0.05

# The star tank's window: a tall rounded window lying on the hull below the
# cockpit, cut from a copy of the hull so it follows its curve.
TANK_BOTTOM, TANK_TOP, TANK_WIDTH = 1.3, 1.94, 0.46


def hull_patch(name, width, bottom, top, grow, mat, outline=0):
    bpy.ops.mesh.primitive_cube_add(location=(0, -1.5, (bottom + top) / 2))
    cutter = bpy.context.object
    cutter.scale = (width / 2, 1.5, (top - bottom) / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    round_ = cutter.modifiers.new("round", "BEVEL")
    round_.width, round_.segments, round_.limit_method = width * 0.45, 8, "NONE"
    patch = bpy.data.objects.new(name, hull.data.copy())
    scene.collection.objects.link(patch)
    patch.scale = (grow, grow, 1)
    cut = patch.modifiers.new("cut", "BOOLEAN")
    cut.operation, cut.object, cut.solver = "INTERSECT", cutter, "EXACT"
    bpy.context.view_layer.objects.active = patch
    bpy.ops.object.modifier_apply(modifier="cut")
    bpy.data.objects.remove(cutter)
    return finish(patch, mat, outline)


hull_patch("tank_rim", TANK_WIDTH + 0.16, TANK_BOTTOM - 0.08, TANK_TOP + 0.08, 1.03, YELLOW, outline=0.03)
tank = hull_patch("tank", TANK_WIDTH, TANK_BOTTOM, TANK_TOP, 1.045, SCREEN)
tank_bottom = hull_point(TANK_BOTTOM + 0.05, lift=0.05)[0]
tank_top = hull_point(TANK_TOP - 0.05, lift=0.05)[0]


def star_shape(cx, cz, outer, inner, points=5):
    return [
        (
            cx + math.sin(i * math.pi / points) * (outer if i % 2 == 0 else inner),
            cz + math.cos(i * math.pi / points) * (outer if i % 2 == 0 else inner),
        )
        for i in range(points * 2)
    ]


def flat_piece(name, outline_xz, thickness, mat, outline=0.05, parent=ship, bevel=0.05):
    """A flat piece from an (x, z) outline, thickness along y."""
    bm = bmesh.new()
    front = [bm.verts.new((x, -thickness / 2, z)) for x, z in outline_xz]
    face = bm.faces.new(front)
    bmesh.ops.extrude_face_region(bm, geom=[face])
    for v in bm.verts:
        if v not in front:
            v.co.y = thickness / 2
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    if bevel:
        round_ = obj.modifiers.new("round", "BEVEL")
        round_.width, round_.segments = bevel, 4
    return finish(obj, mat, outline, parent, smooth=False)


# Three fins that are also its legs: left, right and back. The side fins
# carry a yellow star each.
FIN = smooth_profile(
    [(0.6, 2.0), (0.95, 1.55), (1.35, 0.85), (1.52, 0.2), (1.46, 0.0), (1.18, 0.0), (1.02, 0.42), (0.6, 0.72)],
    steps=4,
)
for name, angle in (("fin_right", 90), ("fin_back", 180), ("fin_left", 270)):
    pivot = bpy.data.objects.new(name, None)
    scene.collection.objects.link(pivot)
    pivot.parent = ship
    pivot.rotation_euler = (0, 0, math.radians(angle - 90))
    flat_piece(name + "_fin", FIN, 0.16, TEAL, parent=pivot)
    if angle != 180:
        flat_piece(
            name + "_star", star_shape(1.12, 0.62, 0.2, 0.09), 0.2, YELLOW, outline=0.02, parent=pivot, bevel=0.01
        )

# The flame, under the engine; each view sets its length.
flame = bpy.data.objects.new("flame", None)
scene.collection.objects.link(flame)
flame.parent = ship
flame.location = (0, 0, 0.32)
flame_shape = smooth_profile([(0.0, 0.05), (0.44, 0.0), (0.4, -0.35), (0.22, -0.75), (0.0, -1.0)])
lathe("flame_outer", flame_shape, FLAME, outline=0.04, parent=flame, segments=48)

if blend:
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(blend))

# Light from the upper left, a little in front, as on Koba's pictures.
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3
# No shadows: the outline shells round every part would shade it all.
sun.data.use_shadow = False
# A sun shines along its -z: here from the left, the front and above.
sun.rotation_euler = Vector((-0.55, -0.6, 0.6)).to_track_quat("Z", "Y").to_euler()
scene.collection.objects.link(sun)
scene.world = bpy.data.worlds.new("world")
scene.world.color = (0, 0, 0)

camera = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
camera.data.type = "ORTHO"
camera.data.ortho_scale = SIZE / PX
scene.collection.objects.link(camera)
scene.camera = camera
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = SIZE
scene.view_settings.view_transform = "Standard"
scene.render.image_settings.color_depth = "8"
scene.render.image_settings.compression = 100
# A little from above, like Koba's pictures and the board.
TILT = math.radians(12)
camera.rotation_euler = (math.pi / 2 - TILT, 0, 0)
view_dir = Vector((0, math.cos(TILT), -math.sin(TILT)))

# name: (turn round its axis, degrees towards showing its right side;
# tip, degrees nose to the right; flame length, 0 for none)
VIEWS = {
    "landed": (-20, 0, 0),
    "launch": (-20, 0, 1.6),
    "landing": (-20, 0, 0.7),
    "flying": (-10, 68, 1.3),
}


def mesh_objects():
    return [o for o in scene.objects if o.type == "MESH" and o.visible_get() and not o.hide_render]


def frame_views(points):
    """Centres the camera on the points (world), keeping the scale."""
    cam_inv = camera.matrix_world.inverted()
    local = [cam_inv @ p for p in points]
    mid = Vector(((min(p.x for p in local) + max(p.x for p in local)) / 2, (min(p.y for p in local) + max(p.y for p in local)) / 2, 0))
    camera.location = camera.matrix_world @ mid - view_dir * 20


def to_px(point):
    co = world_to_camera_view(scene, camera, point)
    return [round(co.x * SIZE, 1), round((1 - co.y) * SIZE, 1)]


info = {"size": SIZE, "pixelsPerUnit": PX, "views": {}}
for view, (turn, tip, flame_length) in VIEWS.items():
    ship.matrix_world = Matrix.Rotation(math.radians(tip), 4, "Y") @ Matrix.Rotation(math.radians(turn), 4, "Z")
    for part in flame.children:
        part.hide_render = flame_length == 0
        part.hide_viewport = flame_length == 0
    flame.scale = (1, 1, max(flame_length, 0.01))
    bpy.context.view_layer.update()
    camera.location = -view_dir * 20
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    points = []
    for obj in mesh_objects():
        evaluated = obj.evaluated_get(depsgraph)
        points += [evaluated.matrix_world @ v.co for v in evaluated.data.vertices]
    frame_views(points)
    bpy.context.view_layer.update()
    m = ship.matrix_world
    edge = (m @ tank_top - m @ tank_bottom).cross(view_dir).normalized() * (TANK_WIDTH / 2)
    info["views"][view] = {
        "base": to_px(m @ Vector((0, 0, 0))),
        "tank": {
            "bottom": to_px(m @ tank_bottom),
            "top": to_px(m @ tank_top),
            "width": round((Vector(to_px(m @ tank_bottom + edge)) - Vector(to_px(m @ tank_bottom - edge))).length, 1),
        },
        "cockpit": {"centre": to_px(m @ cockpit_centre), "radius": round(COCKPIT_R * PX, 1)},
    }
    scene.render.filepath = os.path.join(out, f"{view}.png")
    bpy.ops.render.render(write_still=True)

    # The tank's mask: the window in white, everything else holds it out.
    # Culled like the outline, or the hull's outline shell would hide the window.
    holdout = bpy.data.materials.get("holdout") or flat("holdout", (0, 0, 0), cull=True)
    if not holdout.node_tree.nodes.get("Holdout"):
        holdout.node_tree.nodes.clear()
        h = holdout.node_tree.nodes.new("ShaderNodeHoldout")
        o = holdout.node_tree.nodes.new("ShaderNodeOutputMaterial")
        holdout.node_tree.links.new(h.outputs[0], o.inputs["Surface"])
    saved = {}
    for obj in mesh_objects():
        saved[obj.name] = list(obj.data.materials)
        for i in range(len(obj.data.materials)):
            obj.data.materials[i] = WHITE if obj == tank and i == 0 else holdout
    scene.render.filepath = os.path.join(out, f"{view}_tank.png")
    bpy.ops.render.render(write_still=True)
    for obj in mesh_objects():
        for i, mat in enumerate(saved[obj.name]):
            obj.data.materials[i] = mat

with open(os.path.join(out, "ship.json"), "w") as f:
    json.dump(info, f, indent=1)
    f.write("\n")
