# Renders the 3D robot (Koba) turning on the spot, for the game's turns:
# whole (head and body, no shadow) every 360 / count degrees, each in the
# 512 x 512 frame of the 2D pictures (100 px per unit, the ground at y = 500,
# its middle at x = 256) drawn at half size, 256 x 256. They are saved side
# by side, six to a row, as <out>.webp, frame 0 facing the viewer and later frames turned towards its right (90 degrees shows its left
# side). Its wheels roll the other way round each other as it turns, as on
# the spot: the left one forward, the right one back.
# Also writes <out>.json: for each frame, where the middle of its
# screen is (pixels) and how far the screen faces the viewer (1 straight on,
# 0 edge on, below 0 turned away), so the game can draw the face on it.
#
#   blender -b <koba.blend> -P tool/robot/render_turn.py -- <out> [count]
# The game uses assets/images/robot_turn (see branding/robot.sh).
import json
import math
import os
import sys

import tempfile

import bpy
import numpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
out = os.path.abspath(args[0])
count = int(args[1]) if len(args) > 1 else 24
frames_dir = tempfile.mkdtemp()
scene = bpy.context.scene

bpy.data.objects["shadow"].hide_render = True
robot = bpy.data.objects["Koba"]
wheels = {side: bpy.data.objects[f"wheel_{side}"] for side in (-1, 1)}
screen = bpy.data.objects["screen"]
camera = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = "ORTHO"
camera.data.ortho_scale = 5.12
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.render.resolution_percentage = 50
scene.view_settings.view_transform = "Standard"
camera.rotation_euler = (math.pi / 2, 0, 0)
camera.location = (0, -20, (500 - 256) / 100)

frames = []
for i in range(count):
    angle = i * 360 / count
    robot.rotation_euler = (0, 0, math.radians(-angle))
    # Wheels 0.56 from its middle, 0.3 round: each rolls 0.56 / 0.3 turns
    # for each turn of the robot.
    for side, wheel in wheels.items():
        wheel.rotation_euler = (side * math.radians(angle) * 0.56 / 0.3, 0, 0)
    bpy.context.view_layer.update()
    # The middle of the screen's front, which faces -y.
    box = [Vector(c) for c in screen.bound_box]
    middle = screen.matrix_world @ Vector(
        (
            sum(c.x for c in box) / 8,
            min(c.y for c in box),
            sum(c.z for c in box) / 8,
        )
    )
    # The screen faces -y in the robot's own frame, tipped with the head.
    facing = (screen.matrix_world.to_3x3() @ Vector((0, -1, 0))).normalized()
    frames.append(
        {
            "x": round(256 + middle.x * 100, 1),
            "y": round(500 - middle.z * 100, 1),
            "facing": round(-facing.y, 3),
            "side": round(facing.x, 3),
        }
    )
    scene.render.filepath = os.path.join(frames_dir, f"{i:02d}.png")
    bpy.ops.render.render(write_still=True)

with open(out + ".json", "w") as f:
    json.dump(frames, f, indent=1)

# The frames side by side; Blender's images start at the bottom row.
size, across = 256, 6
rows = -(-count // across)
sheet = numpy.zeros((rows * size, across * size, 4), dtype=numpy.float32)
for i in range(count):
    frame = bpy.data.images.load(os.path.join(frames_dir, f"{i:02d}.png"))
    pixels = numpy.array(frame.pixels[:], dtype=numpy.float32).reshape(size, size, 4)
    top = (rows - 1 - i // across) * size
    sheet[top : top + size, i % across * size : (i % across + 1) * size] = pixels
image = bpy.data.images.new("sheet", across * size, rows * size, alpha=True)
image.pixels = sheet.ravel()
image.filepath_raw = out + ".webp"
image.file_format = "WEBP"
scene.render.image_settings.file_format = "WEBP"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.quality = 90
image.save_render(out + ".webp", scene=scene)
