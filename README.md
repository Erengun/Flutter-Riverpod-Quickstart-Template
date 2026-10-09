[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)
# Flutter Riverpod Template - 2025 Edition

## Modern Flutter Architecture Template with Riverpod

A production-ready Flutter template built with the latest packages and best practices, supporting Flutter 3.32 and above. This template implements clean architecture principles and provides a robust foundation for building scalable applications.

---

### Key Features

- 🏗️ Clean Architecture with Domain-Driven Design
- 🎯 Riverpod 2.6+ with code generation
- 🔒 Built-in authentication pack with secure storage (Hive CE + AES-256)
- 🌐 Type-safe API integration with Dio 5.8+
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
- Network Layer: Dio 5.8.0, FPDart 1.1.0 for functional error handling
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
├── constants/         # App-wide constants (endpoints, assets)
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
- iOS bundle IDs and display names: [app/ios/Flutter/Debug-dev.xcconfig](app/ios/Flutter/Debug-dev.xcconfig) (and the other flavor xcconfig files)
- Per-flavor backend URL and settings: [app/lib/app/config.dart](app/lib/app/config.dart). A plain `flutter run` without `--flavor` uses dev.

---

## Firebase Module

[packages/firebase_module](packages/firebase_module) provides Firebase Analytics and Remote Config through Core's `Analytics` and `RemoteFlags`. It runs on Android, iOS and web; on macOS, Windows and Linux Core skips it. Crash reporting is not part of it.

**As shipped, Firebase is not configured.** The options files in `packages/firebase_module/lib/src/options/` are placeholders, so the Module's `init` throws `Firebase not configured for <flavor>`, Core logs that once, and the app runs on the no-op `Analytics` and `RemoteFlags`. There are no Firebase native files in `app/`.

Remote Config fetches at most every 12 hours (5 minutes on dev). Reads never wait on the network: they use the last cached values, a refresh runs in the background, and the real-time listener activates updates as they arrive, then fires `RemoteFlags.onChanged`. When a fetch fails, the cached values (or the fallbacks) stay.

### Set up Firebase

Each flavor uses its own Firebase project. Two flavors can share one by passing the same `--project`.

1. Install the [Firebase CLI](https://firebase.google.com/docs/cli) and `dart pub global activate flutterfire_cli`, then `firebase login`.
2. Create the Firebase projects, then edit `--project`, `--android-package-name` and `--ios-bundle-id` in the `firebase:configure:<flavor>` scripts in the root [pubspec.yaml](pubspec.yaml). Ids must match `app/android/gradle.properties` and the iOS xcconfig files.
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

Apps that run ads remove the variable everywhere, then also need App Tracking Transparency and a privacy manifest entry.

### Remove the Module

Delete all of these:

- `packages/firebase_module/` (options files included)
- `- packages/firebase_module` in the root `pubspec.yaml` workspace list
- the `firebase_module` dependency in `app/pubspec.yaml`
- the `FirebaseModule()` entry and its import in `app/lib/app/modules.dart`
- the `firebase:configure:*` scripts in the root `pubspec.yaml`
- `FIREBASE_ANALYTICS_WITHOUT_ADID` in `.github/workflows/ci.yaml` (and in your shell or `launchctl`)

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

- **Login & Registration:** Uses Dio to POST to `/api/login` and `/api/register` endpoints.
- **Credential Caching:** Credentials are securely cached in Hive CE using AES-256 encryption, with key derived per-device.
- **State Management:** All authentication UI and logic is managed via Riverpod notifiers and state classes.
- **Error Handling:** All network and validation errors are surfaced in the UI.
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

- Integrated tests for auth controller logic (`app/test/features/login_controller_test.dart`)
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
