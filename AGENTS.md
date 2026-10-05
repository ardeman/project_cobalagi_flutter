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
- Don't add a state-management, routing or DI package unless the task asks for one. That is an architectural decision, so record it in the "Decisions" section below.

## Guardrails

- **Dependencies:** add packages with `flutter pub add <pkg>` (not by hand-editing versions). Commit `pubspec.lock`, because this is an app.
- **Platform folders** (`android/`, `ios/`, etc.) are mostly generated. Edit them only for platform config such as permissions, the app ID or signing. Never edit `ios/Flutter/Generated.xcconfig`, `**/GeneratedPluginRegistrant.*` or anything under `build/` or `.dart_tool/`.
- **Secrets:** never commit keystores, `key.properties`, `google-services.json`/`GoogleService-Info.plist` with real keys, `.env` files or API tokens.
- **App identity:** don't change the package name `cobalagi` or the ID `com.ardeman.cobalagi` without being asked.
- **Version:** bump `version:` in `pubspec.yaml` only when asked.

## Keeping docs current

- When you change a command, the layout or the setup, update `README.md`. When you change a convention or rule, update this file.
- Never copy content between docs. Link to the owning file instead (see the documentation map in `README.md`).
- `CLAUDE.md` and `GEMINI.md` must contain only the import of this file.

## Decisions

Record architectural choices here as one line each: date, decision, reason.

- _None yet._
