[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)
# Flutter Riverpod Quickstart Template

## Modern Flutter Architecture Template with Riverpod

A production-ready Flutter template built with the latest packages and best practices, supporting Flutter 3.47.4 and above. It provides a robust foundation for building scalable applications.

---

### Key Features

- 🎯 Riverpod 3 with code generation
- 🔒 Built-in authentication pack with secure storage (Hive CE + AES-256), token refresh and backend-driven permissions
- 🌐 Type-safe API integration with retrofit clients on one shared Dio
- 🌍 Internationalization with Flutter's gen-l10n (ARB files, English and Turkish)
- 💾 Secure local storage with Hive CE
- 🧩 Optional Modules: Firebase (Analytics, Remote Config) and Sentry, each removable in a few lines
- 🧪 Pre-configured unit and widget tests, plus a Widgetbook catalog
- ⚡ Modern navigation with GoRouter 18
- 🚀 CI on every PR, and a tag-driven release workflow with fastlane
- 🛠️ Custom linting and devtools configuration
- 🤖 Claude Code rules: a short root `CLAUDE.md`, path-scoped rules per area and a `test-writer` agent

---

## Tech Stack

**Core Libraries:**
- State Management: Riverpod 3, Freezed 4 (immutable state)
- Network Layer: Dio 5 + retrofit, with a sealed `ApiException` and translated error messages
- Local Storage: Hive CE 2 with AES-256 encryption
- UI & Navigation: GoRouter 18, FlexColorScheme 9, Google Fonts 9, Material 3

**Developer Tools:**
- Flutter Lints 6, riverpod_lint and the template's own analyzer plugin (`packages/app_lints`)
- Custom linting rules (`lint_rules.yaml`)
- Build Runner, code generation
- Melos 7 scripts across the workspace
- Dart & Flutter DevTools support

---

## Project Structure

The repo is a Dart pub workspace: the app lives in `app/`, shared infrastructure in `packages/core/`, and Melos scripts at the root run across every package.

```
.
├── app/                   # The app: pubspec, lib/, test/, assets/, platform folders, fastlane lanes
├── packages/
│   ├── core/              # Infrastructure every app gets (bootstrap, network, session, permissions, logging)
│   ├── firebase_module/   # Optional Module: Firebase Analytics and Remote Config
│   ├── sentry_module/     # Optional Module: Sentry error reporting
│   └── app_lints/         # Analyzer plugin: the template's architecture rules and your app's own
├── widgetbook/            # Widgetbook catalog (web)
├── .github/               # Workflows, the shared setup action, Dependabot
├── Gemfile                # fastlane, for the release workflow
└── pubspec.yaml           # Workspace list and Melos scripts
```

```
app/lib/
├── app/               # App-wide setup: config, theme, tokens, Modules, overrides, l10n delegates
├── common/            # Shared widgets
├── constants/         # App-wide constants (assets, strings)
├── data/              # Shared models
├── fakes/             # FakeStorage and FakeScope, for tests and the catalog
├── features/          # Features (authentication, home, demo)
│   └── authentication/
│       ├── data/
│       ├── domain/
│       ├── fakes/     # The Feature's Fakes (FakeAuthRepository)
│       └── presentation/
├── hive/              # Local storage setup and adapters
├── l10n/              # ARB files and generated localizations
├── router/            # Navigation, routing and the permission menu
├── shared/            # Code shared between Features (permission keys)
├── utils/             # Utility functions
├── main_<flavor>.dart # One entry point per flavor (main.dart is dev)
└── my_app.dart        # App configuration
```

---

## Create a new app

Start from everything, then remove what you don't need. Each step links to the section with the details.

1. **Use this template.** Click **Use this template** on this repo (or on your organization's copy, see below). The new repo gets its own fresh history and never merges template updates; later template fixes reach it by hand.
2. **Set your identity.** Edit the ids and names listed in [Customize names and IDs](#customize-names-and-ids): `app/android/gradle.properties`, `app/Identity.xcconfig`, `app/web/manifest.json`, `app/web/index.html`, `app/windows/CMakeLists.txt` and `app/linux/CMakeLists.txt`. The Dart package name and the Kotlin namespace stay as they are.
3. **Point at your backend.** Set `apiBaseUrl` and `apiKey` per flavor in `app/lib/app/config.dart`, then replace the demo login (reqres.in) and the demo permission loader (`app/lib/features/authentication/data/demo_permissions.dart`) with your own.
4. **Design context.** Fill in `PRODUCT.md` (or run `/impeccable teach` with the impeccable plugin on) and rewrite the prose of `DESIGN.md` for your app. After changing tokens in `app/lib/app/tokens.dart`, run `dart run melos run design:update`: `DESIGN.md`'s frontmatter is generated from the theme and CI fails when it is out of date.
5. **Register the ids.** Register the bundle ids with Apple (Certificates, Identifiers & Profiles; `.dev` and `.staging` too if you run those flavors on devices) and create the app in Play Console. For local device builds, add your Apple team id as in [Signing on iOS and macOS](#signing-on-ios-and-macos).
6. **Firebase.** Edit and run the `firebase:configure:<flavor>` scripts as in [Set up Firebase](#set-up-firebase), or [remove the Firebase Module](#remove-firebase).
7. **Sentry.** Paste your DSN as in [Sentry Module](#sentry-module), or [remove the Sentry Module](#remove-sentry).
8. **Protect `main`.** In Settings > Rules > Rulesets (or Settings > Branches), protect `main` and require the status checks `check`, `build-android`, `build-ios` and `build-web` from `ci.yaml`. "Use this template" doesn't copy this setting, and the checks only appear in the picker after `ci.yaml` has run once. See [CI](#ci).
9. **fastlane placeholders.** Replace the certificates repo URL in [app/ios/fastlane/Matchfile](app/ios/fastlane/Matchfile) (or set `MATCH_GIT_URL`); for local runs, also `team_id` in [app/ios/fastlane/Appfile](app/ios/fastlane/Appfile) and `json_key_file` in [app/android/fastlane/Appfile](app/android/fastlane/Appfile). The lanes refuse to upload while the id is still `com.example.temp`.
10. **Release secrets, variables and match.** Follow [One-time setup](#one-time-setup): the Play upload keystore and service account, the App Store Connect API key, the first `match` run that creates the certificate and profile, the secrets and variables, then `RELEASE_ENABLED`.
11. **Widgetbook hosting.** Two optional opt-ins, independent of each other: publish `main`'s catalog to Pages (the Pages source and the `WIDGETBOOK_PUBLISH` variable, as in [Publish it to GitHub Pages](#publish-it-to-github-pages)), and host a preview for every PR (a Firebase project, its service-account key and the `WIDGETBOOK_PR_PREVIEW` variable, as in [Preview every PR](#preview-every-pr)). Or [remove Widgetbook](#remove-widgetbook).
12. **Runners (optional).** Set the repository variables `LINUX_RUNNER`, `MACOS_RUNNER` and `WINDOWS_RUNNER` to use other runner labels. See [CI](#ci).
13. **Your own Claude Code rules (optional).** Add them as `.claude/rules/app-*.md`, or edit the template's rules freely: your app never merges template updates. See [Claude Code](#claude-code).
14. **Clean up.** Delete the open-source files a private app doesn't need: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, `.github/FUNDING.yml` and `.github/ISSUE_TEMPLATE/`.

### Keeping your own copy of the template

If your organization keeps its own copy of this repo (to add its own rules or Modules and merge updates from here), mark that copy as a template repository: Settings > General > **Template repository**. Without it, the copy has no **Use this template** button.

Put your company's Claude Code rules in `.claude/rules/company-*.md` and leave the template's own files untouched, so updates from here merge without conflicts. See [Claude Code](#claude-code).

---

## Run it locally

1. **Install dependencies (every package):**
    ```bash
    flutter pub get
    ```

2. **Generate code (every package):**
    ```bash
    dart run melos run gen
    ```

3. **Run the app (dev flavor):**
    ```bash
    cd app
    flutter run --flavor dev -t lib/main_dev.dart
    ```

4. **Analyze and test, as CI does:**
    ```bash
    dart run melos run analyze
    dart run melos run test
    ```

---

## Flavors (app names & package IDs)

This template ships with dev, staging, and prod flavors for Android and iOS. On web and desktop the entry point alone picks the flavor.

### Run commands

Run these from `app/`, or use the dev/staging/prod configs in `.vscode/launch.json`.

- Dev:
    ```bash
    flutter run --flavor dev -t lib/main_dev.dart
    ```
- Staging:
    ```bash
    flutter run --flavor staging -t lib/main_staging.dart
    ```
- Prod:
    ```bash
    flutter run --flavor prod -t lib/main_prod.dart
    ```

### Customize names and IDs

- Android application id, flavor suffixes and app names: the `app.*` keys in [app/android/gradle.properties](app/android/gradle.properties) (the Kotlin namespace stays as it is)
- Web app name: `name` in [app/web/manifest.json](app/web/manifest.json). The description is in two places that can't share one value: `description` in `manifest.json` and the `description` meta tag in [app/web/index.html](app/web/index.html).
- Windows app name: `APP_NAME` in [app/windows/CMakeLists.txt](app/windows/CMakeLists.txt)
- Linux application id and window title: `APPLICATION_ID` and `APP_NAME` in [app/linux/CMakeLists.txt](app/linux/CMakeLists.txt)
- Windows and Linux executable file name (`temp.exe`, `temp`): `BINARY_NAME` in the same two files. The Flutter tool reads it from that line, so it can't come from another value; change it only if the file name matters to you.
- iOS and macOS bundle id, display name and the macOS copyright (About panel): [app/Identity.xcconfig](app/Identity.xcconfig), included by every flavor xcconfig. The iOS dev and staging flavors add their suffixes (`.dev`, ` Dev`) in `app/ios/Flutter/<Config>-<flavor>.xcconfig`.
- Per-flavor backend URL and settings: [app/lib/app/config.dart](app/lib/app/config.dart). A plain `flutter run` without `--flavor` uses dev.

### Signing on iOS and macOS

The Xcode projects carry no development team. To run on a device or sign locally, create `app/ios/Flutter/Signing.xcconfig` (and `app/macos/Runner/Configs/Signing.xcconfig` for macOS) with your team id:

```
DEVELOPMENT_TEAM = ABCDE12345
```

Every flavor xcconfig includes it when it exists. Both files are gitignored; unsigned builds (`flutter build ios --no-codesign`) work without them.

---

## Minimum OS

The template supports what Flutter supports and moves when Flutter raises its minimums. An app may raise a minimum for its audience, never lower it.

| Platform | Minimum | Where it is set |
|---|---|---|
| Android | API 24 (Android 7.0), from Flutter | `minSdk = flutter.minSdkVersion` in `app/android/app/build.gradle.kts`, so it tracks Flutter |
| iOS | 15.0 | `IPHONEOS_DEPLOYMENT_TARGET` in `app/ios/Runner.xcodeproj` |
| macOS | 12.0 | `MACOSX_DEPLOYMENT_TARGET` in `app/macos/Runner.xcodeproj` |
| Windows | Windows 10 | Flutter's minimum; nothing to set |
| Linux | Debian 10 / Ubuntu 20.04 | Flutter's minimum; nothing to set |
| Web | Chrome, Edge and Firefox (latest two versions), Safari 15.6 | Flutter's supported browsers |

Android, iOS and web are first-class: every feature works there, and CI builds them on every PR. macOS, Windows and Linux are build-only: CI builds them after merge, and Modules whose native SDK is missing there (Firebase) switch themselves off.

---

## CI

Five workflows live in `.github/workflows/`. None of them needs a secret until you turn on releases or per-PR previews.

| Workflow | Runs on | Jobs |
|---|---|---|
| `ci.yaml` | every PR to `main` and every push to `main` | `check`, `build-android`, `build-ios`, `build-web` |
| `desktop.yaml` | push to `main`, weekly (Monday 03:00 UTC), manual | `build-macos`, `build-windows`, `build-linux` |
| `release.yaml` | a `v*` tag, only when `RELEASE_ENABLED` is `true` | `version`, `release-android`, `release-ios`, `release-web`, `github-release` |
| `widgetbook.yaml` | push to `main`, manual, only when `WIDGETBOOK_PUBLISH` is `true` | `publish` |
| `widgetbook-preview.yaml` | a PR to `main` from this repo (opened, pushed to, reopened, closed), only when `WIDGETBOOK_PR_PREVIEW` is `true` | `deploy`, `cleanup` (on close) |

- **`check`** runs `melos run gen` and fails when a generated file (`*.g.dart`, `*.freezed.dart`, generated localizations) is out of date, then `melos run analyze` (any lint info fails) and `melos run test`. There is no format check.
- **Build jobs** make unsigned prod release builds, so R8 and tree-shaking problems show up before a release. `build-ios` (and `build-macos`) fails if a `Podfile` appears: every plugin must support Swift Package Manager.
- **Required checks:** the four `ci.yaml` jobs are meant to block merges. Turn that on in branch protection (step 8 of [Create a new app](#create-a-new-app)).
- **Desktop** runs only after merge, because macOS and Windows minutes are expensive. GitHub turns off scheduled workflows after 60 days without repo activity, and a failed scheduled run only emails whoever last edited the workflow file.
- **Runners** come from the repository variables `LINUX_RUNNER`, `MACOS_RUNNER` and `WINDOWS_RUNNER` (defaults `ubuntu-latest`, `macos-latest`, `windows-latest`), so a copy can switch runners without editing the workflows.
- **Dependabot** ([.github/dependabot.yml](.github/dependabot.yml)) updates pub packages, GitHub Actions and the `Gemfile` weekly.

---

## Modules

A Module is optional infrastructure in `packages/<name>_module/` that plugs into Core's `ErrorReporter`, `Analytics` or `RemoteFlags`. The template ships every Module wired in, so its CI covers them all; an app removes the ones it doesn't want. Core skips a Module on platforms it doesn't support and falls back to no-op defaults.

### Remove a Module

Delete all of these, then run `flutter pub get` and `dart run melos run analyze` (a leftover import or dependency fails the analysis):

- `packages/<name>_module/`
- `- packages/<name>_module` in the root `pubspec.yaml` workspace list
- its dependency in `app/pubspec.yaml`
- its dependency in `widgetbook/pubspec.yaml`, and any use cases in `widgetbook/lib/` that import it
- its entry and import in `app/lib/app/modules.dart`
- its localizations delegate in `app/lib/app/l10n.dart`, if it has strings (neither shipped Module does)
- its line in `CLAUDE.md` and its section in this README
- the Module's own extras: [Firebase](#remove-firebase), [Sentry](#remove-sentry)

`flutter pub get` regenerates the macOS, Windows and Linux plugin registrants without the Module's plugins; commit them.

To add a Module back, copy its folder from the template and add the same lines again, plus the vendor's native setup.

---

## Firebase Module

[packages/firebase_module](packages/firebase_module) provides Firebase Analytics and Remote Config through Core's `Analytics` and `RemoteFlags`. It runs on Android, iOS and web; on macOS, Windows and Linux Core skips it. Crash reporting is not part of it.

**As shipped, Firebase is not configured.** The options files in `packages/firebase_module/lib/src/options/` are placeholders, so the Module's `init` throws `Firebase not configured for <flavor>`, Core logs that once, and the app runs on the no-op `Analytics` and `RemoteFlags`. There are no Firebase native files in `app/`.

Ordinary Remote Config fetches run at most every 12 hours (5 minutes on dev); real-time updates are not limited by that interval and are fetched as soon as the backend publishes them. Reads never wait on the network: they use the last cached values, a refresh runs in the background, and the real-time listener activates updates as they arrive, then fires `RemoteFlags.onChanged`. When a fetch fails, the cached values (or the fallbacks) stay.

### Set up Firebase

Each flavor uses its own Firebase project. Two flavors can share one by passing the same `--project`.

1. Install the [Firebase CLI](https://firebase.google.com/docs/cli) and `dart pub global activate flutterfire_cli`, then `firebase login`.
2. Create the Firebase projects, then edit `--project`, `--android-package-name` and `--ios-bundle-id` in the `firebase:configure:<flavor>` scripts in the root [pubspec.yaml](pubspec.yaml). Ids must match `app/android/gradle.properties` and `app/Identity.xcconfig` (plus the iOS flavor suffixes).
3. Run, once per flavor:
    ```bash
    dart run melos run firebase:configure:dev
    dart run melos run firebase:configure:staging
    dart run melos run firebase:configure:prod
    ```
   Each script runs `flutterfire configure` in `app/` once per iOS build configuration (`Debug-<flavor>`, `Profile-<flavor>`, `Release-<flavor>`). It writes the Dart options file over the placeholder, `app/android/app/src/<flavor>/google-services.json`, `app/ios/flavors/<flavor>/GoogleService-Info.plist` and `app/firebase.json`, adds the google-services Gradle plugin, and adds a "FlutterFire: bundle-service-file" build phase to the Runner target.
4. Commit every generated file. Firebase options are identifiers, not secrets; restrict the API keys in Google Cloud instead.
5. Install `flutterfire` on every Mac that builds iOS: the Xcode build phase calls it. The `build-ios` job in `ci.yaml` and `release.yaml` already install it once `app/firebase.json` exists. Add SHA fingerprints for each Android app, and link each flavor's web app to Google Analytics.

### iOS advertising id

Analytics is linked without the advertising id (IDFA). Under Swift Package Manager, `firebase_analytics` decides this from the `FIREBASE_ANALYTICS_WITHOUT_ADID` environment variable while packages resolve, so it has to be set wherever iOS is built:

- CI: the `build-ios` job in [.github/workflows/ci.yaml](.github/workflows/ci.yaml) and the `release-ios` job in [.github/workflows/release.yaml](.github/workflows/release.yaml) set it.
- Locally: `export FIREBASE_ANALYTICS_WITHOUT_ADID=true` in your shell profile before `flutter build ios` / `flutter run`. Xcode opened from the Dock does not see your shell; run `launchctl setenv FIREBASE_ANALYTICS_WITHOUT_ADID true` and restart Xcode.
- After changing it, clear the resolved packages (`flutter clean`, then delete Xcode's DerivedData for the app) so the package resolves again.

Keep this setting unless the app needs IDFA, for example for cross-app tracking or ad attribution that depends on it. Showing ads alone does not require IDFA. An app that does need it removes the variable everywhere, then must ask for permission through App Tracking Transparency before tracking, declare the tracking in its privacy manifest and App Store privacy details, and collect any consent its regions require (for example GDPR consent in the EU).

### Remove Firebase

Follow [Remove a Module](#remove-a-module) for `firebase_module`, then also delete:

- the `firebase:configure:*` scripts in the root `pubspec.yaml`
- `FIREBASE_ANALYTICS_WITHOUT_ADID` in `.github/workflows/ci.yaml` and `.github/workflows/release.yaml` (and in your shell or `launchctl`)
- the "Install the FlutterFire CLI" steps in `.github/workflows/ci.yaml` and `.github/workflows/release.yaml`
- the "Read the firebase_core version" and "Cache the Firebase C++ SDK" steps in the `build-windows` job of `.github/workflows/desktop.yaml`
- the `firebase-dependencies` group in `.github/dependabot.yml`

Once Firebase has been configured, also delete:

- `app/firebase.json`
- the `com.google.gms.google-services` lines in `app/android/settings.gradle.kts` and `app/android/app/build.gradle.kts`
- `app/android/app/src/{dev,staging,prod}/google-services.json`
- `app/ios/flavors/{dev,staging,prod}/GoogleService-Info.plist`
- the "FlutterFire: bundle-service-file" build phase on the Runner target (remove it in Xcode)

---

## Sentry Module

[packages/sentry_module](packages/sentry_module) reports errors to Sentry through Core's `ErrorReporter` on all six platforms, and crash-free statistics on every platform except web (sentry_flutter starts web sessions only from its `SentryNavigatorObserver`, which the template does not add). Staging and prod report, with the flavor name as the Sentry `environment`; dev never starts Sentry. There is no tracing, session replay, screenshots, personal data or HTTP capture.

**As shipped, Sentry is off.** Set `sentryDsn` in [packages/sentry_module/lib/src/sentry_options.dart](packages/sentry_module/lib/src/sentry_options.dart) to your project's DSN (Sentry project settings > Client Keys). One Sentry project serves every flavor. A DSN is not a secret. To get readable prod stack traces, set up the symbol upload in [Releases](#releases).

### Remove Sentry

Follow [Remove a Module](#remove-a-module) for `sentry_module`, then also delete:

- the `sentry_dart_plugin` dev dependency in `app/pubspec.yaml`
- the three "Upload ... to Sentry" steps in `.github/workflows/release.yaml`, and the Sentry rows and notes in [Releases](#releases)
- in `.github/workflows/desktop.yaml`, the "Allow long paths in git" step of `build-windows` and `libcurl4-openssl-dev` in `build-linux` (both are there for Sentry's native SDK)

---

## Authentication

The template includes a complete authentication system with secure credential storage and error handling.

### How it works

- **Login & Registration:** A retrofit client (`AuthApi`) POSTs to `api/login` and `api/register` through Core's shared Dio.
- **Session:** A successful login saves the token in Core's encrypted Hive box, so the user stays signed in after a restart. The app opens on a splash, then goes to home or login. Logout clears the token, and the back button can't undo it.
- **Token refresh:** On a 401, Core refreshes the token once through the auth Feature's optional `refresh` hook and replays the failed requests. If the refresh is rejected (or there is nothing to refresh, as with reqres), the user is signed out, sees "Your session has expired" on the login screen, and comes back to the same page after signing in. A network error during the refresh keeps them signed in.
- **Permissions:** Login completes only after the user's permission areas load (a demo loader here: profile, settings and orders, not reports). Each route declares its area; opening one outside them, even by a direct link, shows a "no permission" page. They are saved encrypted, reloaded once per launch and after a 403, and deleted on logout. `PermissionGate` applies the backend's rule for one control (hidden, read-only or greyed out; the home screen shows one of each), and the home screen's menu lists only granted areas, sending entries without a screen to an "under construction" page. Debug builds log permission keys the app checks that no loaded permissions contain.
- **Remember me:** When ticked, the email and password are saved (encrypted) only to pre-fill the login form; they never sign the user in. Unticking deletes them; logout keeps them.
- **Encryption key:** One random AES-256 key, created on first launch and kept in the platform's secure storage (`flutter_secure_storage`). Android backups exclude the Hive files and that key.
- **State Management:** All authentication UI and logic is managed via Riverpod notifiers and state classes.
- **Error Handling:** Network failures become an `ApiException` and show as a translated snackbar.
- **Loading State:** UI reflects loading and error states for a smooth UX.

### Test Credentials

You can test the authentication functionality using these credentials from [reqres.in](https://reqres.in/):

**Login:**
```json
{
    "email": "eve.holt@reqres.in",
    "password": "cityslicka"
}
```

**Register:**
```json
{
    "email": "eve.holt@reqres.in",
    "password": "pistol"
}
```

**Example:**
```dart
@riverpod
class LoginController extends _$LoginController {
  // ... state and logic here
  Future<LoginResponse> login({required String email, required String password}) async {
    // Handles login, error handling, caching, loading state etc.
  }
}
```
---

## Widgetbook

`widgetbook/` is a web-only [Widgetbook](https://www.widgetbook.io/) catalog where designers can browse Core's screens and the demo screens: the no-permission and under-construction pages, the force-update dialog (blocking and dismissible), the error snackbar and error view for each `ApiException` kind, `PermissionGate`'s states, and the demo login and home screens running on fake repositories. Its toolbar switches the theme (the app's light and dark themes), the locale (en, tr), the device frame (phone, tablet, desktop) and the text scale. When you run it locally (`dart run melos run widgetbook`, a debug build) it also turns on accessibility checks; the catalog published to GitHub Pages and the per-PR previews are release builds, where `accessibility_tools` checks nothing, so they have no accessibility addon.

It is its own workspace member that depends on the app, Core and each Module; the app never depends on it.

### Run it

```bash
dart run melos run widgetbook
```

(or `flutter run -d chrome` inside `widgetbook/`).

### Add a use case

Write a function annotated with `@UseCase` in a file whose path mirrors the widget's, for example `widgetbook/lib/core/permission_gate.use_cases.dart` for Core's `PermissionGate`, or `widgetbook/lib/app/features/home/presentation/home_screen.use_cases.dart` for the app's home screen. Screens that use Riverpod get their own `ProviderScope` with fake overrides (see `FakeScope` in the app's `lib/fakes/`). Then run `dart run melos run gen`, which regenerates `widgetbook/lib/main.directories.g.dart`; commit it. CI fails when it is out of date.

### Publish it to GitHub Pages

`.github/workflows/widgetbook.yaml` builds the catalog for the web and deploys it to GitHub Pages on every push to `main` and on manual dispatch. It does nothing until you opt in:

1. In the repo's Settings > Pages, set the source to **GitHub Actions**.
2. In Settings > Secrets and variables > Actions > Variables, add the repository variable `WIDGETBOOK_PUBLISH` with the value `true`.

No secrets are needed.

### Preview every PR

`.github/workflows/widgetbook-preview.yaml` builds the catalog for the web (a release build) on every push to a pull request and deploys it to a [Firebase Hosting preview channel](https://firebase.google.com/docs/hosting/test-preview-deploy) named `pr-<number>`. The deploy posts a comment on the PR with the preview link, updates that comment on later pushes, and adds a check run. It is never a required check, so a preview outage doesn't block a merge. It is separate from the Pages publish above: you can turn on either one, both, or neither.

It does nothing until you opt in. One-time setup:

1. **A Firebase project for the catalog.** Create a separate project in the [Firebase console](https://console.firebase.google.com/) by default, not the one the Firebase Module uses: the preview belongs to Widgetbook, and removing either one then leaves the other alone. The no-cost Spark plan is enough.
2. **Hosting.** In that project, open Hosting and click Get started, so the project has its default Hosting site. You don't need to deploy anything: the workflow's `widgetbook/firebase.json` already serves `build/web`.
3. **A service account.** In the Google Cloud console for the same project (IAM & Admin > Service accounts), create a service account with the role **Firebase Hosting Admin**, then create a JSON key for it (Keys > Add key > JSON) and download the file.
4. **The variable and the secret.** In Settings > Secrets and variables > Actions, add the repository variable `WIDGETBOOK_FIREBASE_PROJECT_ID` (the project id, not its display name) and the repository secret `WIDGETBOOK_FIREBASE_SERVICE_ACCOUNT_JSON` (paste the whole JSON key as text). Then delete the downloaded key file.
5. **Turn it on.** Add the repository variable `WIDGETBOOK_PR_PREVIEW` with the value `true`. The next push to an open PR deploys its preview.

What to know:

- **Fork PRs get no preview.** GitHub gives a PR from a fork no secrets, so the workflow only runs for PRs from a branch of this repo. Review a fork PR's catalog locally with `dart run melos run widgetbook`.
- **Preview URLs are public.** Anyone with the link can open the catalog, so keep real data and secrets out of use cases (the template's use cases run on fakes).
- **Channels clean themselves up.** Each channel expires 14 days after its last deploy, and closing or merging the PR deletes it.

### Remove Widgetbook

Delete all of these, then run `flutter pub get`:

- `widgetbook/` (with it `widgetbook/firebase.json`, the preview's Hosting config)
- `- widgetbook` in the root `pubspec.yaml` workspace list
- the `dependency_overrides` block for `analyzer` in the root `pubspec.yaml` (it exists only for `widgetbook_generator`)
- the `widgetbook` Melos script in the root `pubspec.yaml`
- `.github/workflows/widgetbook.yaml` and `.github/workflows/widgetbook-preview.yaml`
- the `"/widgetbook"` line in `.github/dependabot.yml`
- the `widgetbook/` line and the other Widgetbook mentions in `CLAUDE.md`, and this section of the README

If you turned on previews, also delete the repository variables `WIDGETBOOK_PR_PREVIEW` and `WIDGETBOOK_FIREBASE_PROJECT_ID` and the secret `WIDGETBOOK_FIREBASE_SERVICE_ACCOUNT_JSON`, and delete the Firebase preview project (or at least its service account). If you turned on Pages, delete `WIDGETBOOK_PUBLISH` too.

---

## Releases

`.github/workflows/release.yaml` ships the prod flavor when you push a version tag (`v*`):

- **Android:** an obfuscated App Bundle, signed with your upload keystore, goes to Play's internal track (`supply`).
- **iOS:** `match` (readonly) fetches the App Store certificate and profile, `update_code_signing_settings` applies them, `gym` archives the obfuscated build and the IPA goes to TestFlight.
- **Web:** a release build with source maps. Hosting is up to you; the build is attached to the GitHub Release as `web.zip` (without the `.map` files).
- **Sentry:** each job uploads its debug symbols (web: source maps) with `sentry_dart_plugin`, under the same release and dist that the Sentry Module reports.
- **GitHub Release:** once all three jobs succeed, the tag's release gets the App Bundle, the iOS archive, the Dart debug symbols (plus the R8 mapping) and the web build.

It does nothing until you opt in: every job runs only when the repository variable `RELEASE_ENABLED` is `true`. The template sets nothing, so its tags skip cleanly.

The lanes are in [app/android/fastlane](app/android/fastlane) and [app/ios/fastlane](app/ios/fastlane); fastlane is pinned by the root `Gemfile` and `Gemfile.lock` (Dependabot updates them). Each lane runs `flutter build` itself, then signs and uploads. To run one locally: `bundle install` at the root, then `bundle exec fastlane android release` from `app/android` (or `ios release` from `app/ios`) with the same environment variables set. The Android lane also takes the keystore from `app/android/key.properties` (below) and the Play key from `json_key_file` in its [Appfile](app/android/fastlane/Appfile).

### Versions and tags

The version comes from `version: <name>+<build>` in `app/pubspec.yaml`, and the tag must be `v<name>` (the `version` job fails otherwise). A tag with a `-` (`v1.2.0-rc.1`) makes a prerelease. Bump the build number for every release: Play and App Store Connect reject a build number they have seen before.

The Sentry release must match what `sentry_flutter` reports, `<package id>@<name>+<build>` with dist `<build>`, and the package id differs per platform. The workflow reads it from the same files the build does:

| Platform | Release | Read from |
|---|---|---|
| Android | `<application id>@<name>+<build>` | `app.applicationId` + `app.prod.applicationIdSuffix` in `app/android/gradle.properties` |
| iOS | `<bundle id>@<name>+<build>` | `IDENTITY_BUNDLE_ID` in `app/Identity.xcconfig` |
| Web | `<pubspec name>@<name>+<build>` | `name` in `app/pubspec.yaml` (web has no package id) |

### One-time setup

1. Set your own ids ([Customize names and IDs](#customize-names-and-ids)). The lanes refuse to upload while the id is still `com.example.temp`.
2. **Android:** create an upload keystore (`keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`) and keep it outside the repo. Create the app in Play Console and upload the first App Bundle by hand: the Play API can't create an app or make its first upload. Then create a Google Cloud service account with release access to the app in Play Console and download its JSON key.
3. **iOS:** create the app in App Store Connect and an App Store Connect API key (Users and Access > Integrations, App Manager role). Create an empty private git repo for the certificates. Then, once, someone with App Store access runs `bundle exec fastlane match appstore` from `app/ios` (with `MATCH_GIT_URL` set, or the placeholder in [Matchfile](app/ios/fastlane/Matchfile) replaced) to create the certificate and profile; CI only reads them. The gitignored `Signing.xcconfig` is for local development only; CI doesn't need it.
4. **Sentry (optional):** set `sentryDsn` ([Sentry Module](#sentry-module)) and create an auth token with the `project:releases` and `org:read` scopes. Without the `SENTRY_PROJECT` variable the upload steps are skipped, and prod stack traces stay obfuscated.
5. Add the secrets and variables below (Settings > Secrets and variables > Actions), then set `RELEASE_ENABLED` to `true`.

| Name | Kind | Use |
|---|---|---|
| `RELEASE_ENABLED` | variable | `true` turns the release jobs on |
| `ANDROID_KEYSTORE_BASE64` | secret | the upload keystore, base64 (`base64 -i upload-keystore.jks \| pbcopy` on macOS, `base64 -w0 upload-keystore.jks` on Linux) |
| `ANDROID_KEYSTORE_PASSWORD` | secret | the keystore password |
| `ANDROID_KEY_ALIAS` | secret | the key alias (`upload` in the command above) |
| `ANDROID_KEY_PASSWORD` | secret | the key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | secret | the service account's JSON key, pasted as text, for `supply` |
| `MATCH_GIT_URL` | variable | HTTPS URL of the private certificates repo |
| `MATCH_PASSWORD` | secret | the passphrase match encrypts the certificates with |
| `MATCH_GIT_BASIC_AUTHORIZATION` | secret | `base64("<user>:<token>")` for a token that can read the certificates repo |
| `APP_STORE_CONNECT_API_KEY_ID` | secret | the API key's id |
| `APP_STORE_CONNECT_ISSUER_ID` | secret | the issuer id shown above the keys list |
| `APP_STORE_CONNECT_API_KEY` | secret | the contents of the downloaded `.p8` file, pasted as text |
| `SENTRY_AUTH_TOKEN` | secret | Sentry auth token for the symbol upload |
| `SENTRY_ORG` | variable | Sentry organization slug |
| `SENTRY_PROJECT` | variable | Sentry project slug; when unset, the Sentry upload steps are skipped |

The runner labels come from `LINUX_RUNNER` and `MACOS_RUNNER`, as in [CI](#ci).

Never commit keystores, `key.properties`, `.p8` keys or service-account JSON; `.gitignore` already excludes them.

### Signing Android locally

`app/android/app/build.gradle.kts` signs release builds with the upload keystore when one is set, and with the debug keys otherwise (so `flutter run --release` and CI's unsigned builds keep working). CI sets `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. Locally, create the gitignored `app/android/key.properties` instead:

```
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

A relative `storeFile` is resolved from `app/android/`.

### Sentry commits

The upload runs with `commits=false`, so Sentry doesn't link commits to the release. To turn that on, connect the repository in Sentry, check out with `fetch-depth: 0` in the jobs that upload, and drop `--sentry-define=commits=false`.

---

## Testing

- Integrated tests for auth controller logic (`app/test/features/login_controller_test.dart`) and the session flow: restart, redirect and logout (`app/test/app/session_flow_test.dart`), and the permission guard, gates and menu (`app/test/app/permissions_flow_test.dart`)
- Run tests in every package with:
    ```bash
    dart run melos run test
    ```

---

## Claude Code

The repo ships instructions for [Claude Code](https://claude.com/claude-code), which people can read too:

- **[CLAUDE.md](CLAUDE.md)** is short and loads in every session: the working style, the rules that always apply, the repo layout and the commands.
- **[`.claude/rules/`](.claude/rules)** holds the detailed rules, one file per area. Each file loads only when Claude reads or edits a file its `paths:` match, so a session pays only for the rules it needs. A rule drops out of the context at `/compact` and loads again on the next matching read.

| File | Covers |
|---|---|
| `presentation.md` | UI files (screens and their widgets, Shared widgets), the catalog's use cases, controllers and UI models |
| `theming.md` | The theme, design tokens, fonts, strings and ARB files, `DESIGN.md` |
| `networking.md` | The shared Dio, retrofit clients, `ApiException` and showing errors |
| `session-permissions.md` | The Session, token refresh, permissions and local storage |
| `routing.md` | GoRouter, the redirects and the permission guard |
| `logging.md` | Logging, breadcrumbs and error reporting, the Sentry Module |
| `shell.md` | Entry points, flavors, config, Modules, force update, platforms and minimum OS |
| `widgetbook.md` | The Widgetbook catalog and its publish and per-PR preview workflows |
| `ci-release.md` | CI, desktop builds, releases, fastlane and Dependabot |
| `lint-plugins.md` | The `app_lints` analyzer plugin |
| `testing.md` | Tests and their helpers |

- **[`.claude/agents/test-writer.md`](.claude/agents/test-writer.md)** is a subagent that writes tests from requirements (a new feature, a bug reproduction) without reading the implementation. Claude hands work to it on its own, or ask for it by name.
- **[`.claude/settings.json`](.claude/settings.json)** recommends plugins to everyone who clones the repo. It registers two plugin marketplaces and turns on only the [dart-flutter](https://github.com/flutter/agent-plugins) plugin (the Dart MCP server and the Dart and Flutter skills); Claude Code asks once to trust the folder, and once to approve the MCP server. [impeccable](https://github.com/pbakaus/impeccable), the design plugin, is registered but off: a Designer turns it on with `claude plugin install impeccable@impeccable`. Use either impeccable's plugin or its standalone skill, not both, or Claude sees two copies. Claude Code on the web ignores this file.
- **Personal files** are gitignored: `CLAUDE.local.md` for your own instructions and `.claude/settings.local.json` for your own permissions. They never reach anyone else, and Claude Code on the web doesn't see them.

### Your own rules

- **A Company copy** commits its rules as `.claude/rules/company-*.md` and never edits the template's files, so updates from the Public template merge without conflicts.
- **A Derived app** adds `.claude/rules/app-*.md`, or edits the template's rules freely, since it never merges updates.

---

## Documentation

- Up-to-date documentation in this README
- [CLAUDE.md](CLAUDE.md) and [`.claude/rules/`](.claude/rules): the architecture, commands and the rules the code follows (see [Claude Code](#claude-code))
- [CONTEXT.md](CONTEXT.md): the project's vocabulary (Module, Feature, Flavor, Session, ...)
- [PRODUCT.md](PRODUCT.md): what the app is for and who it serves, for Claude and impeccable; ships as a `[TODO]` skeleton
- [DESIGN.md](DESIGN.md): the design system in Google Stitch format; its frontmatter is generated from the theme (`dart run melos run design:update`), its prose is written by hand
- Code comments and examples throughout

---

## Contributing

See our [Contributing Guide](CONTRIBUTING.md) for details on how to:
- Set up your development environment
- Run tests
- Submit pull requests

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

- [https://www.erengun.dev](https://www.erengun.dev)
