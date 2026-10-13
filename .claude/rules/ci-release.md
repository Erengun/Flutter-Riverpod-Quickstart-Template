---
paths:
  - ".github/**"
  - "app/android/fastlane/**"
  - "app/ios/fastlane/**"
  - "Gemfile"
  - "Gemfile.lock"
  - "app/android/app/build.gradle.kts"
---

# CI, release and Dependabot

Five workflows in `.github/workflows/`; none needs a secret until a repo turns on releases or per-PR previews.

`ci.yaml` (every PR to `main` and every push to `main`). All four jobs are meant to be required checks, but the workflow does not enforce that: a repo admin turns it on in branch protection for `main` ("Use this template" does not copy that setting). Shared setup is the composite action `.github/actions/setup` (Flutter stable with caching, `flutter pub get`, Melos at the version in the root `pubspec.lock`); each job checks out first, then uses it.
- `check`: `melos run gen`, then fails if any `*.g.dart` / `*.freezed.dart` file or generated `lib/l10n/*_localizations*.dart` changed or is untracked (so always commit regenerated files), then `melos run analyze` (any lint info fails), then `melos run test` (`--coverage`; the coverage artifact never blocks). No format check.
- `build-android`, `build-ios` (`--no-codesign`), `build-web`: unsigned prod release builds from `app/` with `-t lib/main_prod.dart` (plus `--flavor prod` on Android/iOS). `build-ios` fails if `app/ios/Podfile` appears: every iOS plugin must support Swift Package Manager. `build-ios` (like `release-ios`) installs `flutterfire_cli` only when `app/firebase.json` exists (the Runner build phase calls it after `firebase:configure`).
- Runner labels come from repo variables `LINUX_RUNNER` / `MACOS_RUNNER` / `WINDOWS_RUNNER` (defaults `ubuntu-latest` / `macos-latest` / `windows-latest`). A new push to a PR cancels its older runs.
- `.github/workflows/desktop.yaml` (push to `main`, weekly cron, manual dispatch) builds the build-only platforms after merge: `build-macos` (fails if `app/macos/Podfile` appears), `build-windows` (caches the Firebase C++ SDK zip that firebase_core downloads into `app/build/windows/x64/`, keyed on firebase_core's version in `pubspec.lock`; remove with the Firebase Module), `build-linux`, all prod release with `-t lib/main_prod.dart`. It does not use the setup action (no Melos needed). GitHub disables the schedule after 60 days without repo activity.
- `.github/workflows/release.yaml` (`v*` tags) ships prod: fastlane lanes in `app/android/fastlane/` (obfuscated App Bundle to Play's internal track) and `app/ios/fastlane/` (`match` readonly, TestFlight), a web build with source maps, Sentry symbol/source-map upload through `sentry_dart_plugin` (an `app/` dev dependency) with the release set explicitly to what sentry_flutter reports, and a GitHub Release with the files. Every job runs only when the repo variable `RELEASE_ENABLED` is `'true'`; the template skips. The tag must be `v<name>` of `app/pubspec.yaml`'s version. fastlane is pinned by the root `Gemfile` / `Gemfile.lock`. Secrets and variables are listed in the README's "Releases" section. `app/android/app/build.gradle.kts` signs release builds with the keystore from `ANDROID_KEYSTORE_*` env vars or `app/android/key.properties` (gitignored), else with the debug keys.
- Dependabot (`.github/dependabot.yml`) updates pub (root, `app/`, `packages/*`, `widgetbook/`), GitHub Actions and Bundler weekly. New packages under `packages/` are picked up by the glob.

The Widgetbook publish and per-PR preview workflows are described in `.claude/rules/widgetbook.md`.
