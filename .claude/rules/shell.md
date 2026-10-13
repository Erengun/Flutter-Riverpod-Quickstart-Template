---
paths:
  - "app/lib/main*.dart"
  - "app/lib/my_app.dart"
  - "app/lib/app/config.dart"
  - "app/lib/app/modules.dart"
  - "app/lib/app/overrides.dart"
  - "app/lib/app/setup.dart"
  - "app/android/**"
  - "app/ios/**"
  - "app/macos/**"
  - "app/windows/**"
  - "app/linux/**"
  - "app/web/**"
  - "app/*.xcconfig"
  - "packages/*_module/**"
  - "packages/core/lib/src/config/**"
  - "packages/core/lib/src/modules/**"
  - "packages/core/lib/src/update/**"
---

# App shell: entry, flavors, config, Modules, force update, platforms

Optional Modules:

- `packages/firebase_module/`: optional Module (android, ios, web) contributing Firebase `Analytics` and Remote Config `RemoteFlags`; depends only on Core. Its options files in `lib/src/options/` are placeholders that throw `FirebaseNotConfiguredException` until `melos run firebase:configure:<flavor>` overwrites them; they are lint-excluded. Setup, the iOS ad-id env var and the removal checklist are in the README's "Firebase Module" section.
- `packages/sentry_module/` (package `sentry_module`): the `SentryModule` (`sentry_flutter` ^9, all six platforms). Dev never starts Sentry and contributes the no-op reporter; staging and prod start it with `environment` = flavor name, errors and crash-free statistics only (no tracing, replay, screenshots, PII, HTTP capture, Sentry logs or `debugPrint` breadcrumbs). Web gets errors but no crash-free statistics: sentry_flutter starts web sessions only from its `SentryNavigatorObserver`, which no Module contributes. One DSN constant, `sentryDsn` in `lib/src/sentry_options.dart`, ships empty; while it is empty Sentry never starts. `SentryFlutter.init` runs without `appRunner` (Core calls `runApp`), and its error integrations chain to Core's uncaught-error handlers; on web `configureSentryOptions` adds the `OnErrorIntegration` sentry_flutter leaves out there, fed by Core's `runGuarded` zone.

**Entry / flavors.** Each of `app/lib/main_dev.dart` / `main_staging.dart` / `main_prod.dart` runs the app-owned `setUpApp()` (`lib/app/setup.dart`: Hive, orientation) and then calls Core's `bootstrap(<flavor>Config, app:, theme:, splash:, modules:, overrides:)` with its config from `lib/app/config.dart`, the theme from `lib/app/theme.dart` and the Modules from `lib/app/modules.dart`. `overrides:` (optional) takes the app's own `ProviderScope` overrides from `lib/app/overrides.dart` (`buildAppOverrides()`, which overrides `sessionHooksProvider` with the auth Feature's `authSessionHooks`); it must not repeat a provider `bootstrap` already overrides (config, theme, splash, Module interfaces). Bare `lib/main.dart` is dev, and the app pubspec sets `flutter: default-flavor: dev`, so a plain `flutter run` / `flutter build` never points at prod. On Android and iOS `bootstrap` throws `FlavorMismatchError` before `runApp` when the native `--flavor` differs from the entrypoint, in every build mode; elsewhere the entrypoint alone decides. No `--dart-define`: edit the configs instead. Native flavor names/IDs live in `android/gradle.properties` (`app.*` keys, read by `android/app/build.gradle.kts`) and `ios/Flutter/{Debug,Profile,Release}-<flavor>.xcconfig` (bundle id, display name and macOS copyright come from the shared `app/Identity.xcconfig`, which every iOS and macOS flavor xcconfig includes; the flavor files add the dev/staging suffixes on iOS); keep them in sync with Core's `Flavor { dev, staging, prod }`.

**Config.** Core's `AppConfig` holds only per-flavor values: `flavor`, `apiBaseUrl`, the demo `apiKey` and `storeLinks` (force-update store ids/links; empty means no check). Read it with `ref.watch(appConfigProvider)`; the provider throws unless `bootstrap` overrides it, so tests use `appConfigProvider.overrideWithValue(...)`. A Module's or Feature's own per-flavor values (a DSN, a second base URL) stay in that Module or Feature and are picked by `config.flavor`. Nothing compiled into the app is secret.

**Modules.** A Module implements Core's `CoreModule` (`name`, `platforms`, `Future<ModuleContributions> init(AppConfig config)`) and is listed in `lib/app/modules.dart`. `bootstrap` starts them in order through `startModules`: a Module is skipped on platforms outside `platforms`; a throwing `init` is logged, keeps the defaults and is reported once every Module has started; two Modules contributing the same interface stop startup with `ModuleConflictError`. Contributions become `ProviderScope` overrides of `errorReporterProvider`, `analyticsProvider` and `remoteFlagsProvider`, whose defaults are the no-op `NoopErrorReporter` / `NoopAnalytics` / `NoopRemoteFlags`. Modules never write overrides themselves.

**Force update.** `CoreUpdateGate` sits in `MaterialApp.router`'s `builder` (in `MyApp`) with the router's navigator key. It reads `app_min_version_<platform>` / `app_recommended_version_<platform>` (`x.y.z` version names) through `appVersionSourceProvider`, which defaults to `RemoteFlags`; an app whose backend serves the versions overrides that provider. Below the minimum: a dialog with only Update that can't be dismissed. Below the recommended: Update / Ignore / Later. The dialog is Core's public `CoreUpdateDialog` (material_ui, Core's strings), which the Widgetbook catalog shows on its own since the gate never checks on web. An empty `storeLinks` entry means no check on that platform; web is never checked. Startup never waits: cached values are checked at once, `RemoteFlags.refresh()` runs in the background, and the check repeats on resume (cached values at once, then `RemoteFlags.refresh()` again) and on `RemoteFlags.onChanged`. The dialog is a route on the router's navigator: when a redirect removes it without a button tap, it is checked again, so a hard update comes back (a soft one waits its three days). Any failure lets the user in. Raise the Android minimum only after the new build is fully rolled out on Play.

**Platforms and minimum OS.** First-class: Android, iOS, web (every feature works; built on every PR). Build-only: macOS, Windows, Linux (built by `desktop.yaml`; a Module whose native SDK is missing there lists only the platforms it supports and Core skips it). The minimum OS always equals Flutter's own: Android `minSdk = flutter.minSdkVersion` tracks it by itself; iOS `IPHONEOS_DEPLOYMENT_TARGET` (15.0) and macOS `MACOSX_DEPLOYMENT_TARGET` (12.0) are set in every build configuration of `ios/Runner.xcodeproj/project.pbxproj` and `macos/Runner.xcodeproj/project.pbxproj` (macOS `Info.plist` reads the variable). When Flutter raises its minimums, raise both targets to match in every configuration and update the README's "Minimum OS" table. An app may raise a minimum, never lower it.
