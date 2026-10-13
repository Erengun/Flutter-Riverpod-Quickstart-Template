---
paths:
  - "widgetbook/**"
  - ".github/workflows/widgetbook.yaml"
---

# Widgetbook

- `widgetbook/` (package `widgetbook_catalog`): the web-only Widgetbook catalog (only a `web/` platform folder). It depends on the app, Core and each Module; the app never depends on it, and removing a Module removes its line from `widgetbook/pubspec.yaml` and its use cases. Use cases are `@UseCase` functions in files that mirror the widget's path (`lib/core/permission_gate.use_cases.dart`, `lib/app/features/home/presentation/home_screen.use_cases.dart`); `melos run gen` regenerates the committed `lib/main.directories.g.dart`. Addons are in `lib/catalog/catalog_addons.dart`: device frame, locale, text scale, accessibility (debug builds only: `accessibility_tools` checks nothing in release, so the Pages catalog leaves the addon out and the checks run only in a local `melos run widgetbook`), theme. The theme addon comes last because it wraps each use case in `CatalogApp` (so `Widgetbook`'s `appBuilder` passes the use case straight through; its default adds a `WidgetsApp` that throws on its first route), a material_ui `MaterialApp` (Widgetbook's shell is `flutter/material`, whose `Theme` and `ScaffoldMessenger` the app's widgets can't see) that also maps the app's unprefixed asset keys to `packages/flutter_riverpod_template/`. Screens that use Riverpod get their own root `ProviderScope` with the tests' fakes (`FakeScope` in the app's `lib/fakes/`); there is none above the catalog. Run it with `melos run widgetbook`. The root pubspec overrides `analyzer` only because `widgetbook_generator` caps it below 14; the generator's telemetry is off in `widgetbook/build.yaml`. Run, publish and removal steps are in the README's "Widgetbook" section.

`.github/workflows/widgetbook.yaml` (push to `main` and manual dispatch) builds `widgetbook/` for the web and deploys it to GitHub Pages, only when the repo variable `WIDGETBOOK_PUBLISH` is `'true'` (and Pages' source is "GitHub Actions"). PRs have no Widgetbook job: `check` already generates, analyzes and tests it, and its `*.g.dart` check covers `main.directories.g.dart`.
