# Coba Lagi

A coding-learning app for children of all ages, in Bahasa Indonesia and English.

- **Tier 1** (pre-readers, about 4–7): icon blocks and voice instructions.
- **Tier 2** (early readers, about 7–10, planned): word blocks such as `move 3`.
- **Tier 3** (about 10–14+, planned): blocks that flip to real code, then typed code.

Every tier drives the same game world. A short, voice-led placement game picks each child's starting point, and the app then chooses to advance, practise or review after every lesson.

Primary target: Android tablets in landscape. The code stays compatible with iOS, web and desktop, but only Google Play releases are planned for now.

> **Status:** the MVP code is complete (phases 0–5, see the roadmap). Voice-over is recorded (ElevenLabs, Indonesian and English) and the app icon is done. The store listing is drafted in `store/`. Still needed before launch: character artwork and Play Console setup.

Website: [cobalagi.ardeman.com](https://cobalagi.ardeman.com) (source in `website/`).

## Screenshots

| | |
| --- | --- |
| ![Adventure map with five islands and mastery stars](website/screenshots/adventure-map.png) | ![A Loops puzzle: a repeat block holding a forward block, with hint footprints on the path](website/screenshots/play-loops.png) |
| **Adventure map:** one island per concept, with stars for mastery. | **Loops puzzle:** a repeat block, the block limit, and a hint showing the route. |
| ![A solved puzzle with a cheer and a Next button](website/screenshots/solved.png) | ![Warm-up game asking what comes next in a pattern of shapes](website/screenshots/warm-up-pattern.png) |
| **Solved:** varied cheers, then the next puzzle chosen by the learning rules. | **Warm-up game:** picture-based, voice-led placement for children who can't read yet. |
| ![Parent area dialog for choosing a child's starting island](website/screenshots/parent-placement.png) | ![The adventure map in Bahasa Indonesia](website/screenshots/adventure-map-id.png) |
| **Parent area:** behind a grown-up check; set the starting island or replay the warm-up. | **Bahasa Indonesia:** every screen in Indonesian and English. |
| ![A Magic Block puzzle: the star row holds a stair step, called four times](website/screenshots/play-functions.png) | ![A child's progress report with puzzles, play time and islands](website/screenshots/parent-progress.png) |
| **Magic Block:** build your own block once, then use it again and again. | **Progress report** (sponsor feature): puzzles, play time and every island. |
| ![Look Ahead: an eye block inside a repeat checks before moving](website/screenshots/play-conditions.png) | ![Look Ahead on a phone](website/screenshots/phone-play-conditions.png) |
| **Look Ahead:** check the path before taking a step. | **Phone editor:** nested conditions and repeats also work in portrait. |

| | |
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
                   learning, pretest, parent)
test/              Mirrors lib/
integration_test/  Tests that drive the real app on a device (e.g. warm-up voice timing)
.githooks/         Versioned Git hooks for commit-message validation
tool/              Developer scripts (voice clips, screenshot renders)
branding/          App icon source (SVG), rendered PNGs and branding/render.sh
store/             Google Play listing text and graphics per language (id, en-US)
website/           Static landing page for cobalagi.ardeman.com, plus screenshots
assets/config/     skills.json (skill map), adaptive.json (learning thresholds),
                   pretest.json (placement rules and warm-up vocabulary)
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
# put the chosen voice_id for "id" and "en" in tool/elevenlabs.json
dart run tool/generate_voice.dart --sample    # 5 sample lines per language in build/voice_samples/
dart run tool/generate_voice.dart             # all clips (replaces test voices)
dart run tool/generate_voice.dart --only cheer_celebrate_1   # redo one clip
```

Model, voices and settings (`speed`, `stability`, `style`…) live in `tool/elevenlabs.json`. When the test voices are replaced, the tool removes `assets/audio/TEST_VOICES`. The shipped clips use Cahaya (Indonesian) and Jessica (English) and are committed in `assets/audio/`.

**Sound effects:** `tool/generate_sfx.dart` makes the game sounds (`SoundEffect`: step, turn, bump, star, goal, drop) with ElevenLabs' sound-effects model, from the prompts in `tool/sound_effects.json`, into `assets/audio/sfx/`. The API key needs the *Sound Effects* permission.

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

3. Increase the build number (after `+` in `version:` in `pubspec.yaml`) for
   every new Google Play upload, even if the visible app version stays the same.
   Previously uploaded version codes cannot be reused; see
   [Android versioning](https://developer.android.com/studio/publish/versioning).
   Write release notes for the new build, then build the bundle to upload:

   ```sh
   flutter build appbundle --release
   ```

**Play Console:**

- **Donations:** create one-time in-app products whose ids match `assets/config/donations.json` (`supporter_small`, `supporter_medium`, `supporter_large`), with prices of your choice. Any of them unlocks the sponsor plan. Test with license testers.
- **Families policy:** target audience is children, with no ads and no data collection. The release build has no internet permission. Privacy policy URL: `https://cobalagi.ardeman.com/privacy.html`.

## macOS

```sh
flutter build macos --release   # → build/macos/Build/Products/Release/Coba Lagi.app
```

- Needs macOS 12 or later, Xcode and CocoaPods. The window opens at 1280 × 800 and can't shrink below 960 × 600.
- **Apple Silicon only (`ARCHS = arm64`).** Xcode 27's `lipo -verify_arch` accepts one architecture per call, which breaks Flutter 3.41's universal-build check. Remove `ARCHS = arm64` from `macos/Runner.xcodeproj` once Flutter handles it, to bring back Intel Macs.
- **Not distributed for now:** developers build and run it themselves (`open "build/macos/Build/Products/Release/Coba Lagi.app"`). The build is ad-hoc signed, so it runs only on the Mac that built it. Distributing it later needs an Apple Developer account (Developer ID signing and notarization, or the Mac App Store).
- Donations are off on macOS (free plan only); the store is wired up for Android and iOS.

## Website

`website/` is published to [cobalagi.ardeman.com](https://cobalagi.ardeman.com) by GitHub Pages. `.github/workflows/pages.yml` deploys it on every push to `master` that changes `website/`, and can also be run by hand from the Actions tab. Preview locally with `open website/index.html`; add `?lang=en` or `?lang=id` to pick a language.

One-time setup (already done for this repo): Pages source **GitHub Actions**, custom domain `cobalagi.ardeman.com` (also in `website/CNAME`), and a DNS `CNAME` record `cobalagi` → `ardeman.github.io`.

## App icon

The icon (coral character on teal) is drawn in `branding/icon.svg`, with a one-colour version for Android 13 themed icons in `branding/icon_monochrome.svg`. After editing either, run `branding/render.sh`: it renders the PNGs with headless Chrome and generates every platform's icons with `flutter_launcher_icons` (config: `flutter_launcher_icons.yaml`). `branding/play_store_icon.png` is the 512 × 512 icon for the Play Console.

## Store listing

`store/<locale>/` holds the Google Play listing for Indonesian (`id`) and English (`en-US`): `title.txt` (max 30 characters), `short_description.txt` (max 80), `full_description.txt` (max 4,000) and `changelogs/<versionCode>.txt` with each build's release notes (max 500), plus `feature_graphic.png` (1024 × 500), `screenshots/` (1920 × 1080, 16:9) for the 7-inch and 10-inch tablet sections and `phone_screenshots/` (1080 × 1920, 9:16) for the phone section. The app icon for the listing is `branding/play_store_icon.png`.

`flutter test tool/screenshots --update-goldens && tool/screenshots/export.sh` renders every screenshot from the real app with sample data into `website/screenshots/`, in Indonesian and English. Tablet and phone store sets each contain eight matching features: the map, Loops, Magic Block, Look Ahead, a solved puzzle, the warm-up game, parent controls and the progress report. `store/render.sh` then re-renders the graphics from `website/screenshots/` and the icon art. Play doesn't allow ranking or promotional words ("best", "#1", "new", "sale"), calls to action or emoji in the listing.

## Roadmap (MVP)

| Phase | Scope |
| --- | --- |
| 0. Foundation ✅ | Packages, theme, Indonesian/English, routing, local storage, responsive layout, audio, profiles, parent gate, free/full plan check |
| 1. Engine ✅ | Instruction set, world, interpreter, level JSON, solver (unit-tested, no UI) |
| 2. Play + Tier 1 ✅ | Flame world with placeholder shapes, icon-block editor, run/step/reset, Directions and Sequencing levels |
| 3. Learning loop ✅ | Attempt tracking, mastery, advance/practice/review, generated variations, Loops levels, adventure map |
| 4. Pretest ✅ | Reading check and pre-skills, voice-led and adaptive; placement; parent override |
| 5. Hardening ✅ (code) | Donations through Google Play Billing (any donation unlocks sponsor features), release config, voice clips, tablet performance |

| 6. After MVP ✅ | Magic Block island (own block), parent progress report, sound effects and music, splash, how-to hint, warm-up second chance, Tier 2 word blocks for readers |
| 7. Conditions ✅ | Look Ahead island, six lessons, generated practice and an eye block that runs its contents only when the cell ahead is clear |

The eye block checks once before running its contents. Put a forward block
inside it to move safely; put the eye block inside a repeat to check again
on every turn of the loop. Tap a repeat or eye block, then a palette block
to fill it, or drag blocks into it. Checks appear as green (clear) or orange
(blocked) rings in the world. The Conditions island follows Magic Block.

Later: Rive characters, Tier 3 (typed code), variables.

## Documentation map

Each topic has one home. Update that file instead of copying its content somewhere else.

| File | Audience | Owns |
| --- | --- | --- |
| `README.md` | Everyone | Overview, setup, commands, layout |
| `AGENTS.md` | AI coding agents (and humans who want the rules) | Conventions, guardrails, definition of done |
| `CLAUDE.md`, `GEMINI.md` | Claude Code, Gemini CLI | Only an import of `AGENTS.md` |
| `LICENSE.md` | Everyone | Terms for using the code (PolyForm Noncommercial 1.0.0) |
| `website/` | Visitors of cobalagi.ardeman.com | The landing page, privacy policy and screenshots (also used by this README) |

Codex, Cursor, GitHub Copilot, Windsurf, Jules, Aider, Zed and other agents that follow the [AGENTS.md](https://agents.md) convention read `AGENTS.md` directly.

## License

Coba Lagi is source-available under the [PolyForm Noncommercial License 1.0.0](LICENSE.md): you may read, learn from and modify it for noncommercial purposes. Commercial use needs permission from Ardeman. Third-party packages keep their own licenses.
