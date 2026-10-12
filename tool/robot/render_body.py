# Renders the 3D robot's body without its head (and without its shadow),
# turned to a given angle, in the 512 x 512 frame of the 2D pictures: 100 px
# per unit, the ground at y = 500, the robot's middle at x = 256 + shift.
# branding/robot.sh puts the drawn three-quarter head over it, so that
# picture's body matches the front, back and 3D views.
#
#   blender -b <koba.blend> -P tool/robot/render_body.py -- <out.png> <angle> [shift]
import math
import os
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
out, angle = args[0], float(args[1])
shift = float(args[2]) if len(args) > 2 else 0
scene = bpy.context.scene


def hide(obj):
    obj.hide_render = True
    for child in obj.children:
        hide(child)


hide(bpy.data.objects["head"])
hide(bpy.data.objects["shadow"])
robot = bpy.data.objects["Koba"]
robot.rotation_euler = (0, 0, math.radians(-angle))
camera = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = "ORTHO"
# Drawn a little smaller than the front and back, like the original drawing,
# whose head is turned towards the child and so looks bigger.
camera.data.ortho_scale = 5.12 / 0.92
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.view_settings.view_transform = "Standard"
camera.rotation_euler = (math.pi / 2, 0, 0)
per_unit = 512 / camera.data.ortho_scale
camera.location = (-shift / per_unit, -20, (500 - 256) / per_unit)
scene.render.filepath = os.path.abspath(out)
bpy.ops.render.render(write_still=True)
