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
- 🌍 Internationalization ready with Easy Localization
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

- Android flavor names and applicationId suffixes: [app/android/app/build.gradle.kts](app/android/app/build.gradle.kts)
- iOS bundle IDs and display names: [app/ios/Flutter/Debug-dev.xcconfig](app/ios/Flutter/Debug-dev.xcconfig) (and the other flavor xcconfig files)
- Dart-side flavor labels: [app/lib/flavors/app_flavor.dart](app/lib/flavors/app_flavor.dart)

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
