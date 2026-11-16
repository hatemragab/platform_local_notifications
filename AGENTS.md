# Repository Guidelines

## Project Structure & Module Organization

`lib/platform_local_notifications.dart` is the public export barrel. Implementation lives in `lib/src/`: models in `models/`, orchestration in `services/`, shared values in `constants/`, and platform abstractions in `types/`. Root unit tests are in `test/`. The `example/` directory is a runnable consumer: UI code is in `example/lib/`, widget tests in `example/test/`, and platform runners under its Android, iOS, web, Windows, macOS, and Linux folders. Update `README.md`, `MIGRATION_GUIDE.md`, and `CHANGELOG.md` when public behavior changes.

## Flutter 3.50 verification workflow

Use the installed project-compatible Flutter 3.50/Dart 3.14 SDK. Keep direct `material_ui`/`cupertino_ui` dependencies consistent with their imports; design widgets no longer come from `flutter/material.dart` or `flutter/cupertino.dart`. Prefer neutral Flutter libraries when design widgets are unnecessary. Preserve this project's architecture and public contracts.

Resolve dependencies from each affected package root with `flutter pub get --no-example`. For a design migration, run `dart fix --apply --code=migrate_design_widgets` and review its output. After every code edit, run these commands sequentially from the affected package root:

```sh
dart fix --apply
dart format .
flutter analyze
```

Fix and format must finish before analysis or tests. Analyzer-only verification is the default. Run a focused test or build when requested or needed to prove a specific behavior change; choose the smallest useful check. Passing analysis does not prove runtime, provider, native linking, or integration behavior. Never suppress maintained-source diagnostics to obtain a pass. Preserve tool-owned generated files.

Existing web runners: `example`. When a run is requested, use the existing web development workflow with one explicitly selected target and port, then inspect it with Playwright MCP. An explicitly requested `flutter build web` is a compile check, separate from the development run. Do not add web targets merely to validate a migration.

Use a reachable physical Android device only when web is unsupported and device execution is requested. No emulator or simulator is authorized. This Linux VPS cannot execute native iOS/macOS builds or assume access to a phone attached to the Mac. Observe the global 500 MB download rule and preserve existing edits, credentials, caches, and running sessions. Do not push, publish, deploy, or run native builds without task authorization.

Use one handwritten class/widget per file; a StatefulWidget and its paired State may share a file. Apply SOLID without speculative abstractions. Keep UI, coordination, domain behavior, transport, persistence, and provider mechanics in their existing layers; use explicit types and correct async ownership/disposal. Do not impose another project’s state management or architecture.


## Coding Style & Naming Conventions

Use null-safe Dart with two-space indentation and trailing commas where `dart format` expands argument lists. Name files `snake_case.dart`, types `UpperCamelCase`, members `lowerCamelCase`, and private symbols with a leading underscore. Prefer immutable values, `const` constructors, descriptive booleans such as `isInitialized`, and focused methods. Document public APIs and explain only non-obvious decisions. Export additions deliberately through the public barrel.

## Testing Guidelines

Use `flutter_test`; files must end in `_test.dart`. Group tests by model, service, or platform behavior and use behavior-focused names. Cover validation, action callbacks, permission handling, and platform fallbacks. No coverage threshold is configured, but meaningful behavior changes need focused regression tests. Verify OS behavior on affected platforms because unit tests cannot prove permission prompts or native delivery.

## Commit & Pull Request Guidelines

History mixes imperative subjects with prefixes such as `feat:` and `Refactor:`. Prefer concise subjects using `feat:`, `fix:`, `refactor:`, `docs:`, or `test:`; reserve `🚀 Release vX.Y.Z: ...` for releases. Pull requests should explain the change and platform impact, link issues, list validation commands, and include screenshots or recordings for example UI changes. Update user-facing docs and the changelog when applicable. Never commit credentials, signing material, build output, IDE metadata, or hand-edited generated registrants.

## Local package migration dependencies

The development overrides in `pubspec_overrides.yaml`, `example/pubspec_overrides.yaml` point to migrated sibling packages in the organized workspace. Keep the relative layout when developing this migration. Hosted releases may still expose legacy Material theme types. Before distributing a checkout independently, release compatible dependency versions and update its hosted constraints; do not publish local paths or force incompatible overrides.
