[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)
# Flutter Riverpod Template - 2025 Edition

## Modern Flutter Architecture Template with Riverpod

A production-ready Flutter template built with the latest packages and best practices, supporting Flutter 3.32 and above. This template implements clean architecture principles and provides a robust foundation for building scalable applications.

---

### Key Features

- 🏗️ Clean Architecture with Domain-Driven Design
- 🎯 Riverpod 2.6+ with code generation
- 🔒 Built-in authentication pack with secure storage (Hive CE + AES-256)
- 🌐 Type-safe API integration with retrofit clients on one shared Dio
- 📱 Responsive UI with adaptive widgets
- 🌍 Internationalization with Flutter's gen-l10n (ARB files, English and Turkish)
- 💾 Secure local storage with Hive CE
- 🧪 Pre-configured unit testing for authentication and controller logic
- ⚡ Modern navigation with GoRouter 14.8+
- 🛠️ Custom linting and devtools configuration

---

## Tech Stack

**Core Libraries:**
- State Management: Riverpod 2.6.1, Freezed 3.0.6 (immutable state)
- Network Layer: Dio 5 + retrofit, with a sealed `ApiException` and translated error messages
- Local Storage: Hive CE 2.11.1 with AES-256 encryption
- UI & Navigation: GoRouter 14.8.0, Google Fonts 6.2.1, Material 3

**Developer Tools:**
- Flutter Lints 5.0.0
- Build Runner, code generation
- Custom linting rules (`lint_rules.yaml`)
- Dart & Flutter DevTools support

---

## Project Structure

The repo is a Dart pub workspace: the app lives in `app/`, shared infrastructure in `packages/core/`, and Melos scripts at the root run across every package.

```
app/lib/
├── common/            # Shared widgets and components
├── config/            # App configuration (theme etc.)
├── constants/         # App-wide constants (assets)
├── core/              # Core functionality, network layer
├── features/          # Feature modules (authentication, home, ...)
│   └── authentication/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── hive/              # Local storage setup and adapters
├── router/            # Navigation & routing
├── utils/             # Utility functions
├── main.dart          # App entry point
└── my_app.dart        # App configuration
```

---

## Getting Started


### Setup

1. **Clone the template:**
    ```bash
    git clone https://github.com/Erengun/Flutter-Riverpod-2.0-Template.git my_app
    cd my_app
    ```

2. **Install dependencies:**
    ```bash
    flutter pub get
    ```

3. **Generate code (every package):**
    ```bash
    dart run melos run gen
    ```

4. **Setup environment:**
    ```bash
    cp .env.example .env
    ```

5. **Run the app:**
    ```bash
    cd app
    flutter run --flavor prod -t lib/main_prod.dart
    ```

---

## Flavors (app names & package IDs)

This template ships with dev, staging, and prod flavors for Android and iOS.

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
- Web app name: `name` in [app/web/manifest.json](app/web/manifest.json)
- Windows app name: `APP_NAME` in [app/windows/CMakeLists.txt](app/windows/CMakeLists.txt)
- Linux application id: `APPLICATION_ID` in [app/linux/CMakeLists.txt](app/linux/CMakeLists.txt)
- iOS and macOS bundle id and display name: [app/Identity.xcconfig](app/Identity.xcconfig), included by every flavor xcconfig. The iOS dev and staging flavors add their suffixes (`.dev`, ` Dev`) in `app/ios/Flutter/<Config>-<flavor>.xcconfig`.
- Per-flavor backend URL and settings: [app/lib/app/config.dart](app/lib/app/config.dart). A plain `flutter run` without `--flavor` uses dev.

### Signing on iOS and macOS

The Xcode projects carry no development team. To run on a device or sign locally, create `app/ios/Flutter/Signing.xcconfig` (and `app/macos/Runner/Configs/Signing.xcconfig` for macOS) with your team id:

```
DEVELOPMENT_TEAM = ABCDE12345
```

Every flavor xcconfig includes it when it exists. Both files are gitignored; unsigned builds (`flutter build ios --no-codesign`) work without them.

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
    melos run firebase:configure:dev
    melos run firebase:configure:staging
    melos run firebase:configure:prod
    ```
   Each script runs `flutterfire configure` in `app/` once per iOS build configuration (`Debug-<flavor>`, `Profile-<flavor>`, `Release-<flavor>`). It writes the Dart options file over the placeholder, `app/android/app/src/<flavor>/google-services.json`, `app/ios/flavors/<flavor>/GoogleService-Info.plist` and `app/firebase.json`, adds the google-services Gradle plugin, and adds a "FlutterFire: bundle-service-file" build phase to the Runner target.
4. Commit every generated file. Firebase options are identifiers, not secrets; restrict the API keys in Google Cloud instead.
5. Install `flutterfire` on every Mac that builds iOS (CI included): the Xcode build phase calls it. Add SHA fingerprints for each Android app, and link each flavor's web app to Google Analytics.

### iOS advertising id

Analytics is linked without the advertising id (IDFA). Under Swift Package Manager, `firebase_analytics` decides this from the `FIREBASE_ANALYTICS_WITHOUT_ADID` environment variable while packages resolve, so it has to be set wherever iOS is built:

- CI: the `build-ios` job in [.github/workflows/ci.yaml](.github/workflows/ci.yaml) sets it.
- Locally: `export FIREBASE_ANALYTICS_WITHOUT_ADID=true` in your shell profile before `flutter build ios` / `flutter run`. Xcode opened from the Dock does not see your shell; run `launchctl setenv FIREBASE_ANALYTICS_WITHOUT_ADID true` and restart Xcode.
- After changing it, clear the resolved packages (`flutter clean`, then delete Xcode's DerivedData for the app) so the package resolves again.

Keep this setting unless the app needs IDFA, for example for cross-app tracking or ad attribution that depends on it. Showing ads alone does not require IDFA. An app that does need it removes the variable everywhere, then must ask for permission through App Tracking Transparency before tracking, declare the tracking in its privacy manifest and App Store privacy details, and collect any consent its regions require (for example GDPR consent in the EU).

### Remove the Module

Delete all of these:

- `packages/firebase_module/` (options files included)
- `- packages/firebase_module` in the root `pubspec.yaml` workspace list
- the `firebase_module` dependency in `app/pubspec.yaml`
- the `FirebaseModule()` entry and its import in `app/lib/app/modules.dart`
- the `firebase:configure:*` scripts in the root `pubspec.yaml`
- `FIREBASE_ANALYTICS_WITHOUT_ADID` in `.github/workflows/ci.yaml` (and in your shell or `launchctl`)
- the `packages/firebase_module/` line in `CLAUDE.md`

The Firebase entries in the macOS and Windows plugin registrants go away on the next `flutter pub get`, which regenerates them.

Once Firebase has been configured, also delete:

- `app/firebase.json`
- the `com.google.gms.google-services` lines in `app/android/settings.gradle.kts` and `app/android/app/build.gradle.kts`
- `app/android/app/src/{dev,staging,prod}/google-services.json`
- `app/ios/flavors/{dev,staging,prod}/GoogleService-Info.plist`
- the "FlutterFire: bundle-service-file" build phase on the Runner target (remove it in Xcode)
- the `flutterfire` install step in CI, if you added one

---

## Authentication Module

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

## Testing

- Integrated tests for auth controller logic (`app/test/features/login_controller_test.dart`) and the session flow: restart, redirect and logout (`app/test/app/session_flow_test.dart`), and the permission guard, gates and menu (`app/test/app/permissions_flow_test.dart`)
- Run tests in every package with:
    ```bash
    dart run melos run test
    ```

---

## Documentation

- Up-to-date documentation in this README
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
