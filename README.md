# Coba Lagi

A coding-learning app for children of all ages, in Bahasa Indonesia and English.

- **Picture blocks** (pre-readers, about 4–7): icon blocks and voice instructions.
- **Typed code** (readers, about 7–14+): the same program typed as text, a tap away from the blocks. The Code tab shows for children the warm-up game finds can read; parents can turn it on or off per child.

Blocks and code drive the same game world. A short, voice-led placement game picks each child's starting point, and the app then chooses to advance, practise or review after every lesson.

Primary target: Android tablets in landscape. The code stays compatible with iOS, web and desktop, in Google Play's closed test (Android) and released on the [App Store](https://apps.apple.com/app/id6823508005) for iPhone and iPad (the Mac version is in review); GitHub [Releases](https://github.com/ardeman/project_cobalagi_flutter/releases) carry Android APKs and a Linux AppImage (also for the Steam Deck). See Roadmap → Next: more platforms.

> **Status:** version 2.6.1 (build 23) is live on the App Store for iPhone and iPad (checked 2026-10-20), in review for the Mac, and in Google Play's closed test: Koba the robot exploring the Warm-up planet and nine coding planets, picture blocks and typed code, voice-over in Indonesian and English, stickers, and the parent area with donations (tips on the App Store). Still to come: the public release on Google Play after the closed test and the Mac App Store release (released automatically once approved); see the roadmap.

Website: [cobalagi.ardeman.com](https://cobalagi.ardeman.com) (source in `website/`).

## Screenshots

<table>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/adventure-map.png" alt="The adventure map in space with ten planets, the Warm-up planet first"><br>
      <b>Adventure map:</b> one planet per idea, with stars and a sticker book.
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/warm-up-island.png" alt="The Warm-up planet with six picture games and their stars"><br>
      <b>Warm-up planet:</b> counting, colours, shapes, patterns, left and right, and steps.
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/hint-loops-03.png" alt="A Loops puzzle: the hint shows the blocks along a dotted trail"><br>
      <b>Hint:</b> the level's own blocks along the route; asked again, the shape that repeats.
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/play-code.png" alt="The same puzzle as typed code, coloured like the blocks"><br>
      <b>Typed code:</b> readers type the program; commands share their blocks' colours.
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/play-functions.png" alt="A Magic Block puzzle: the star row holds a stair step"><br>
      <b>Magic Block:</b> build your own block once, then use it again and again.
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/play-otherwise.png" alt="An Otherwise puzzle: the two-row eye block in a hedge maze"><br>
      <b>Otherwise:</b> if the path is clear, step; otherwise, turn.
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/play-variables.png" alt="A Step Box puzzle: the box holds 3, used by two moves"><br>
      <b>Step Box:</b> save a number once and move by it.
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/sticker-book.png" alt="The sticker book with earned and empty stickers"><br>
      <b>Sticker book:</b> a sticker for every finished planet and Warm-up game.
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/solved.png" alt="A solved puzzle with a cheer and a Next button"><br>
      <b>Solved:</b> varied cheers, then back to the planet (or the map once the planet is complete).
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/parent-placement.png" alt="Parent area dialog for choosing a child's starting planet"><br>
      <b>Parent area:</b> behind a grown-up check; rename a player or change their picture, set the starting planet or replay the warm-up.
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="website/screenshots/parent-progress.png" alt="A child's progress report with puzzles, play time and planets"><br>
      <b>Progress report:</b> (sponsor feature) puzzles, play time and every planet.
    </td>
    <td width="50%" valign="top">
      <img src="website/screenshots/adventure-map-id.png" alt="The adventure map in Bahasa Indonesia"><br>
      <b>Bahasa Indonesia:</b> every screen in Indonesian and English.
    </td>
  </tr>
</table>

| Item | Value |
| --- | --- |
| Package name | `cobalagi` |
| App / bundle ID | `com.ardeman.cobalagi` |
| Dart SDK | `^3.11.0` (built with Flutter 3.41.1, stable) |
| Lints | [`flutter_lints`](https://pub.dev/packages/flutter_lints) via `analysis_options.yaml` |

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install) on the stable channel, plus the toolchain for the platform you target (Android Studio, Xcode, etc.). Run `flutter doctor` to check.

```sh
flutter pub get
git config --local core.hooksPath .githooks
flutter run            # choose a device; or: flutter run -d chrome
```

## Commands

| Task | Command |
| --- | --- |
| Install dependencies | `flutter pub get` |
| Run (debug) | `flutter run -d <device>` |
| List devices | `flutter devices` |
| Format | `dart format .` |
| Static analysis | `flutter analyze` |
| Tests | `flutter test` |
| On-device tests (real app and audio; not part of Checks) | `flutter test integration_test -d macos` |
| Enable commit-message hook (once per clone) | `git config --local core.hooksPath .githooks` |
| Release build | `flutter build <apk\|appbundle\|ipa\|web\|macos\|linux\|windows>` |
| Installable Android APKs (one per architecture) | `flutter build apk --release --split-per-abi` |
| Publish the APKs (and the AppImage, if built) as a GitHub Release by hand (`--dry-run` to only build; `--latest` for a full release). Pushing a version bump to `master` does this automatically (`.github/workflows/release-apks.yml`: the checks, the APKs (`--build-only`) and the AppImage build side by side, then one job publishes them with `--skip-build`). | `tool/release_apks.sh` |
| Linux and Steam Deck AppImage (x86_64 Linux only; CI builds it for every release) | `tool/build_appimage.sh` |
| Steam library artwork (macOS, headless Chrome) | `tool/steam_art.sh` |

**Checks** — run all three before every commit. They must pass with no errors or warnings:

```sh
dart format --set-exit-if-changed . && flutter analyze && flutter test
```

Commit subjects must use `type(scope)!: description`, with optional scope and
`!` for breaking changes. Allowed types are `feat`, `fix`, `docs`, `style`,
`refactor`, `perf`, `test`, `build`, `ci`, `chore` and `revert`. For example:
`feat(profiles): add avatar picker`. Bodies and footers are optional.

The versioned `.githooks/commit-msg` hook rejects invalid subjects, including
default merge and revert messages; give those commits a conventional subject
such as `chore: merge feature branch` or `revert: undo avatar picker`.
Enable it after each clone using the setup command above. Local Git hooks can
be bypassed with `--no-verify`; they do not enforce remote repository policy.

## Project layout

```text
lib/
  main.dart        Opens storage, wires services, starts the app
  app/             App widget, router, theme, l10n (ARB files + generated code)
  core/            Shared services: storage, settings, entitlement, audio, responsive,
                   widgets (bounded glass panels and the ambient background)
  engine/          Pure Dart: instruction set (program/), levels (world/), interpreter, solver + puzzle generator
  learning/        Pure Dart: skill graph, mastery scoring, advance/practice/review rules
  features/        One folder per feature (profiles, adventure_map, play, editors,
                   learning, pretest, parent, splash, story)
test/              Mirrors lib/
integration_test/  Tests that drive the real app on a device (e.g. warm-up voice timing)
.githooks/         Versioned Git hooks for commit-message validation
tool/              Developer scripts (voice clips, screenshot renders)
branding/          App icon source (SVG), rendered PNGs and branding/render.sh
store/             Store listings: google_play/ and app_store/ per language (id, en-US), changelogs/ per language, releases.json, render.sh
website/           Static landing page for cobalagi.ardeman.com, plus screenshots
assets/config/     skills.json (skill map), adaptive.json (learning thresholds),
                   pretest.json (placement rules and warm-up vocabulary)
                   warm_up.json (Warm-up island games and round length)
assets/levels/     Hand-made lesson packs (JSON), one per concept
assets/audio/      Voice clips per language: <id|en>/<clipId>.mp3 (see Voice-over)
android/ ios/ web/ macos/ linux/ windows/
                   Platform runners, mostly generated by Flutter
```

## Voice-over

Every clip the app plays is listed in `lib/core/audio/voice_clips.dart` with the text to record. Missing clips are skipped silently, so the app works before recording.

```sh
dart run tool/voice_script.dart id > voice_id.csv   # Indonesian script: id, file, text, status
dart run tool/voice_script.dart en > voice_en.csv   # English
```

Record each row as an MP3 at the listed path (`assets/audio/<language>/<clipId>.mp3`). Run the script again to see what is still missing.

**ElevenLabs (the chosen voices):** `tool/generate_voice.dart` makes every clip with ElevenLabs, then trims and levels it like the test voices. Shipping the clips needs an ElevenLabs plan with a commercial license (Starter or higher); the free plan is fine for auditioning.

```sh
cp .env.example .env                          # then put your key in .env (git-ignored)
dart run tool/generate_voice.dart --voices    # list voices in your account
# put the chosen voice_id per speaker and language in tool/elevenlabs.json
dart run tool/generate_voice.dart --sample    # 5 sample lines per language in build/voice_samples/
dart run tool/generate_voice.dart             # all clips (replaces test voices)
dart run tool/generate_voice.dart --only cheer_celebrate_1   # redo one clip
dart run tool/generate_voice.dart --speaker koba --force     # redo one speaker's clips
dart run tool/design_voice.dart               # Voice Design previews for Koba in build/voice_samples/koba/
dart run tool/design_voice.dart --save <generated_voice_id>  # keep a preview as a voice
```

Model, voices and settings (`speed`, `stability`, `style`…) live in `tool/elevenlabs.json`, under `voices.<speaker>.<language>`. Every clip names its speaker in `VoiceClips` (`kobaSays` or `narratorSays`): Koba says its tours, goals, hints, feedback, cheers, demos and its introduction, in the first person; the narrator says the warm-up's questions, announcements and the story's narration. When the test voices are replaced, the tool removes `assets/audio/TEST_VOICES`. The narrator uses Cahaya (Indonesian) and Jessica (English); Koba has one voice made with Voice Design for both languages. The clips are committed in `assets/audio/`.

**Sound effects:** `tool/generate_sfx.dart` makes the game sounds (`SoundEffect`: step, turn, a bump for each obstacle material, star, goal, drop) with ElevenLabs' sound-effects model, from the prompts in `tool/sound_effects.json`, into `assets/audio/sfx/`. The API key needs the *Sound Effects* permission.

```sh
dart run tool/generate_sfx.dart               # missing effects
dart run tool/generate_sfx.dart --only goal   # redo one
```

**Background music:** `tool/generate_music.dart` composes the looping theme (`MusicTrack`) with ElevenLabs Music from the prompt in `tool/music.json` into `assets/audio/music/`. The API key needs the *Music* permission. Run `dart run tool/generate_music.dart --force` to compose a new one.

**Test voices (macOS):** to hear the voice flow before real recordings exist, generate every clip with the Mac's built-in voices (Damayanti for Indonesian, Flo for English):

```sh
dart run tool/test_voices.dart          # create missing clips (needs ffmpeg)
dart run tool/test_voices.dart --clean  # remove them again
```

Apple's license doesn't cover shipping these voices, so they are marked by the git-ignored `assets/audio/TEST_VOICES`, and **release builds refuse to build while that marker exists**. Don't commit clips while the marker is present; restore the real ones with `git checkout assets/audio` (or regenerate them) and run `--clean`.

After adding or replacing clips, Android builds may keep using an old asset list. Clear it with `rm -rf build/app/intermediates/flutter .dart_tool/flutter_build` (or `flutter clean`) before building.

## Release (Google Play)

1. Create an upload key once and keep it safe (never commit it):

   ```sh
   "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/cobalagi-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   macOS has no system Java, so this uses the Java bundled with Android Studio. Back up the `.jks` file and its password outside this Mac; without them you can't publish updates.

2. Create `android/key.properties` (git-ignored):

   ```properties
   storeFile=/Users/<you>/cobalagi-upload.jks
   storePassword=<password>
   keyAlias=upload
   keyPassword=<password>
   ```

   Without this file, release builds are debug-signed: fine for testing, rejected by Google Play.

3. For each new build ("bump and build"), follow the checklist below.

### Bump and build checklist

1. **Version.** Raise the build number after `+` in `pubspec.yaml` by one. Pick the name from the rules in `AGENTS.md` → Version: ask whether the previous build is already live in a Google Play track. If it isn't, keep its name (`1.4.0+11` → `1.4.0+12`); if it is, raise MINOR for new features or PATCH for fixes only.
2. **Release notes.** Write `store/changelogs/en-US/<build>.txt` and `store/changelogs/id/<build>.txt` (one `- ` line per change, plain words for parents, at most 500 characters each, both saying the same), add `{ "build", "version", "date" }` to `store/releases.json`, then run `dart run tool/website_changelog.dart`.
3. **Listing text.** If a feature changes what `store/google_play/<locale>/full_description.txt` or `website/index.html` claim, update both languages.
4. **Screenshots.** Run `flutter test tool/screenshots --update-goldens`, `tool/screenshots/export.sh` and `store/render.sh`. Headless Chrome is sometimes killed mid-render (exit 137, slides deleted): run `store/render.sh` again until it exits 0 and `ls store/google_play/*/phone_screenshots/*.png store/google_play/*/screenshots/*.png | wc -l` gives 32.
5. **Drop render noise.** The solved and warm-up screens pick a random cheer and confetti, so they change on every render. If their screen didn't change, restore them: `git checkout -- 'store/google_play/*/6-solved.png' website/screenshots/solved*.png website/screenshots/phone-solved*.png website/screenshots/warm-up-pattern*.png website/screenshots/phone-warm-up*.png website/screenshots/warm-up-colors*.png website/screenshots/phone-warm-up-colors*.png`. Look at every other changed slide before keeping it.
6. **Checks and builds.** Run the Checks, then `flutter build appbundle --release` (for Play) and `flutter build apk --release --split-per-abi`.
7. **Tell the user what to upload:** the bundle path, the release notes, and which listing items changed since the listing on Play (Store listing → Updating the Play listing), naming the Play Console field for each and marking slides that only changed slightly as optional. When the user says the listing is uploaded, mark that build `"listing": true` in `store/releases.json`.
8. **Commit and push only when asked**, as two commits: the feature work (`feat:`/`fix:`), then `build: bump version to <name>+<build>` with `pubspec.yaml`, `store/` and `website/`. Pushing the version change publishes the APKs and the Linux AppImage to GitHub Releases; watch it with `gh run watch $(gh run list --workflow release-apks.yml --limit 1 --json databaseId --jq '.[0].databaseId') --exit-status`.

### Checking UI changes

- **Renders:** `flutter test tool/screenshots --update-goldens --plain-name '<test>'` (for example `'tablet en map'`) draws a screen into `tool/screenshots/out/`. For a screen without a test, add a temporary `testWidgets` there, look at the image, then remove the test and its `out/*tmp-*` images. Renders draw plain blurs, not liquid-glass shaders.
- **Emulators** (AVDs `Pixel_9a`, `Redmi_Pad_2`): start one with `~/Library/Android/sdk/emulator/emulator -avd <name> &`, drive the app from a temporary test in `integration_test/` with `flutter test integration_test/<file> -d emulator-5554`, print a marker at each step, and grab `adb exec-out screencap -p` when it appears. The emulator's own rotation is unreliable: set orientation inside the test with `SystemChrome.setPreferredOrientations`. Delete the temporary test afterwards.

**Play Console:**

- **Donations:** create one-time in-app products whose ids match `assets/config/donations.json` (`supporter_small`, `supporter_medium`, `supporter_large`), with prices of your choice, spread out (small, medium, large). Any of them unlocks the sponsor plan, so the small one is in effect the price of the sponsor features; keep the App Store's tips at the same prices. Test with license testers.
- **Families policy:** target audience is children, with no ads and no data collection. The release build has no internet permission. Privacy policy URL: `https://cobalagi.ardeman.com/privacy.html`.

## Launch updates

On Android, the app asks Google Play for an available update at launch and
whenever it comes back to the foreground. The splash waits for the answer for up
to two seconds; Play is often slower on a cold start, so a later answer (within
30 seconds) is offered on the player picker instead. If one is available, the
notice offers continuing to play (which hides it for the session) or asking a
parent to update. The update action requires the parent gate; Google Play handles
the download and installation. Unavailable stores, offline devices and slow
checks continue to play without a notice. iOS, web and desktop skip the check.

Use a Google Play test track to verify the real update flow: install an older
build from Play with the test account, then make a higher version code available
to that account. Direct APK installs do not have a separate update source. See
[Google's in-app update testing guide](https://developer.android.com/guide/playcore/in-app-updates/test).

## macOS

```sh
flutter build macos --release   # → build/macos/Build/Products/Release/Coba Lagi.app
```

- Needs macOS 12 or later, Xcode and CocoaPods. The window opens at 1280 × 800 and can't shrink below 960 × 600.
- **Apple Silicon only (`ARCHS = arm64`).** Xcode 27's `lipo -verify_arch` accepts one architecture per call, which breaks Flutter 3.41's universal-build check. Remove `ARCHS = arm64` from `macos/Runner.xcodeproj` once Flutter handles it, to bring back Intel Macs.
- **Local builds** are signed for development, so they run only on the developer's Mac (`open "build/macos/Build/Products/Release/Coba Lagi.app"`). Macs get the app from the Mac App Store (below) or from GitHub Releases.
- **GitHub build:** CI (`.github/workflows/macos.yml`) builds it unsigned, signs it with the Developer ID certificate and the hardened runtime, has Apple notarize it, staples the ticket and adds `CobaLagi-macOS.zip` to each release (it also runs whenever `macos/` or `pubspec.lock` changes on `master`). It keeps unlock codes and has no store billing, like other GitHub builds, and shares its progress container with the Mac App Store build (same app ID). Secrets: `MACOS_CERTIFICATE_P12_BASE64` (the Developer ID Application certificate exported from Keychain Access as `.p12`, base64), `MACOS_CERTIFICATE_PASSWORD`, and `APPLE_API_KEY_P8` (an App Store Connect API key with the Developer role; its key and issuer ids are in the workflow). Without them the job skips with a warning and releases go out without the Mac zip. The certificate expires on 2 February 2027: before then, create a new one (Xcode → Settings → Apple Accounts → Manage Certificates → + → Developer ID Application) and replace both certificate secrets. Apps already released keep opening.
- **Mac App Store build:** `flutter build macos --release --dart-define=APP_STORE=true`. It sells tips through the App Store (the same products as iOS) and has no unlock codes (`StoreRules`). To upload, run that command first (Xcode's archive reuses its `--dart-define`s from `macos/Flutter/ephemeral/Flutter-Generated.xcconfig`), then in Xcode (`macos/Runner.xcworkspace`) choose Product → Archive and Distribute App → App Store Connect. Signing is automatic with the developer's team. Builds are uploaded by hand, not with Xcode Cloud; to automate uploads later, add an App Store upload step to the GitHub release workflow instead. Other macOS builds have no store billing, so they stay on the free plan; unlock codes still work.
- Release builds run in the app sandbox (`macos/Runner/Release.entitlements`, no network) and save progress in the app's sandbox container. `macos/Runner/PrivacyInfo.xcprivacy` says the app tracks and collects nothing, and `Info.plist` sets the Education category and `ITSAppUsesNonExemptEncryption = NO`.

## Linux and Steam Deck

```sh
tool/build_appimage.sh   # → build/release/CobaLagi-x86_64.AppImage
```

- One x86_64 AppImage for Linux PCs and the Steam Deck: SteamOS's system is read-only, so the AppImage bundles GTK and GStreamer (audio, MP3 through `gstreamer1.0-plugins-good`) and takes only glibc and the graphics drivers from the system. CI builds it on Ubuntu 22.04, the oldest glibc it supports, and adds it to each GitHub Release next to the APKs (`.github/workflows/release-apks.yml`); the release notes say how to run it and add it to Steam as a non-Steam game. Its name never changes, so updating is replacing the file: the Steam shortcut keeps working and progress stays in the home folder.
- **Adding it to Steam:** each release carries `linux/steam/CobaLagi-Steam-Installer.desktop`, a launcher like Decky's installer: double-clicked, it opens Konsole, downloads `linux/steam/CobaLagi-Steam-Installer.sh` from `master` and runs it, so a change to the script reaches every new install without a release. The script also runs on its own: `bash CobaLagi-Steam-Installer.sh`. It downloads the library artwork from `master` (`linux/steam/artwork/`, rendered on a Mac by `tool/steam_art.sh` from the robot and the icon; run from the repo it uses the folder next to it). Run in Desktop Mode, the script downloads the newest release's AppImage (pre-releases too, through GitHub's API; given a path, it uses that file instead, and offline it looks for a downloaded copy) into `~/Applications`, closes Steam, adds or updates a "Coba Lagi" non-Steam shortcut in every Steam user's `shortcuts.vdf` (keeping a `.bak`), copies the capsule, wide capsule, hero, logo and icon into `config/grid/` under the shortcut's app id, and starts Steam again. Running it again updates the game and the shortcut, never duplicates. It also copies itself to `~/.local/share/cobalagi-steam/` and adds "Uninstall Coba Lagi" to the Desktop Mode menu, which runs it with `--uninstall`: that removes the shortcut, its pictures, the AppImage and the menu entry, and deletes the players' progress only if asked to. `STEAM_DIR=<folder>` points it at a test copy of Steam.
- It builds only on x86_64 Linux; on a Mac, push a version bump and let CI build it. The tools (linuxdeploy and its GTK and GStreamer plugins) are pinned in the script. The desktop entry and icon are in `linux/packaging/` (the icon comes from `branding/render.sh`).
- **Controllers:** the Deck's controls (and any Xbox, PlayStation or other pad, on every platform) work without touching the screen: the d-pad or left stick moves a glowing highlight, the right stick scrolls, A presses, B goes back, X goes on (Go, Next in a tour), ☰ (menu) plays the spoken words again, X also plays (Play, Play level, "Let's go!" after the warm-up), ⧉ (view) shows the tour on the play screen and in the warm-up games, and "Watch how" on a planet, ☰ (menu) opens the parent area on the player picker, Y turns the map on the play screen, opens the stickers on the map and continues the adventure next to Play level (alone, that's X), L3 (press the left stick) is the hint, L1 and R1 undo and redo, and R3 (press the right stick) switches between Blocks and Code. To drag a block (or a new one from the palette), hold R2 on it: the stick drags it freely like a finger, the d-pad steps it from spot to spot (back onto the palette deletes it); let go to drop it (B puts it back); each control shows its button while a controller is in use. In a dialog with a text field, X saves and B cancels; on the Deck (Game Mode or Big Picture) a text field opens Steam's on-screen keyboard as soon as it gets focus, through `steam://open/keyboard`, and leaving the field closes it (`steam://close/keyboard`); while it shows, the app treats the bottom half of the screen as covered, so dialogs move above it. In Steam, keep the non-Steam game's controller layout on "Gamepad". Code: `lib/core/gamepad/` (AGENTS.md → Conventions).
- The window opens at 1280 × 800 (the Deck's screen) and can't shrink below 960 × 600, as on macOS. Progress is saved in the user's home folder. Free plan only (no store billing); unlock codes still work.

## Windows

```sh
flutter build windows --release   # → build/windows/x64/runner/Release/cobalagi.exe
```

- Builds only on Windows; CI builds it (`.github/workflows/windows.yml`) whenever `windows/` or `pubspec.lock` changes on `master`, so a broken build shows before a release, and on every version bump, when it adds `CobaLagi-Windows-x64.zip` to the GitHub Release (`.github/workflows/release-apks.yml`). The zip holds a "Coba Lagi" folder with `cobalagi.exe` and the Visual C++ runtime DLLs, so it runs without installing anything.
- Not code-signed yet, so SmartScreen warns on the first run (More info → Run anyway) until there is a code-signing certificate.
- The window opens at 1280 × 800 and can't shrink below 960 × 600, as on macOS and Linux (`windows/runner/`). Progress is saved in the user's AppData folder, under the company and product names in `windows/runner/Runner.rc` (changing them loses saved progress). Free plan only (no store billing); unlock codes still work. Controllers work as on the Steam Deck (Linux and Steam Deck → Controllers).

## Character

The friend children program is a small teal robot, exploring planets in space. Its picture is `branding/robot.svg`; `branding/robot.sh` renders it, split at the neck, to `robot_head.png` and `robot_body.png` for the splash screen, and puts its head over the 3D robot's body turned the same way (`branding/robot_body_three_quarter.png`, see below) for `assets/images/robot.png`, the game's three-quarter view (`tool/robot/three_quarter.html`). The same script makes `robot_front.png` (facing the child) and `robot_back.png` (from behind: a back panel and neck band, a battery hatch) with `tool/robot/front.html`: it keeps the head of the reference picture `branding/robot_front_source.png` (background cleared, face erased, colours matched) and draws the neck, body, arms and wheels facing straight on, in the 3D robot's proportions. All are in the same 512-pixel square. The game draws it upright on its tile and shows its facing itself: a soft headlight beam lights the tile it faces (and sweeps round as it turns), facing up the board it shows its back (`robot_back.png`), facing left or right it shows that side, facing down it faces the child (`robot_front.png`), and its eyes look the way it faces. Its faces are drawn over the screen in code (`paintRobotFace` in `lib/core/character/robot_face.dart`: normal with blinks, dizzy after a bump, star eyes at the flag), so every expression is the same robot. Koba's head (`KobaHead`) looks at what the guided tour explains, and on the player picker and the map (`KobaHead.follow`) its eyes follow the child's touch and the controller's highlight; it stays off the coding board so it doesn't distract. The splash (`RollingRobot`) rolls it on the spot: spokes turn on its wheel hubs, it bounces, its head nods a beat behind, and road marks slide past; it holds still when the system asks for less motion.

Each planet's puzzle world (`WorldTheme` in `lib/features/play/view/world/world_theme.dart`) has its own starry sky, ground, obstacles and finish, and every finish carries the red flag the voice talks about.

The robot was designed with AI (Recraft V3 on fal.ai) and is finished: `branding/` holds its artwork, and `branding/robot.sh` rebuilds every picture from it without any AI service. AI animation (Omnilottie) only handled very simple shapes, so the game animates the robot in code instead.

The robot also exists in 3D, built from simple shapes in Blender (`brew install --cask blender`) by `blender -b -P tool/robot/build_model.py -- build/robot3d/koba [angles…]`: Koba's colours, drawn-looking outlines and inner lines, a blank screen for the app's faces, and separate head and wheels for animation. It writes `koba.glb` and `koba.blend` and renders the given angles (0 faces the viewer, 90 shows its left) to compare with the pictures. `tool/robot/render_body.py` renders its body alone for `branding/robot_body_three_quarter.png` (the command is in `branding/robot.sh`). AI image-to-3D (Tripo and Hunyuan3D on fal.ai) got the shape but not the details, so the model is built by hand.

Koba's star ship, for the Star fuel story, is built the same way: `blender -b -P tool/ship/build_ship.py -- branding/ship [ship.blend]` models a round coral rocket with a teal nose, Koba's antenna, a round cockpit window (where Koba sits), a tall star tank window and three teal fins that are also its legs, in Koba's colours with navy outlines and one flat shade on the side away from the light. It renders four 1024-pixel views to `branding/ship/`, all at the same scale: `landed` (engine off), `launch` (a big flame), `landing` (a small flame) and `flying` (nose to the right, for flying between planets; mirror it to fly left). Each has a `<view>_tank.png` mask of the tank's window, so the game draws the tank's fill at any level clipped to it, and `ship.json` gives, per view in pixels, the ship's base, the tank's fill axis (bottom to top, and its width) and the cockpit's middle and radius. `tool/ship/export.sh` copies the views and masks into the app at half size (`assets/images/ship_<view>.webp`, `ship_<view>_tank.webp`); `ShipGeometry` in `lib/features/story/data/story_art.dart` holds half of `ship.json`'s numbers, and a test keeps them in step. In the app Koba's face looks out of the cockpit window, drawn in code like its other faces.

## Website

`website/` is published to [cobalagi.ardeman.com](https://cobalagi.ardeman.com) by GitHub Pages. `.github/workflows/pages.yml` deploys it on every push to `master` that changes `website/`, and can also be run by hand from the Actions tab. Preview locally with `open website/index.html`; add `?lang=en` or `?lang=id` to pick a language.

One-time setup (already done for this repo): Pages source **GitHub Actions**, custom domain `cobalagi.ardeman.com` (also in `website/CNAME`), and a DNS `CNAME` record `cobalagi` → `ardeman.github.io`.

## App icon

The icon (the robot's head on plain coral) is drawn in `branding/icon.svg`, with a one-colour version for Android 13 themed icons in `branding/icon_monochrome.svg`. After editing either, run `branding/render.sh`: it renders the PNGs with headless Chrome and generates every platform's icons with `flutter_launcher_icons` (config: `flutter_launcher_icons.yaml`). `branding/play_store_icon.png` is the 512 × 512 icon for the Play Console. On Apple systems the icon follows the home screen's look: iOS 18+ dark and tinted versions come from the head alone (`image_path_ios_*` in `flutter_launcher_icons.yaml`), and iOS and macOS 26+ use the Liquid Glass icon `AppIcon.icon` (an Icon Composer document in `ios/Runner/` and `macos/Runner/`, written by the same script), which the system turns dark, clear or tinted. Preview one with Xcode's `ictool` (inside `Icon Composer.app/Contents/Executables/`, `--rendition Default|Dark|TintedLight|ClearLight`).

## Store listing

`store/google_play/<locale>/` holds the Google Play listing for Indonesian (`id`) and English (`en-US`): `title.txt` (max 30 characters), `short_description.txt` (max 80), `full_description.txt` (max 4,000), plus `feature_graphic.png` (1024 × 500), `screenshots/` (1920 × 1080, 16:9) for the 7-inch and 10-inch tablet sections and `phone_screenshots/` (1080 × 1920, 9:16) for the phone section. The app icon for the listing is `branding/play_store_icon.png`. Each build's release notes (max 500 characters) are in `store/changelogs/<locale>/<versionCode>.txt`, shared by every store, GitHub Releases and the website.

`flutter test tool/screenshots --update-goldens && tool/screenshots/export.sh` renders every screenshot from the real app with sample data into `website/screenshots/`, in Indonesian and English. Tablet and phone store sets each contain eight slides: the map, Loops, typed code, Magic Block, Fix it!, a solved puzzle, Until the flag, and the parent controls with the progress report. `store/render.sh` then re-renders the graphics from `website/screenshots/` and the icon art. `dart run tool/website_changelog.dart` rebuilds the website's release notes page (`website/changelog.html`) from `store/releases.json` and the store changelogs. Play doesn't allow ranking or promotional words ("best", "#1", "new", "sale"), calls to action or emoji in the listing.

### Updating the Play listing

Play Console → Grow → Store presence → Main store listing, once per language: Indonesian (`id`, the default) and English (`en-US`, under "Manage translations").

| Play Console field | File |
| --- | --- |
| App icon (both languages) | `branding/play_store_icon.png` |
| Feature graphic | `store/google_play/<locale>/feature_graphic.png` |
| Phone screenshots | `store/google_play/<locale>/phone_screenshots/1-…8-*.png` |
| 7-inch and 10-inch tablet screenshots | `store/google_play/<locale>/screenshots/1-…8-*.png` (the same set in both sections) |
| App name, short and full description | `store/google_play/<locale>/title.txt`, `short_description.txt`, `full_description.txt` |
| Video | The landscape promo's YouTube link (see Promo videos, below) |
| Release notes (in the release, not the listing) | `store/changelogs/<locale>/<build>.txt` |

Upload slides in order, 1 to 8; delete the old ones first, because Play takes at most eight per section. The listing on Play matches the newest build marked `"listing": true` in `store/releases.json`. To see what to re-upload, diff from that build's commit: `git diff --stat $(git log -1 --format=%h --grep 'bump version to .*+<build>$') -- store/ branding/play_store_icon.png`. Release notes and `releases.json` aren't part of the listing.

### App Store listing

`store/app_store/<locale>/` holds the App Store listing for Indonesian (`id`, the primary language) and English (`en-US`), one record for iOS, iPadOS and macOS: `name.txt` (max 30 characters), `subtitle.txt` (30), `keywords.txt` (100, commas without spaces; words already in the name or subtitle are left out, since Apple searches those too), `promotional_text.txt` (170, can change without a new build), `description.txt` (4,000) and `screenshots/{iphone,ipad,mac}/1-…8-*.jpg` (iPhone 6.3″ 1206 × 2622, the size App Store Connect requires; iPad 13″ 2752 × 2064; Mac 2880 × 1800). The files use fastlane deliver's names. The text says the same as the Play listing, except that purchases are tips handled by the App Store, never donations, and it never names Google Play or Android (guidelines 2.3.10 and 3.2.2); `test/store/store_text_test.dart` checks the limits and those words. `store/render.sh` renders the screenshots with the Play ones, from the 2x renders in `tool/screenshots/out/` (so run `flutter test tool/screenshots --update-goldens` first), as JPEG to keep them small. It also renders the creative assets for Header and Search Results: `header.png` (3840 × 1646, 21:9, the product page header; Koba and the tagline stay in the middle because narrow screens crop the sides) and `search_result.png` (3840 × 2560, 3:2). Apple reviews them apart from app versions, and they may not show prices, URLs or other platforms.

App Store Connect → the app, once per language for the text and screenshots:

| Setting | Value |
| --- | --- |
| Category | Education |
| Content Rights | No third-party content (the art, voices and music are the app's own) |
| App Privacy | Data Not Collected; privacy policy `https://cobalagi.ardeman.com/privacy.html` |
| Age rating | Parental controls yes (the parent area), age assurance no, every capability (web access, user-generated content, social media, messaging, advertising) no, and None or No for every content question, which gives 4+; then Made for Kids, ages 6–8, which puts the app in the Kids Category (it then can't be offered on visionOS) |
| Support URL | `https://cobalagi.ardeman.com` |
| App Review notes | Paste `store/app_store/review_notes.txt` (one English text for every language, iOS and macOS; keep it true when the app changes). It answers the Kids Category questions (guideline 1.3) up front, or review stops with "2.1.0 App Completeness" until they are answered. After replying to such a message, open the version, press Update Review, then Resubmit to App Review |
| Text and screenshots | `store/app_store/<locale>/` as above; upload slides in order, 1 to 8 (Apple takes up to 10) |
| Header and Search Results | `header.png` under Header and `search_result.png` under Search Results, per language (Product Page Information → Header and Search Results → Upload) |
| Version release | Automatically release this version, for iOS and macOS |

### Promo videos

Promo videos show real gameplay from the "Watch me!" demos. They are made in the separate `../../assets/ai-generated-content` repo (`cobalagi/`; its `README.md` has the commands, the formats and how to upload them to YouTube), like other generated media, so this repo holds no promo scripts or videos. What stays here is recording the gameplay frames they use (about 15 minutes, again whenever the demos look different): `VIDEO_FRAMES=1 flutter test tool/screenshots --update-goldens --plain-name 'video frames'`, into `tool/screenshots/out/video/`. The videos also use `website/screenshots/`, the voice clips and music in `assets/audio/`, the ARB words and the version in `pubspec.yaml`.

## Roadmap (MVP)

| Phase | Scope |
| --- | --- |
| 0. Foundation ✅ | Packages, theme, Indonesian/English, routing, local storage, responsive layout, audio, profiles, parent gate, free/full plan check |
| 1. Engine ✅ | Instruction set, world, interpreter, level JSON, solver (unit-tested, no UI) |
| 2. Play + picture blocks ✅ | Flame world with placeholder shapes, icon-block editor, run/step/reset, Directions and Sequencing levels |
| 3. Learning loop ✅ | Attempt tracking, mastery, advance/practice/review, generated variations, Loops levels, adventure map |
| 4. Pretest ✅ | Reading check and pre-skills, voice-led and adaptive; placement; parent override |
| 5. Hardening ✅ (code) | Donations through Google Play Billing (any donation unlocks sponsor features), release config, voice clips, tablet performance |
| 6. After MVP ✅ | Magic Block island (own block), parent progress report, sound effects and music, splash, how-to hint, warm-up second chance |
| 7. Conditions ✅ | Look Ahead island, six lessons, generated practice and an eye block that runs its contents only when the cell ahead is clear |
| 8. Typed code ✅ | Switch between blocks and code on every island, command buttons, line feedback and step highlighting, with the same engine and lesson limits |
| 9. Variables ✅ | Step Box island, six lessons, generated practice, stored-distance blocks and typed assignments |
| 10. Otherwise ✅ | Otherwise island (if / else): the eye block gets a second row for a blocked path, in a hedge maze; six lessons, generated wall-following practice, typed `if_path_clear { } otherwise { }` |

The eye block checks once before running its contents. Put a forward block
inside it to move safely; put the eye block inside a repeat to check again
on every turn of the loop. Tap a repeat or eye block, then a palette block
to fill it, or drag blocks into it. Checks appear as green (clear) or orange
(blocked) rings in the world. The Conditions island follows Magic Block.

The Code button opens a small teaching language. The first code draft is
copied from the current blocks; each editor then keeps its own draft for the
current puzzle. Commands use the same names in both app languages:

```text
define star {
  move();
  turn_right();
}
repeat(3) {
  if_path_clear {
    move();
  }
}
star();
```

Actions end with `();`. Repeats take counts from 1 to 9, and `//` starts a
comment. `turn_left();` turns left. Command buttons offer only the current
lesson's palette. The parser compiles to `Program` with source IDs; the shared
validator checks the palette, block limit, empty bodies and recursive calls.
Run and Step use the same interpreter as blocks. Editing and switching put the
world back at the start. On phones, the code editor fills the space while the
keyboard is open. Commands are coloured like their blocks (`colouredCode`), so
a child can match a line of code to the block it came from.

On phones (portrait), the world and the editor scroll as one page under a
glass top bar, which holds the Blocks/Code switch for readers, and glass controls (Go and
its buttons) at the bottom; the bars frost only while content is under them.
Phones held sideways (under 500 dp tall) keep the world and Go on the left and
scroll the editor on its own on the right, with the same small blocks; the
adventure map puts the islands in one row that scrolls sideways, starting at the current island; the warm-up game shrinks its pictures to fit the height and puts the question's
picture beside the answers. Tablets held upright use the stacked phone page
with a large world. A new block scrolls into view; Go and Step scroll back to the world
so the child watches the run.

Once every lesson on an island is solved, practice puzzles lead on to the
next island: after a solved puzzle at the practice mastery level, or after
`practiceLimit` exercises at most (`assets/config/adaptive.json`). The island
screen shows how many puzzles remain as a dotted trail to the next island's
emblem (`LearningEngine.puzzlesToMoveOn`). When a child moves on, play returns
to the map, where the new island grows in as its cloud and lock lift off
(`LearningState.islandToCelebrate`, cleared by `celebrated`); it holds still
when the system asks for fewer animations. Dropping a block gives a light
haptic tick on devices that have one.

The Warm-up island comes first on the map and is always open. It keeps the
warm-up game's picture questions for the youngest players, plus colours and
shapes, as separate games (`WarmUpGame` in `lib/learning/warm_up/`): counting,
colours, shapes, patterns, left and right, and steps. A round
(`roundLength` questions in `assets/config/warm_up.json`) starts at the
child's best level, goes up a level after a right answer and down after a
wrong one. Each game's stars are its best level; the island's stars are their
average. Warm-up games never change the coding path. To add a game, add a
`WarmUpGame` value with its question type, prompt text and voice clips, then
list it in `warm_up.json`.

The sticker book (the book button on the map, with a badge for new
stickers) holds a sticker for every coding island whose lessons are all
solved and every Warm-up game at three stars (`lib/learning/stickers.dart`).
Stickers are worked out from progress; only the ones already seen are saved,
so new ones pop in once.

Parents can set a break reminder (off, 15, 30 or 45 minutes of puzzle time; `PlayClock` pauses in the background). When it is due, the current puzzle finishes, then a "Time for a break!" screen comes before the next one; only a grown-up (parent gate) continues, which resets the time.

Every island opens with a "Watch me!" demo on a child's first visit: a voice explains the idea while a hand places blocks in the real editor and presses Go in the real world. Children watch, then press "Let's play!" (or Skip); "Watch how" on each island plays it again. Demos are scripts in `assets/config/tutorials.json` (a small level plus actions: add a block, set a count, pick and replace, press Go), with narration clips `tutorial_<concept>`; `test/features/tutorial/tutorial_test.dart` checks every island has one that ends solved. Seen demos are saved per child (`LearnerState.tutorialsSeen`).

Fix it! (debugging) follows the Step Box. Its puzzles open with blocks already placed that have one bug: a turn the wrong way, a step missing or one too many, a repeat count off by one, or a wrong turn inside the Magic Block. The child runs the program, watches where it goes off course and fixes it; every lesson is fixable with one change (`test/features/play/level_assets_test.dart`). Generated practice plants one bug in a verified Step-by-step or Loops solution. Lessons store the starter program in the level JSON (`"starter"`, see `lib/engine/program/program_json.dart`). Struggling children review Loops.

Until the flag (while loops) follows Fix it!. Its "repeat until the flag" block (`until_flag { … }` in code, `RepeatUntilGoal` in the engine) repeats its blocks with no count; the run ends on the flag, on a bump or at the step limit, and each round costs one step, so a loop that never moves still stops. It sits only in the main row and may hold actions and one Look Ahead check. Routes repeat a shape 3–7 times, the palette has no counted repeat, and the block limit leaves no room to write the steps out. Struggling children review Loops.

Variables follow Look Ahead on the map. The six Step Box lessons teach saving
a number, reusing it across equal-length corridors, changing it for a new
distance and collecting stars along the way. Generated practice follows the
same progression across five difficulty levels. The palette offers Save steps,
Use steps and turns; its command limit keeps the focus on stored distances.

Save steps has number buttons (1–9) and picture dots. Use steps moves the
current saved distance. In code, write `steps = 3;` then `move(steps);`.
The box starts empty on each run; using it before saving is highlighted before
execution. A save inside a conditional does not guarantee a value outside it.
The number shown in the world follows playback, including Step, and resets
when the program is edited. Both editors compile to shared `SetSteps` and
`MoveSteps` instructions; the world only displays interpreter events.

### Next: more platforms

Planned on 2026-10-15. The Apple Developer account is active since 2026-10-16.

| Where | Platforms | Built by |
| --- | --- | --- |
| Google Play | Android | CI (as now) |
| App Store | iOS (also the foldable iPhone Duo), iPadOS, macOS | Locally on the developer's Mac, uploaded with Xcode or Transporter |
| GitHub Releases (sideloading) | Android APKs (as now), macOS, Windows, Linux (also Steam Deck) | CI, when the version changes |

Steps, one small change each:

1. **App Store rules:** hide unlock codes in App Store builds (guideline 3.1.1 bans unlocking outside in-app purchase) and call the purchases support or tips there, not donations (only nonprofits may take donations). GitHub builds keep unlock codes. Done: `StoreRules` (`lib/core/entitlement/store_rules.dart`) treats every iOS build as an App Store build; build for the Mac App Store with `flutter build macos --release --dart-define=APP_STORE=true`.
2. **iOS and iPadOS config:** privacy manifest (`PrivacyInfo.xcprivacy`), `ITSAppUsesNonExemptEncryption = NO`, all orientations and resizing (no `UIRequiresFullScreen`), so iPad split view and the iPhone Duo's fold work. Folding or unfolding mid-puzzle keeps the puzzle. Check that music mixes with other audio as on Android. Done: `ios/Runner/PrivacyInfo.xcprivacy` (no tracking, no data collected; the plugins bring their own), the encryption key and the app's languages in `Info.plist`, and one audio session on iOS that mixes everything, voices too, so the app never stops a parent's music (iOS has no per-player sessions). The minimum is iOS 15, the oldest Xcode 27 builds for. iPhone Duo: the app lays out from the space it gets, so it resizes when the phone folds; scroll views keep clear of side insets too (`belowBars`), because the Duo's status bar sits on a side edge, and tests check the Duo's sizes (466 × 678 closed, 669 × 951 open, either way up): `test/side_insets_test.dart`, the warm-up fit test and a fold mid-puzzle. Upload with Xcode 27.1 or later, so the app reaches the Duo's screen edge; its simulator also comes with 27.1. Flutter doesn't report the Duo's fold on iOS (`MediaQuery.displayFeatures` is Android only), so a half-open Duo shows the app across the fold. Phones from 320 dp up fit the play screen's bars in both languages. Still to check on a real iPhone or iPad: split view and the music mixing.
3. **Mac App Store:** app sandbox and in-app purchase on macOS. Done in code: release builds were already sandboxed (checked: progress saves in the container, no sandbox denials), Mac App Store builds use store billing, and macOS has the privacy manifest, category and encryption key (see macOS). Signing uses the developer's team (automatic). App Store Connect has one record for iOS and macOS ("Coba Lagi: Belajar Coding", Indonesian first), so tips are shared between them. The tips are in-app purchases of type Non-Consumable with the ids in `assets/config/donations.json`, base country United States at $0.99, $2.99 and $4.99, with Indonesia set by hand to the Google Play prices (Rp 5,000, 19,000 and 49,000; any tip unlocks the sponsor plan, so the small one is the sponsor features' price). An Indonesian base doesn't work: Apple rounds Rp 5,000 and Rp 19,000 both up to $0.99 elsewhere, with Family Sharing on, so one parent's tip unlocks the whole family's devices (it can't be turned off again). Their names and descriptions say tip, never donation, in both languages. The first build (2.6.1+23) is in TestFlight and checked on a Mac: it starts, saves progress in its container, plays sound, and shows tips without unlock codes. A tip bought in TestFlight (sandbox, on 2026-10-16) loaded the App Store prices, went through and unlocked the sponsor plan.
4. **App Store listing:** Kids Category with an age band, privacy label "Data Not Collected", age rating, text within Apple's limits (subtitle 30, keywords 100, promo text 170 characters) in `store/` with a limits test, and iPhone 6.3″ and iPad 13″ screenshots from `store/render.sh`. Done: text and screenshots (also for the Mac) in `store/app_store/`, entered in App Store Connect with the settings in Store listing → App Store listing. iOS and macOS 2.6.1 (build 23, iOS built with Xcode 27.0) were submitted for review on 2026-10-16. On 2026-10-17 Apple paused iOS with its Kids Category questions ("2.1.0 App Completeness", guideline 1.3); they were answered and the same build resubmitted (see Store listing → App Store listing → App Review notes). iOS passed review and is live (released automatically; seen on the store on 2026-10-20); macOS waits for review and is set to release automatically. The tips' review screenshot must have an App Store screenshot size and no transparency. The EU trader details (Digital Services Act) were verified on 2026-10-17 and show on the EU App Store. iOS 2.7.0 (build 24) was built with Xcode 27.1, so the app reaches the iPhone Duo's screen edge. Still to do: check the app on the iPhone Duo simulator (folded and unfolded, upright and sideways), and add iPhone Duo screenshots (inner display 2007 × 2853, outer 1398 × 2034), optional now and required from April 2027 for apps built with the iOS 27.1 SDK.
5. **macOS on GitHub:** Developer ID signing and notarization in CI (needs the Apple account; secrets set with the user's approval). Done in CI (see macOS → GitHub build); its secrets are set (2026-10-16). Still to check once a release carries it: the zip opens without a warning on another Mac.
6. **Windows on GitHub:** a zip or installer built in CI. Unsigned builds show a SmartScreen warning until there is a code-signing certificate. Done: a zip built in CI (see Windows). Still to check on a Windows PC once a release carries it: it starts, sound, saving, a controller and the minimum window size.
7. **Linux and Steam Deck on GitHub:** an x86_64 AppImage built in CI (done: see Linux and Steam Deck). Still to check on the Deck once a release carries it: touch, the controls, the 1280 × 800 screen, audio (GStreamer) and Game Mode.
8. **Docs:** update AGENTS.md (build platforms, "Google Play only" decision), the intro and status above, the website and `privacy.html` where they name only Google Play. Done: `privacy.html` (dated 16 October 2026) covers App Store tips and updates and the Mac's missing network access, and the landing page links to the App Store (iPhone and iPad) and says the Mac version is still in review.

Windows, Linux and GitHub macOS builds have no store billing, so they stay on the free plan; unlock codes still unlock sponsor features.

### Next: the "Star fuel" story

Chosen on 2026-10-18. Since the app isn't public yet, all five steps are prepared now so the story ships with the first public release, instead of one phase per update.

Koba's ship runs on stars; a space wind scatters them over the planets, and the child (the commander) helps collect them. Played live by the app like the demos (no video), voiced in both languages, skippable, once per child, never in a bonus adventure or replay. A small book button on the map (⧉) plays the story again. Children with progress (testers) see the intro once too. Each arrival scene stands alone, since the warm-up can place a child past earlier planets.

Steps, one session each:

0. **The ship's illustration:** a proper illustration in `branding/` (not drawn in code), modelled by a Blender script from simple shapes like Koba's (`tool/robot/build_model.py`) and rendered in Koba's colours and light, with angles for taking off and landing. The tank's fill is drawn in code over its window, so it can show any level. Done: `tool/ship/build_ship.py` renders `branding/ship/` (see Character).
1. **Koba's voice:** Koba gets a voice of its own, gentle and calm: soft and patient like a kind friend, with little robot sound, so children aged 3–6 understand it easily. Designed with ElevenLabs' Voice Design, one voice for both languages so Koba sounds the same in Indonesian and English (if it doesn't speak Indonesian well, a matched pair). It says everything Koba says: guided tours, cheers, hints, the demos, its introduction in the warm-up and its story lines. The current voices stay as the narrator: the story's narration, questions and the rest of the warm-up. `tool/elevenlabs.json` gets the Koba voice, each clip in `VoiceClips` names its speaker, and Koba's clips are re-recorded. Record the choice under Decisions in AGENTS.md. Done: one Voice Design voice for both languages (`tool/design_voice.dart`, see Voice-over).
2. **Scene player, intro, leaving and flying:** a scene player shared by every scene. The intro (about 25 seconds): Koba flies happily, the wind scatters the stars, the ship lands, Koba bumps a rock and tries again, "Will you help me?". On finishing a planet, the map's celebration becomes the ship taking off, the stars flying into its tank (fuller each planet) and the ship flying to the next planet. Done: `StoryPlayer` (`lib/features/story/`) plays a `StoryScene`, beats of a voice clip, its words and pictures painted in code over the night sky; each beat waits for its voice, Skip (B) leaves, and "Watch again" (⧉) and "Let's play!" (X) end it, with still pictures under reduced motion. The intro (`IntroScene`, route `/child/<id>/story/intro`) opens from the map once the child has a starting point (testers too), saved as `story-intro` in `LearnerState.tutorialsSeen` (`Story`, `lib/learning/story.dart`), and the gold book button on the map plays it again. On the map, `ShipFlight` flies the ship from the finished planet to the new one (about 7 seconds, Koba saying `story_fly`), and the planet opens once it lands; the tank holds planets finished out of all planets (`Story.tankFill`).
3. **Arrivals for planets 1–5:** on first opening a planet, an arrival scene shows why Koba needs its skill, before the "Watch me!" demo. Directions: signposts every way; Step by step: stars on a winding path; Loops: the same steps again and again, "is there a shortcut?"; Magic Block: a block that remembers moves; Look ahead: fog, Koba's headlight. Done: `ArrivalScene` (`lib/features/story/view/arrival_scenes.dart`) lands the ship on the planet, painted in its `WorldTheme`, while the narrator sets the scene, then Koba shows its problem: it looks each way as the signpost's arrows light up in the arrow blocks' colours, hops along stepping stones collecting stars in order, climbs the same steps until the repeat block pops up, teaches the Magic Block its moves and copies pop out, and switches on its headlight to clear the fog off an ice spike. `PlayScreen` plays it before the demo, saved as `story-arrival-<concept>`; a planet explored before the story existed gets no arrival late. Each also plays at `/child/<id>/story/arrival-<concept>`.
4. **Arrivals 6–9 and the ending:** Step Box: a box that remembers a number; Fix it!: muddled blocks left behind; Until the flag: a far flag on a long road; Otherwise: a fork in the road. After the last planet, an ending: the tank full, "Thank you, commander!". The story must keep working when planets are added in later updates: the tank's fill is planets finished out of all planets, and a child who already saw the ending gets a "new planet" scene the first time a newer version has more planets (the space wind blew a few stars out of the tank to a planet nobody had found yet, so the tank never shrinks without a reason, and Koba asks the commander for help again); once the new planets are finished, a short "tank full again" ending plays instead of the whole ending again (about 8 seconds: the stars fly home into the tank, the ship does a happy loop, and Koba thanks the commander for the new skill by name, from the planet's own words), so a child never sits through the same ending twice. One scene serves every future update. Add to AGENTS.md: a new planet needs an arrival scene and a thank-you line naming its skill (both ARB files and a voice clip), like its demo, and the "new planet" scene and ending must keep working. Done: `VariablesArrival` (the Step Box opens and its number flies over Koba, who counts its steps on the tiles), `DebuggingArrival` (muddled blocks line up, the wrong one wears the bump's orange ring and flips to the right one), `UntilArrival` (Koba starts counting the tiles to a far flag, gets dizzy, and the until-the-flag block sends it rolling) and `OtherwiseArrival` (a bush blocks the way ahead, the two-row eye block pops up, and Koba turns down the clear way to a star). The endings (`lib/features/story/view/ending_scenes.dart`) play on the map: `EndingScene` once the last planet is finished (the ship lifts off as the last stars fly in, does a happy loop, and flies among every planet), `NewPlanetScene` for a child who saw an ending when an update adds planets, and `FullAgainScene` with the newest planet's thank-you line once it is finished. Each ending saves `story-full-<last planet>`, so neither plays twice for the same map. Each also plays at `/child/<id>/story/ending-<concept>`, `full-again-<concept>` and `new-planet-<concept>`.

Still to do before the story ships:

- **Telling people:** done in 2.8.0+26 (release notes, both listings and the website); the promos are under the next section. The release that ships the story (a new feature, so a minor version) mentions it in its release notes, the Play and App Store listings and the website, in both languages. Re-recording the promos' gameplay to show it is optional.

### Next: promo videos for 2.8.0 (the Star fuel story)

Done on 2026-10-21: gameplay frames re-recorded, all promos rendered for 2.8.0, a new short told by Koba (`short-koba-<lang>`), captions for Instagram, Facebook, WhatsApp, Threads, LinkedIn and TikTok in each short's `.youtube.txt`, and a "coming soon" card for Koba's short on the landing page. Left:

1. **Upload** (the user, by hand): the videos in `../../assets/ai-generated-content/cobalagi/out/`, replacing the old YouTube promos, and the shorts on every platform with their captions.
2. **Fill in the landing page's ids:** Koba's short's YouTube ids go in `data-video`/`data-en-video` and `href`/`data-en-href` of the `video-short` card in `website/index.html`, which then plays like the main video; replace the main promo's ids too if it was re-uploaded.
3. **Story scenes in the videos** (optional): the frames record only the demos, so the videos show gameplay, not the story scenes. Recording the intro and an arrival needs a new case in `tool/screenshots`' video frames.

### Later

- **Koba celebration clip** (a time-boxed test after the Google Play production launch): an AI clip of Koba celebrating (Seedance on Higgsfield, from Koba's own picture, about 2 seconds; costs credits) turned into a sprite sheet with a transparent background and played with Flame's `SpriteAnimation` on the solved card or when a new planet opens. No video player (it doesn't run on Linux) and no new package. Keep it only if Koba still looks like Koba; AI edits haven't kept it recognisable before (Decisions, 2026-10-08).
- **Progress export and import** (parent area, behind the parent gate; a sponsor feature or for everyone, not decided): "Save progress" writes a file and opens the system share sheet, so the parent chooses where it goes (Google Drive, Files, a chat to themselves); "Load progress" on another device picks that file and merges it. The app stays without internet access and nothing leaves the device unless a parent moves it, so the privacy promises and the Families form stay as they are. Merge: union of lesson, star (best kept) and seen-puzzle data, the attempt logs combined by unique id, and the starting-island choice from the newer file. Real cloud sync (the app sending progress to the parent's Google Drive or a server) would break the "no internet, data stays on the device" promise and need a new Families review, so it is not planned.

## Documentation map

Each topic has one home. Update that file instead of copying its content somewhere else.

| File | Audience | Owns |
| --- | --- | --- |
| `README.md` | Everyone | Overview, setup, commands, layout |
| `AGENTS.md` | AI coding agents (and humans who want the rules) | Conventions, guardrails, definition of done |
| `CLAUDE.md`, `GEMINI.md` | Claude Code, Gemini CLI | Only an import of `AGENTS.md` |
| `LICENSE` | Everyone | Terms for using the code (GPL-3.0) |
| `NOTICE.md` | Everyone | Copyright, and the separate terms for sounds, art and the name |
| `website/` | Visitors of cobalagi.ardeman.com | The landing page, privacy policy and screenshots (also used by this README) |
| `../../assets/ai-generated-content/README.md` (separate repo) | Whoever makes or uploads the promo videos | The promo video scripts, their YouTube text and how to upload them |

Codex, Cursor, GitHub Copilot, Windsurf, Jules, Aider, Zed and other agents that follow the [AGENTS.md](https://agents.md) convention read `AGENTS.md` directly.

## License

The code of Coba Lagi is free software under the [GNU General Public License v3.0 or later](LICENSE): you may use, study, share and change it, and anything you distribute that is built from it must be under the GPL too, with its source. Sounds, art and listing graphics are under CC BY-NC-ND 4.0, and the name and icon are not licensed for other apps; see [NOTICE.md](NOTICE.md). Third-party packages keep their own licenses.
