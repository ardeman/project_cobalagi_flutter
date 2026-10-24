# Branding: Koba, its ship and the app icon

Every picture here is finished artwork. The scripts rebuild the app's images from it without any AI service.

## Koba

Koba is a small teal robot exploring planets in space. It was designed with AI (Recraft V3 on fal.ai); the reasons behind its look are in `AGENTS.md` → Decisions.

`robot.sh` renders `robot.svg`, the reference picture `robot_front_source.png` and the 3D body `robot_body_three_quarter.png` into the app's pictures, all in the same 512-pixel square:

| Picture | Shows | Made with |
| --- | --- | --- |
| `robot_head.png`, `robot_body.png` | the robot split at the neck, for the splash (`RollingRobot`) | `robot.svg` |
| `assets/images/robot.png` | the game's three-quarter view | the head over the 3D body (`tool/robot/three_quarter.html`) |
| `robot_front.png` | facing the child | the reference picture's head (background cleared, face erased, colours matched) with the body drawn straight on (`tool/robot/front.html`) |
| `robot_back.png` | from behind: a back panel, neck band and battery hatch | the same page |

The game shows which way Koba faces: a headlight beam on the tile ahead, its back facing up the board, its side facing left or right, its front facing down, and eyes looking that way. Faces are drawn in code over its screen (`paintRobotFace`, `lib/core/character/robot_face.dart`: blinks, dizzy after a bump, star eyes at the flag). Koba's head (`KobaHead`) looks at what a guided tour explains, and its eyes follow the child's touch on the player picker and the map.

### 3D model

Built from simple shapes in Blender (`brew install --cask blender`), since AI image-to-3D lost the details:

```sh
blender -b -P tool/robot/build_model.py -- build/robot3d/koba [angles…]   # koba.glb, koba.blend and renders (0 faces the viewer, 90 shows its left)
```

`tool/robot/render_body.py` renders the body alone for `robot_body_three_quarter.png` (the command is in `robot.sh`), and `tool/robot/render_turn.py` renders the turning frames in `assets/images/robot_turn.webp`.

## The ship

Koba's star ship for the Star fuel story is built the same way:

```sh
blender -b -P tool/ship/build_ship.py -- branding/ship [ship.blend]
tool/ship/export.sh   # copies the views and tank masks into assets/images/ at half size
```

It renders four 1024-pixel views to `ship/`, all at the same scale: `landed`, `launch` (a big flame), `landing` (a small flame) and `flying` (nose to the right; mirror it to fly left). Each has a `<view>_tank.png` mask of the tank's window, so the game draws the tank's fill at any level, and `ship.json` gives each view's base, tank fill axis and cockpit in pixels. `ShipGeometry` (`lib/features/story/data/story_art.dart`) holds half of those numbers, and a test keeps them in step.

## App icon

Koba's head on plain coral, drawn in `icon.svg`, with a one-colour version for Android 13 themed icons in `icon_monochrome.svg`. Keep the foreground inside the central 66% (Android's safe zone). After editing either, run:

```sh
branding/render.sh
```

It renders the PNGs with headless Chrome and generates every platform's icons with `flutter_launcher_icons` (config: `flutter_launcher_icons.yaml`), never edit those by hand. `play_store_icon.png` is the 512 × 512 icon for the Play Console. On iOS 18+ the dark and tinted icons come from the head alone; iOS and macOS 26+ use the Liquid Glass icon `AppIcon.icon` (in `ios/Runner/` and `macos/Runner/`, written by the same script). Preview it with Xcode's `ictool` (inside `Icon Composer.app/Contents/Executables/`, `--rendition Default|Dark|TintedLight|ClearLight`).
