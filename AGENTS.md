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
- An editor lives in `lib/features/editors/<name>/`: its own block model, a compile function to `Program` that copies block ids, and its own cubit. `PlayCubit` only receives the compiled `Program`. The block editor (`lib/features/editors/blocks/`) serves Tier 1 (picture blocks) and Tier 2 (word blocks) as two looks of the same blocks.
- The Flame world (`lib/features/play/view/world/`) holds no game logic. It mirrors `PlayState` through `WorldGame.apply` and reports each finished animation with `PlayCubit.eventShown`.
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
- Drag-and-drop must work with touch and mouse (`Draggable`/`DragTarget`), with tap-to-add as an alternative.

## Guardrails

- **Dependencies:** before adding a package, confirm on pub.dev that it supports Android, iOS and web. Add it with `flutter pub add <pkg>` (not by hand-editing versions), commit `pubspec.lock` (this is an app), and record the choice under "Decisions".
- **Children's app (Google Play Families):** no ads, analytics, tracking or crash-reporting SDKs and no network calls. Data stays on the device, and a profile holds only a nickname and avatar. Settings, purchases and external links sit behind the parent gate (`showParentGate`). Never show purchase prompts to children.
- **Builds:** build and run only for Android or macOS desktop. Don't trigger iOS builds. Keep code compatible with iOS, web and desktop anyway. macOS builds are Apple Silicon only for now (see README → macOS).
- **Installable APKs:** split release APKs by Android architecture using the command in README → Commands. Use an App Bundle for Google Play uploads.
- **App updates:** check only through Google Play on Android, without adding internet permission. Update notices are optional; starting an update requires `showParentGate`. Other platforms skip checks, and store errors or a slow check must never prevent play.
- **Platform folders** (`android/`, `ios/`, etc.) are mostly generated. Edit them only for platform config such as permissions, the app ID or signing. Never edit `ios/Flutter/Generated.xcconfig`, `**/GeneratedPluginRegistrant.*` or anything under `build/` or `.dart_tool/`.
- **Secrets:** never commit keystores, `key.properties`, `google-services.json`/`GoogleService-Info.plist` with real keys, `.env` files or API tokens.
- **App identity:** don't change the package name `cobalagi` or the ID `com.ardeman.cobalagi` without being asked.
- **Version:** bump `version:` in `pubspec.yaml` only when asked.

## App icon

- App icons are generated from `branding/` by `branding/render.sh`. Never hand-edit the generated icons under `android/`, `ios/`, `web/`, `macos/` or `windows/`; change the SVG and re-run the script.
- Keep the foreground art inside the central 66% of `icon.svg` (Android's adaptive-icon safe zone).

## Store listing

- `store/<locale>/` text must stay within Play's limits (title 30, short 80, full 4,000, release notes 500 characters; `test/store/store_text_test.dart` checks them), true for the released app, and free of ranking or promotional words, calls to action and emoji. The title and short description also may not mention price or ads ("free", "gratis", "no ads"); say that in the full description only. Keep `id` and `en-US` saying the same thing.
- Every build gets release notes in `store/<locale>/changelogs/<versionCode>.txt` (fastlane's layout), written when the version is bumped.
- Write changelogs in simple, everyday language for parents: say what changed and how it affects using the app. Avoid technical jargon and implementation details. Keep both languages equivalent.

## Website

- `website/` is the static site for cobalagi.ardeman.com: `index.html` (landing page), `privacy.html` (privacy policy, linked from the Play listing), shared `site.css` and `site.js`, and `screenshots/`. It makes no external requests (no web fonts, analytics or CDNs), to match the app's privacy promise.
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
