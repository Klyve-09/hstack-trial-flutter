# Proof

Run these checks in order from the repository root. Every command must exit zero.

| Check | Command | Machine |
| --- | --- | --- |
| test | `flutter test` |  |
| analyze | `flutter analyze` |  |
| format | `dart format --set-exit-if-changed .` |  |
| build-linux | `flutter build linux` |  |
| build-ios | `flutter build ios --no-codesign` | ci |

## Requirements

Use Flutter 3.50 stable with Dart 3.14 or later; the project was created with Flutter 3.50.0 (framework revision `ab2912035e160d9cad6306df307576da6128ebdb` in `.metadata`). Run `flutter pub get` before the checks. `build-linux` needs the Flutter Linux desktop toolchain: Clang, CMake, Ninja, pkg-config, and the GTK 3 development libraries. `build-ios` runs on a GitHub Actions macOS runner with Xcode.

## Coverage

- `analyze`: `analysis_options.yaml`
- `analyze`: `lib/**`
- `analyze`: `pubspec.lock`
- `analyze`: `pubspec.yaml`
- `analyze`: `test/**`
- `build-ios`: `.metadata`
- `build-ios`: `ios/**`
- `build-ios`: `lib/**`
- `build-ios`: `pubspec.lock`
- `build-ios`: `pubspec.yaml`
- `build-linux`: `.metadata`
- `build-linux`: `lib/**`
- `build-linux`: `linux/**`
- `build-linux`: `pubspec.lock`
- `build-linux`: `pubspec.yaml`
- `format`: `analysis_options.yaml`
- `format`: `lib/**`
- `format`: `pubspec.yaml`
- `format`: `test/**`
- `test`: `lib/**`
- `test`: `pubspec.lock`
- `test`: `pubspec.yaml`
- `test`: `test/**`
- Review-only: `.github/**`
- Review-only: `.gitignore`
- Review-only: `AGENTS.md`
- Review-only: `CLAUDE.md`
- Review-only: `LICENSE`
- Review-only: `README.md`
- Review-only: `android/**`
- Review-only: `docs/**`
