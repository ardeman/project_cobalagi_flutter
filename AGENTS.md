# AGENTS.md

Instructions for AI coding agents working in this repo. Read `README.md` for the overview, setup, commands and layout. This file does not repeat them.

## Definition of done

A change is done only when the **Checks** command in `README.md` passes. If you can't run it, say so; don't claim it passed. Add or update tests in `test/` for any behavior you change.

## Conventions

- Use Conventional Commit subjects; see `README.md` for the format and hook setup.
- Follow [Effective Dart](https://dart.dev/effective-dart) and the lints in `analysis_options.yaml`. Fix lint findings; don't silence them with `// ignore:` unless you add a comment saying why.
- Files use `snake_case.dart` and types use `UpperCamelCase`. Use one public widget per file once `lib/` grows past `main.dart`.
- Use `const` constructors wherever you can. Prefer `StatelessWidget` and keep state as local as possible.
- Import project code with `package:cobalagi/...` imports, not relative paths that climb out of `lib/`.
- State lives in Cubits (`flutter_bloc`). Services reach widgets through `RepositoryProvider`/`BlocProvider`, built in `lib/app/app.dart`; there is no service locator.
- A feature folder is split into `data/` (models, repositories), `cubit/` (state) and `view/` (widgets).
- `lib/engine/` and `lib/learning/` are pure Dart: no Flutter imports, so they can be tested headless.
- Every editor (blocks, later typed code) compiles to the shared `Program` in `lib/engine/`. Never add an editor-specific path into the world or interpreter.
- An editor lives in `lib/features/editors/<name>/`: its own block model, a compile function to `Program` that copies block ids, and its own cubit. `PlayCubit` only receives the compiled `Program`. The block editor (`lib/features/editors/blocks/`) shows picture blocks only; readers use typed code (`lib/features/editors/typed/`) instead of word blocks.
- The Flame world (`lib/features/play/view/world/`) holds no game logic. It mirrors `PlayState` through `WorldGame.apply` and reports each finished animation with `PlayCubit.eventShown`.
- Every island has a "Watch me!" demo in `assets/config/tutorials.json` and a narration clip `tutorial_<concept>`; a new island needs both. Demos play in the real editor and world but are watch-only.
- Every hand-made level must be solvable with its own palette; `test/features/play/level_assets_test.dart` checks this.
- User-facing text goes in both `lib/app/l10n/app_en.arb` and `app_id.arb`; never hardcode strings. Voice clips live at `assets/audio/<id|en>/<clipId>.mp3`; sound effects at `assets/audio/sfx/<name>.mp3`, one per `SoundEffect`, each with a prompt in `tool/sound_effects.json`; music at `assets/audio/music/<name>.mp3`, one per `MusicTrack`, prompted in `tool/music.json`.
- Learning thresholds and skill prerequisites belong in `assets/config/`, not in code. `AdaptiveConfig` has no defaults on purpose.
- A concept id must match a lesson pack (`assets/levels/<id>.json`) and a `PuzzleKind` name, so practice puzzles can be generated for it.
- Never serve the same puzzle twice: generated puzzles go through `LearningCubit.nextExercise`, which skips fingerprints in `LearnerState.seenPuzzles`.
- Replays (lessons replayed from an island, `ExerciseMode.replay`) never change mastery, difficulty or the current concept; they only earn a lesson's star. Record them with `LearningCubit.recordReplay`, not `record`.
- Present a review as a reward ("bonus adventure"), never as a failure, in text, icons and voice.
- Feedback to children comes from `CheerPicker` (`lib/core/feedback/cheers.dart`): varied, never the same words twice in a row, and never "wrong". Add phrases there (both ARB files), not one-off strings.
- The warm-up game (`lib/learning/placement/`) must work without reading: every prompt has a voice clip id and pictures for answers. Placement thresholds and the number of second chances per skill (`secondChances`: extra questions at the same level after a wrong answer) live in `assets/config/pretest.json`. After a wrong answer it shows the right one (green ✓ with "The answer is this one!" under it, orange wobble on the tapped card) with encouraging words, never "wrong".
- Layouts adapt via `WindowClass`/`WindowClassBuilder` (`lib/core/responsive/`), not fixed device sizes. Tap targets are at least 64dp.
- Pop-ups go through `showGlassDialog`/`showGlassSheet` (`lib/core/widgets/glass_popups.dart`), never `showDialog`/`showModalBottomSheet` directly. Screens with an app bar use `GlassAppBar` with `Scaffold(extendBodyBehindAppBar: true)` and pad their scroll view with `belowBars`; custom bars over a scrolling page use `GlassFrame`. Bars turn to glass only while content is under them.
- Drag-and-drop must work with touch and mouse (`Draggable`/`DragTarget`), with tap-to-add as an alternative. Tapping a placed block picks it: the next palette tap replaces it in place, and the delete button removes just that block, so a block can be fixed without dragging. Where blocks sit in a row that scrolls (placed blocks everywhere, the palette too on phones), a finger lifts a block only after a short hold (`_dragSource`), so swiping across wide blocks scrolls instead; a mouse still drags at once.

## Guardrails

- **Dependencies:** before adding a package, confirm on pub.dev that it supports Android, iOS and web. Add it with `flutter pub add <pkg>` (not by hand-editing versions), commit `pubspec.lock` (this is an app), and record the choice under "Decisions".
- **Children's app (Google Play Families):** no ads, analytics, tracking or crash-reporting SDKs and no network calls. Data stays on the device, and a profile holds only a nickname and avatar. Settings, purchases and external links sit behind the parent gate (`showParentGate`). Never show purchase prompts to children.
- **Builds:** build and run only for Android or macOS desktop. Don't trigger iOS builds. Keep code compatible with iOS, web and desktop anyway. macOS builds are Apple Silicon only for now (see README → macOS).
- **Installable APKs:** split release APKs by Android architecture using the command in README → Commands. Use an App Bundle for Google Play uploads.
- **App updates:** check only through Google Play on Android, without adding internet permission. Update notices are optional; starting an update requires `showParentGate`. Other platforms skip checks, and store errors or a slow check must never prevent play.
- **Platform folders** (`android/`, `ios/`, etc.) are mostly generated. Edit them only for platform config such as permissions, the app ID or signing. Never edit `ios/Flutter/Generated.xcconfig`, `**/GeneratedPluginRegistrant.*` or anything under `build/` or `.dart_tool/`.
- **Secrets:** never commit keystores, `key.properties`, `google-services.json`/`GoogleService-Info.plist` with real keys, `.env` files or API tokens.
- **App identity:** don't change the package name `cobalagi` or the ID `com.ardeman.cobalagi` without being asked.
- **Version:** bump `version:` in `pubspec.yaml` only when asked. It is `NAME+BUILD`:
  - The name follows semantic versioning for people: PATCH (1.1.0 → 1.1.1) for fixes only, MINOR (1.1.x → 1.2.0) for new features such as an island or a tool, MAJOR for big changes such as a redesign or a new age group.
  - The build (Android versionCode) is one counter that only goes up, by one per upload, and never resets: Google Play rejects a build number it has seen before.
  - Repeated test uploads of the same release keep the name and only raise the build, e.g. 1.1.0+8, 1.1.0+9.

## App icon

- App icons are generated from `branding/` by `branding/render.sh`. Never hand-edit the generated icons under `android/`, `ios/`, `web/`, `macos/` or `windows/`; change the SVG and re-run the script.
- Keep the foreground art inside the central 66% of `icon.svg` (Android's adaptive-icon safe zone).

## Store listing

- `store/<locale>/` text must stay within Play's limits (title 30, short 80, full 4,000, release notes 500 characters; `test/store/store_text_test.dart` checks them), true for the released app, and free of ranking or promotional words, calls to action and emoji. The title and short description also may not mention price or ads ("free", "gratis", "no ads"); say that in the full description only. Keep `id` and `en-US` saying the same thing.
- Google Play takes at most 8 screenshots per device type. `store/render.sh` keeps each set at 8; to show more, put related screens on one slide (`pair_slide`, `phone_pair_slide`) instead of dropping one.
- Every build gets release notes in `store/<locale>/changelogs/<versionCode>.txt` (fastlane's layout) and an entry in `store/releases.json` (version and date), written when the version is bumped. Then run `dart run tool/website_changelog.dart`: `website/changelog.html` is generated from them and must never be edited by hand (`test/store/website_changelog_test.dart` fails while it is stale).
- Write changelogs in simple, everyday language for parents: say what changed and how it affects using the app. Avoid technical jargon and implementation details. Keep both languages equivalent.

## Website

- `website/` is the static site for cobalagi.ardeman.com: `index.html` (landing page), `privacy.html` (privacy policy, linked from the Play listing), `changelog.html` (release notes, generated), shared `site.css` and `site.js`, and `screenshots/`. It makes no external requests (no web fonts, analytics or CDNs), to match the app's privacy promise.
- Every page shares one header (menu, GitHub icon, language button, ☰ on phones) and one footer, copied from `privacy.html`; the home page differs only in linking to its own sections. `tool/website_changelog.dart` copies them into the changelog, and `test/store/website_changelog_test.dart` fails if any page drifts.
- Every text has Indonesian in the HTML and English in `data-en` (`data-en-alt`, `data-en-src` for images). Screenshots come in pairs: `<name>-id.png` and `<name>.png`.
- Pushing a change under `website/` to `master` publishes it live (`.github/workflows/pages.yml`).
- Claims on the pages must stay true for the released app. When the app starts storing or sending different data, update `privacy.html` and its date in the same change.

## Keeping docs current

- When you change a command, the layout or the setup, update `README.md`. When you change a convention or rule, update this file.
- Never copy content between docs. Link to the owning file instead (see the documentation map in `README.md`).
- `CLAUDE.md` and `GEMINI.md` must contain only the import of this file.

## Decisions

Record architectural choices here as one line each: date, decision, reason.

- 2026-10-05: `flutter_bloc` for state (`flame_bloc` not needed so far: the world mirrors `PlayState` via `WorldGame.apply`). `flutter_riverpod` 3.4.3 fails pub.dev's web check (imports `flutter_test` → `dart:io`).
- 2026-10-05: `go_router` for routing; `sembast` (+ `sembast_web` on IndexedDB) for local storage behind repositories.
- 2026-10-05: `path_provider` is allowed without web support: it is imported only on native via `lib/core/storage/database_factory_io.dart`.
- 2026-10-05: Flame for the game world, Rive (`flame_rive`) for characters later; placeholder shapes until then. Flame is added in Phase 2.
- 2026-10-05: The app is free. A donation of any amount unlocks the sponsor features (`Plan.full`; free: 1 profile, full: `Plan.full.maxProfiles`). Google Play Billing only sells fixed prices, so "any amount" means several one-time donation products at different prices, any of which unlocks `Plan.full`. Checks go through `EntitlementService`/`EntitlementCubit` only. Billing (`in_app_purchase`, no web support) arrives in Phase 5; platforms without store billing stay free.
- 2026-10-05: Released on Google Play only for now. The release manifest removes the INTERNET permission; don't add networking without revisiting this.
- 2026-10-05: Donations are one-time Play products listed in `assets/config/donations.json`; `DonationEntitlementService` unlocks `Plan.full` for any of them and caches it locally. No server verification. The store sits behind `PurchaseStore` so it can be faked in tests.
- 2026-10-05: Voice-over uses prerecorded clips, not TTS. Missing clips are skipped silently. Every clip id lives in `VoiceClips` (`lib/core/audio/voice_clips.dart`) with the ARB key of its words; never pass a literal clip id to `playVoice`. Real clips come from `tool/generate_voice.dart` (ElevenLabs); its API key comes from the git-ignored `.env` (template: `.env.example`) or the `ELEVENLABS_API_KEY` environment variable, and must never be committed. Clips from `tool/test_voices.dart` (macOS voices) are for testing only: never commit them or remove the release-build guard in `android/app/build.gradle.kts`.
- 2026-10-05: The pretest sets each child's starting point. Directions levels exist and serve as the review target for Sequencing; children who pass the pretest's left/right check skip them.
- 2026-10-05: Unlock codes (Parent area → Support Coba Lagi → "Have a code?") unlock `Plan.full` like a donation, so Google Play reviewers can reach the sponsor features. Only SHA-256 hashes go in `assets/config/donations.json` (`unlock_code_sha256`), because the repo is public; never commit a code itself. Uses `crypto` (dart.dev; Android, iOS, web). Codes work on every platform; desktop and web use `NoPurchaseStore`.
- 2026-10-06: `package_info_plus` (Flutter Favorite; Android, iOS, web, desktop) shows the installed version and build at the bottom of the Parent area, so testers can say which build they use.
- 2026-10-06: The parent progress report (Parent area → tap a player) is a sponsor feature; the free plan sees the starting island and a locked card. `ProgressReport` (`lib/learning/progress_report.dart`) owns the island star rule, shared with the adventure map.
- 2026-10-06: Sound effects (`SoundEffect`, `AudioService.playEffect`) are made with ElevenLabs' sound-effects model and can be turned off in the Parent area; voices always play. The Flame world plays them through its `onSound` callback when it shows an event, so it still holds no game logic.
- 2026-10-06: `flame_test` is a dev dependency only (tests the world without a widget tree). pub.dev lists no web support, which doesn't matter because it never ships.
- 2026-10-06: Background music (ElevenLabs Music, instrumental) loops quietly while the app is in the foreground, drops under voices, and mixes in without taking audio focus. Parents can turn it off; it is on by default.
- 2026-10-06: `in_app_update` 4.2.5 uses Google Play's update service without app internet access. The user approved an Android-only dependency exception; conditional factories disable it on iOS, web and desktop. Version 5 requires a newer Dart SDK than this app currently uses.
- 2026-10-06: Conditions use `IfPathClear` in the shared engine. Each check inspects the cell ahead once and counts toward the execution limit; the world displays `PathChecked` events. The block editor allows a condition inside a repeat, with tap-to-fill as well as dragging.
- 2026-10-06: Liquid-glass styling uses Flutter's clipped `BackdropFilter` in shared `GlassSurface` panels, with an opaque high-contrast fallback. Buttons and blocks use painted highlights rather than individual blurs to keep game screens inexpensive to render.
- 2026-10-06: Typed code uses a bounded teaching-language parser (8,000 characters, 16 nested containers) that compiles to the shared `Program` with source-offset IDs. Actions move one step so code preserves block-editor lesson limits; the first code draft copies the blocks, then both drafts stay separate for the puzzle.

- 2026-10-06: Variables start with one Step Box storing an integer from 1 to 9. Shared `SetSteps` and `MoveSteps` instructions reset the value each run, validate saving before use and emit `StepsStored` for playback; blocks and code share the same semantics.
- 2026-10-06: Liquid-glass bars and pop-ups: content scrolls under app bars and phone bottom bars, which blur only while something is beneath (`GlassBar`); dialogs blur the screen behind a translucent panel, sheets are clipped glass. High contrast stays opaque. `GlassFrame` reports its bars as `MediaQuery` padding so revealed content (new blocks) stops clear of them.
- 2026-10-06: Word blocks (Tier 2) are dropped: blocks are always pictures, and readers switch to typed code. `Placement.readsWords` (the warm-up's reading result, or a parent's Code tab switch in the progress screen) decides whether a child sees the Code tab; pre-readers see picture blocks only.
- 2026-10-07: Versions use semantic version names and one ever-increasing build number. Builds 1–7 bumped only the patch even for new features; from 1.1.0 on, features raise the minor version.
- 2026-10-07: Fix it! (debugging) is island 7, after the Step Box, so testers' saved progress is untouched; its prerequisites are [loops, variables], so a struggling child reviews Loops. Levels can carry a starter program (`Level.starter`), which the block editor opens with and undo never removes; every debugging lesson must fail as given and be fixable with one change.
- 2026-10-07: Until the flag (while loops) is island 8, after Fix it!. `RepeatUntilGoal` has no condition of its own: the interpreter already ends a run on the flag, so the loop runs until the run ends, and each round counts toward the step limit. Prerequisites [loops, debugging], so a struggling child reviews Loops.
- 2026-10-07: Island tutorials are live demos played by the app, not video files: no video dependency or download size, offline, both languages, and they always match the current screens. Island stars are the better of lesson completion and recent scores, so an island with every lesson solved always shows three stars.
- 2026-10-07: A child who has solved every lesson on an island moves on after a solved puzzle once recent mastery reaches `practiceAt`, or after `practiceLimit` puzzles on the island in all (both in `assets/config/adaptive.json`). Before, only mastery at `advanceAt` advanced, so hints and extra tries could keep a child on one island for ever (Directions has no review to send them to).
- 2026-10-07: The break reminder counts only puzzle time on this device for the app session (`PlayClock`), never data off the device; it never interrupts a puzzle, and continuing needs the parent gate. The second hint press shows the repeating pattern with a spoken line, and the hint bulb pulses after two runs without a hint.
