# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Install deps: `flutter pub get`
- Codegen (Riverpod, Freezed, json_serializable, Hive CE adapters): `dart run build_runner build --delete-conflicting-outputs` (use `watch` instead of `build` while iterating). Rerun after changing any `@riverpod`, `@freezed`, `@JsonSerializable`, or `@GenerateAdapters` code. Generated `*.g.dart` / `*.freezed.dart` files are committed, so commit regenerated output alongside source changes.
- Run (flavors): `flutter run --flavor dev -t lib/main_dev.dart` (also `staging` / `lib/main_staging.dart`, `prod` / `lib/main_prod.dart`)
- Tests: `flutter test`; single file: `flutter test test/features/login_controller_test.dart`; single test: add `--plain-name "successful login updates state correctly"`
- Analyze (matches CI): `flutter analyze --no-pub --fatal-infos --fatal-warnings`

CI (`.github/workflows/lint.yaml`) runs pub get → build_runner → `flutter test` → analyze with fatal infos/warnings, so any lint info fails the build.

## Lint rules

`lint_rules.yaml` enables almost every Dart lint; `analysis_options.yaml` turns off the conflicting ones and adds `riverpod_lint` plus strict-casts/inference/raw-types. In practice:
- Explicit types everywhere (`always_specify_types`): `final String x = ...`, typed collection literals (`<Locale>[...]`), typed closure params.
- Relative imports inside `lib/` (`prefer_relative_imports`); tests import via `package:flutter_riverpod_template/...`.
- Single quotes.

## Architecture

**Entry / flavors.** `main_dev.dart` / `main_staging.dart` / `main_prod.dart` call `FlavorConfig.setFlavor(...)` (`lib/flavors/app_flavor.dart`) then `bootstrap()` in `lib/main.dart`, which initializes EasyLocalization, Hive (`lib/hive/hive.dart`), orientation, and wraps `MyApp` in `ProviderScope` + `EasyLocalization`. Native flavor names/IDs live in `android/app/build.gradle.kts` and `ios/Flutter/{Debug,Profile,Release}-<flavor>.xcconfig`; keep them in sync with `FlavorConfig`.

**State management.** Riverpod 3 with code generation (`@riverpod` / `@Riverpod(keepAlive: true)` + `part '*.g.dart'`). Generated provider names are `<name>Provider` (e.g. `NetworkRepository` → `networkRepositoryProvider`). Immutable models and UI state use Freezed.

**Features** (`lib/features/<feature>/{data,domain,presentation}`):
- `domain/`: Freezed request/response models and use cases.
- `data/`: repositories. An abstract interface plus implementation exposed through a provider (e.g. `AuthenticationRepository` / `HttpAuthRepository` via `authenticationRepositoryProvider`), so tests can override them.
- `presentation/`: screens plus an async notifier controller holding a Freezed UI model (e.g. `LoginController` → `AuthUiModel`).

**Networking.** `lib/data/repository/network_repository.dart` is a keepAlive notifier whose state is the shared `Dio` (base URL/API key from `lib/constants/endpoints.dart`, log + retry + memory-cache interceptors). Auth tokens are set via `networkRepositoryProvider.notifier.setToken`. The default backend is reqres.in (test credentials in README).

**Local storage.** Hive CE. Adapters are declared in `lib/hive/hive_adapters.dart` via `@GenerateAdapters([AdapterSpec<T>(), ...])`; add new persisted types there and rerun build_runner (`hive_registrar.g.dart` registers them). Boxes are opened through providers in `lib/features/authentication/data/hive/hive_box_providers.dart`; the user box is AES-encrypted with a key derived from the device ID. Access goes box provider → datasource (`local_user_ds.dart`) → `UserRepository` notifier.

**Routing.** `lib/router/app_router.dart`: `goRouterProvider` builds a `GoRouter`; routes are named by the `SGRoute` enum (`SGRoute.home.route` → `/home`). Transitions come from `.fade()` / `.slide()` extensions on `GoRoute` (`fade_extension.dart`, `slide_extension.dart`). Both extensions are named `GoRouteExtension`, so import only one per file.

**Theming / i18n.** FlexColorScheme light/dark in `lib/my_app.dart`; theme mode persisted by `themeLogicProvider` (`lib/config/theme/`). Strings are EasyLocalization JSON in `assets/translations/{en,tr}.json`; add new locales there and to `supportedLocales` in `lib/main.dart`.

## Testing pattern

Unit-test controllers with a `ProviderContainer` and `overrides` (fake repositories via `overrideWithValue` / `overrideWith(Fake.new)`), keeping autoDispose providers alive with `container.listen(...)`. See `test/features/login_controller_test.dart`.

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues (Erengun/Flutter-Riverpod-Quickstart-Template) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.
