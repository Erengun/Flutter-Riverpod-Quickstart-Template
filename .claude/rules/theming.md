---
paths:
  - "app/lib/app/theme.dart"
  - "app/lib/app/tokens.dart"
  - "app/lib/app/l10n.dart"
  - "**/l10n/**"
  - "**/*.arb"
  - "app/assets/fonts/**"
  - "packages/core/lib/src/theme/**"
  - "packages/core/lib/src/preferences/**"
---

# Theming, i18n and design tokens

**Theming / i18n.** FlexColorScheme light/dark in `lib/app/theme.dart`, passed to `bootstrap` and read by `MyApp` through `coreThemeProvider`. Core's `themeModeProvider` (system/light/dark) and `localeProvider` (`null` = follow the device) are saved in the unencrypted Hive `prefs` box (`prefsBoxName`, opened by `initHive`; tests override `prefsBoxProvider`); `MyApp` passes them to `MaterialApp`, and the home screen's theme and language tiles set them.

Strings use Flutter's gen-l10n, one translation set per package: the app's `lib/l10n/app_<locale>.arb` → `AppLocalizations` (all Features share it), Core's `packages/core/lib/l10n/core_<locale>.arb` → `CoreLocalizations` (error messages, session expired, Remember me, no-permission / under-construction pages, update dialog). Each package has `generate: true`, its own `l10n.yaml`, `flutter_localizations` and `intl: any`. Rules:
- ARB key order: `@@locale` first, then keys sorted by name, each `@key` metadata block right after its key. `test/l10n/arb_order_test.dart` checks every `*.arb` in the repo.
- Every app key starts with its Feature's name (`homeIntro`, `authLoginTitle`); `appTitle` is the app title (`MaterialApp.onGenerateTitle`). Add `@key` metadata only for placeholders or translator notes.
- English is the template and fallback. A new locale needs an ARB file in every package with strings (a missing key falls back to English, a missing file makes that package's delegate unsupported); `AppLocalizations.supportedLocales` is the only locale list, and iOS also lists locales in `CFBundleLocalizations` (`ios/Runner/Info.plist`).
- One delegate list, `appLocalizationsDelegates` in `lib/app/l10n.dart`, feeds `MaterialApp` and the tests: the app's delegates, `CoreLocalizations.delegate`, material_ui's `GlobalMaterialLocalizations.delegates`, plus one line per Module with strings.
- To change Core's wording, edit `packages/core/lib/l10n/*.arb` directly; there is no override mechanism. Code without a `BuildContext` uses `lookupCoreLocalizations(locale)`.
- On a merge conflict in generated l10n Dart, take either side and rerun `flutter pub get`.

**Design tokens and fonts.** `lib/app/tokens.dart` holds the hand-written raw values (scheme colors, status colors, spacing, radii, font family and type scale); only `lib/app/theme.dart` reads it. `buildAppTheme()` turns them into light and dark FlexColorScheme 9 `ThemeData` and fills Core's `CoreTokens` `ThemeExtension` (spacing, radii, `success` / `warning` / `info` and their on-colors) for both. Core reads it only via `CoreTokens.of(context)`, which falls back to `CoreTokens.fallbackLight` / `fallbackDark`; app-only extensions go next to it in `theme.dart`. Core screens never hardcode colors or fonts: Core's widgets use no literal color, size or font (no `Colors.x`, `Color(0x...)`, `TextStyle(fontSize: ...)`, numeric `EdgeInsets` / `SizedBox` / radius) and read only `Theme.of(context)` and `CoreTokens.of(context)`; anything Material has no slot for becomes a field on `CoreTokens` (with a fallback), not a literal. No lint checks this. Fonts load through google_fonts from the files bundled in `assets/fonts/` (named `<Family>-<Weight>.ttf`, e.g. `Roboto-Medium.ttf`); `buildAppTheme()` sets `GoogleFonts.config.allowRuntimeFetching = false` and registers `assets/fonts/OFL.txt` with `LicenseRegistry`. Changing the font or using a new weight means bundling its files (and license) there; `test/app/theme_test.dart` fails when a used file is missing.
