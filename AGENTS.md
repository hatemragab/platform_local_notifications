# Repository Guidelines

## Project Structure & Module Organization

`lib/platform_local_notifications.dart` is the public export barrel. Implementation lives in `lib/src/`: models in `models/`, orchestration in `services/`, shared values in `constants/`, and platform abstractions in `types/`. Root unit tests are in `test/`. The `example/` directory is a runnable consumer: UI code is in `example/lib/`, widget tests in `example/test/`, and platform runners under its Android, iOS, web, Windows, macOS, and Linux folders. Update `README.md`, `MIGRATION_GUIDE.md`, and `CHANGELOG.md` when public behavior changes.

## Build, Test, and Development Commands

- `flutter pub get` resolves package dependencies.
- `dart format lib test example/lib example/test` formats maintained Dart sources.
- `flutter analyze` applies the `flutter_lints` rules from `analysis_options.yaml`.
- `flutter test` runs the package unit suite.
- `cd example && flutter pub get && flutter test` validates the consumer app.
- `cd example && flutter run -d <device>` exercises real notification delivery. Run `flutter build apk --debug` there for an Android compile check.
- `flutter pub publish --dry-run` checks package metadata and contents before any approved release.

## Coding Style & Naming Conventions

Use null-safe Dart with two-space indentation and trailing commas where `dart format` expands argument lists. Name files `snake_case.dart`, types `UpperCamelCase`, members `lowerCamelCase`, and private symbols with a leading underscore. Prefer immutable values, `const` constructors, descriptive booleans such as `isInitialized`, and focused methods. Document public APIs and explain only non-obvious decisions. Export additions deliberately through the public barrel.

## Testing Guidelines

Use `flutter_test`; files must end in `_test.dart`. Group tests by model, service, or platform behavior and use behavior-focused names. Cover validation, action callbacks, permission handling, and platform fallbacks. No coverage threshold is configured, but meaningful behavior changes need focused regression tests. Verify OS behavior on affected platforms because unit tests cannot prove permission prompts or native delivery.

## Commit & Pull Request Guidelines

History mixes imperative subjects with prefixes such as `feat:` and `Refactor:`. Prefer concise subjects using `feat:`, `fix:`, `refactor:`, `docs:`, or `test:`; reserve `🚀 Release vX.Y.Z: ...` for releases. Pull requests should explain the change and platform impact, link issues, list validation commands, and include screenshots or recordings for example UI changes. Update user-facing docs and the changelog when applicable. Never commit credentials, signing material, build output, IDE metadata, or hand-edited generated registrants.
