# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo layout

The repo is a Dart pub workspace. The root `pubspec.yaml` is workspace-only (`publish_to: none`, `workspace:` list, Melos config under `melos:`) and holds no code. One `pubspec.lock` and one `.dart_tool/` live at the root.
- `app/`: the whole app (pubspec, `lib/`, `test/`, `assets/`, platform folders). App paths below are relative to `app/`.
- `packages/core/` (package `core`): infrastructure every app gets. It depends on nothing else in the repo. It holds `bootstrap`, per-flavor config, the Module contract, the `ErrorReporter` / `Analytics` / `RemoteFlags` interfaces and the router transition extensions; import it via `package:core/core.dart`.
- Every package has its own `test/` and an `analysis_options.yaml` that includes the root one (plus its own `exclude:` globs, since excludes resolve relative to the file that declares them).
- New packages go in `packages/` and must be added to the root `workspace:` list; each member's pubspec has `resolution: workspace`. The app depends on `core` by `path: ../packages/core`.

## Commands

Run from the repo root unless noted. Melos 7 is a root dev dependency, so call it as `dart run melos ...` (or a global `melos`).
- Install deps: `flutter pub get` (resolves every workspace member).
- Codegen in every package that uses build_runner (Riverpod, Freezed, json_serializable, Hive CE adapters): `dart run melos run gen`. While iterating in the app: `dart run build_runner watch --delete-conflicting-outputs` from `app/`. Rerun after changing any `@riverpod`, `@freezed`, `@JsonSerializable`, or `@GenerateAdapters` code. Generated `*.g.dart` / `*.freezed.dart` files are committed, so commit regenerated output alongside source changes.
- Tests in every package: `dart run melos run test`. Inside one package (`cd app` or `cd packages/core`): `flutter test`; single file: `flutter test test/features/login_controller_test.dart`; single test: add `--plain-name "successful login updates state correctly"`.
- Analyze every package (matches CI): `dart run melos run analyze` (runs `flutter analyze --no-pub --fatal-infos --fatal-warnings` and `dart analyze --fatal-infos --fatal-warnings` per package).
- Run (flavors), from `app/`: `flutter run --flavor dev -t lib/main_dev.dart` (also `staging` / `lib/main_staging.dart`, `prod` / `lib/main_prod.dart`). VS Code launch configs for all three flavors are committed in `.vscode/launch.json`.

Flutter must be `>=3.47.4` (root pubspec `environment`); CI always uses the latest stable.

CI (`.github/workflows/ci.yaml`, every PR to `main` and every push to `main`; no job needs secrets). All four jobs are meant to be required checks, but the workflow does not enforce that: a repo admin turns it on in branch protection for `main` ("Use this template" does not copy that setting). Shared setup is the composite action `.github/actions/setup` (Flutter stable with caching, `flutter pub get`, Melos at the version in the root `pubspec.lock`); each job checks out first, then uses it.
- `check`: `melos run gen`, then fails if any `*.g.dart` / `*.freezed.dart` file changed or is untracked (so always commit regenerated files), then `melos run analyze` (any lint info fails), then `melos run test` (`--coverage`; the coverage artifact never blocks). No format check.
- `build-android`, `build-ios` (`--no-codesign`), `build-web`: unsigned prod release builds from `app/` with `-t lib/main_prod.dart` (plus `--flavor prod` on Android/iOS). `build-ios` fails if `app/ios/Podfile` appears: every iOS plugin must support Swift Package Manager.
- Runner labels come from repo variables `LINUX_RUNNER` / `MACOS_RUNNER` (defaults `ubuntu-latest` / `macos-latest`). A new push to a PR cancels its older runs.
- Dependabot (`.github/dependabot.yml`) updates pub (root, `app/`, `packages/*`), GitHub Actions and Bundler weekly. New packages under `packages/` are picked up by the glob.

## Lint rules

`lint_rules.yaml` enables almost every Dart lint; the root `analysis_options.yaml` turns off the conflicting ones and adds the analyzer plugins (below) plus strict-casts/inference/raw-types. Each package includes it. In practice:
- Explicit types everywhere (`always_specify_types`): `final String x = ...`, typed collection literals (`<Locale>[...]`), typed closure params.
- Relative imports inside a package's `lib/` (`prefer_relative_imports`); other packages via `package:core/...`; app tests import via `package:flutter_riverpod_template/...`.
- Single quotes.
- No imports between Features (`no_cross_feature_imports`): a file in `lib/features/<a>/` must not import or export anything from `lib/features/<b>/`. Move shared code to Core or `lib/shared/`, or navigate through the router. Files outside a Feature folder (`lib/app/`, `test/`) may import any Feature.
- Only `lib/app/theme.dart` imports `lib/app/tokens.dart` (`tokens_only_in_theme`, also for tests and other packages). Everything else reads tokens through `Theme.of(context)` or `KonteynerTokens.of(context)`.

**Analyzer plugins.** The root `analysis_options.yaml` loads three plugins: `riverpod_lint`, `packages/konteyner_lints` (the template's architecture rules, currently `no_cross_feature_imports` and `tokens_only_in_theme`) and `packages/app_lints` (empty; an app adds its own rules there, registered in its `lib/main.dart` the same way). The two local plugins are referenced by `path:`, are not workspace members (they have their own `pubspec.lock`) and report in every package that includes the root options. Notes:
- Only `dart analyze` runs plugins; `flutter analyze` does not, so a clean `flutter analyze` alone proves nothing for plugin rules. The Melos `analyze` script runs both.
- Rule tests use `analyzer_testing` (`AnalysisRuleTest`, see `packages/konteyner_lints/test/`). Run them with `dart run melos run test:lints` (also part of `melos run test`); `melos run analyze:lints` analyzes both plugin packages (also part of `melos run analyze`).
- `analysis_server_plugin` is 0.x and pinned to an exact version, with `analyzer` pinned to the version it requires. Bump both together in both plugin packages. After changing a plugin, restart the analysis server (or rerun `dart analyze`) to pick it up.

## Local files

Gitignored and never committed: `CLAUDE.local.md`, `.claude/worktrees/`, `.claude/settings.local.json`, `graphify-out/`, `.idea/`, `*.iml`, `app/ios/Flutter/Signing.xcconfig`, and everything in `.vscode/` except `launch.json` and `extensions.json`.

## Architecture

**Entry / flavors.** Each of `app/lib/main_dev.dart` / `main_staging.dart` / `main_prod.dart` runs the app-owned `setUpApp()` (`lib/app/setup.dart`: EasyLocalization, Hive, orientation) and then calls Core's `bootstrap(<flavor>Config, app:, theme:, splash:, modules:)` with its config from `lib/app/config.dart`, the theme from `lib/app/theme.dart` and the Modules from `lib/app/modules.dart`. Bare `lib/main.dart` is dev, and the app pubspec sets `flutter: default-flavor: dev`, so a plain `flutter run` / `flutter build` never points at prod. On Android and iOS `bootstrap` throws `FlavorMismatchError` before `runApp` when the native `--flavor` differs from the entrypoint, in every build mode; elsewhere the entrypoint alone decides. No `--dart-define`: edit the configs instead. Native flavor names/IDs live in `android/gradle.properties` (`app.*` keys, read by `android/app/build.gradle.kts`) and `ios/Flutter/{Debug,Profile,Release}-<flavor>.xcconfig`; keep them in sync with Core's `Flavor { dev, staging, prod }`.

**Config.** Core's `AppConfig` holds only per-flavor values: `flavor`, `apiBaseUrl`, the demo `apiKey` and `storeLinks` (force-update store ids/links; empty means no check). Read it with `ref.watch(appConfigProvider)`; the provider throws unless `bootstrap` overrides it, so tests use `appConfigProvider.overrideWithValue(...)`. A Module's or Feature's own per-flavor values (a DSN, a second base URL) stay in that Module or Feature and are picked by `config.flavor`. Nothing compiled into the app is secret.

**Modules.** A Module implements Core's `KonteynerModule` (`name`, `platforms`, `Future<ModuleContributions> init(AppConfig config)`) and is listed in `lib/app/modules.dart`. `bootstrap` starts them in order through `startModules`: a Module is skipped on platforms outside `platforms`; a throwing `init` is logged, keeps the defaults and is reported once every Module has started; two Modules contributing the same interface stop startup with `ModuleConflictError`. Contributions become `ProviderScope` overrides of `errorReporterProvider`, `analyticsProvider` and `remoteFlagsProvider`, whose defaults are the no-op `NoopErrorReporter` / `NoopAnalytics` / `NoopRemoteFlags`. Modules never write overrides themselves.

**State management.** Riverpod 3 with code generation (`@riverpod` / `@Riverpod(keepAlive: true)` + `part '*.g.dart'`). Generated provider names are `<name>Provider` (e.g. `NetworkRepository` → `networkRepositoryProvider`). Immutable models and UI state use Freezed.

**Features** (`lib/features/<feature>/{data,domain,presentation}`):
- `domain/`: Freezed request/response models and use cases.
- `data/`: repositories. An abstract interface plus implementation exposed through a provider (e.g. `AuthenticationRepository` / `HttpAuthRepository` via `authenticationRepositoryProvider`), so tests can override them.
- `presentation/`: screens plus an async notifier controller holding a Freezed UI model (e.g. `LoginController` → `AuthUiModel`).

**Networking.** `lib/data/repository/network_repository.dart` is a keepAlive notifier whose state is the shared `Dio` (base URL and `x-api-key` from `appConfigProvider`, log + retry + memory-cache interceptors). Endpoint paths live in their Feature (e.g. the auth paths in `authentication_repository.dart`). Auth tokens are set via `networkRepositoryProvider.notifier.setToken`. The default backend is reqres.in (test credentials in README).

**Local storage.** Hive CE. Adapters are declared in `lib/hive/hive_adapters.dart` via `@GenerateAdapters([AdapterSpec<T>(), ...])`; add new persisted types there and rerun build_runner (`hive_registrar.g.dart` registers them). Boxes are opened through providers in `lib/features/authentication/data/hive/hive_box_providers.dart`; the user box is AES-encrypted with a key derived from the device ID. Access goes box provider → datasource (`local_user_ds.dart`) → `UserRepository` notifier.

**Routing.** `lib/router/app_router.dart`: `goRouterProvider` builds a `GoRouter`; routes are named by the `SGRoute` enum (`SGRoute.home.route` → `/home`). Transitions come from the `.fade()` / `.slide()` extensions on `GoRoute` in Core (`FadeGoRouteExtension` / `SlideGoRouteExtension` in `packages/core/lib/src/router/`), both exported by `package:core/core.dart`.

**Theming / i18n.** FlexColorScheme light/dark in `lib/app/theme.dart`, passed to `bootstrap` and read by `MyApp` through `konteynerThemeProvider`; theme mode persisted by `themeLogicProvider` (`lib/config/theme/`). Strings are EasyLocalization JSON in `assets/translations/{en,tr}.json`; add new locales there and to `supportedLocales` in `lib/app/setup.dart`.

**Design tokens and fonts.** `lib/app/tokens.dart` holds the hand-written raw values (scheme colors, status colors, spacing, radii, font family and type scale); only `lib/app/theme.dart` reads it. `buildAppTheme()` turns them into light and dark FlexColorScheme 9 `ThemeData` and fills Core's `KonteynerTokens` `ThemeExtension` (spacing, radii, `success` / `warning` / `info` and their on-colors) for both. Core reads it only via `KonteynerTokens.of(context)`, which falls back to `KonteynerTokens.fallbackLight` / `fallbackDark`; app-only extensions go next to it in `theme.dart`. Fonts load through google_fonts from the files bundled in `assets/fonts/` (named `<Family>-<Weight>.ttf`, e.g. `Roboto-Medium.ttf`); `buildAppTheme()` sets `GoogleFonts.config.allowRuntimeFetching = false` and registers `assets/fonts/OFL.txt` with `LicenseRegistry`. Changing the font or using a new weight means bundling its files (and license) there; `test/app/theme_test.dart` fails when a used file is missing.

## Testing pattern

Unit-test controllers with a `ProviderContainer` and `overrides` (fake repositories via `overrideWithValue` / `overrideWith(Fake.new)`), keeping autoDispose providers alive with `container.listen(...)`. See `test/features/login_controller_test.dart`.

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues (Erengun/Flutter-Riverpod-Quickstart-Template) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.
