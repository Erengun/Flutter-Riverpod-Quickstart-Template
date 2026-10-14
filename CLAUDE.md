# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working style

- Before coding, state your assumptions. When a request reads more than one way, or a simpler approach exists, say so and ask; don't pick silently.
- Write the least code that solves the problem: no features, abstractions, options or error handling nobody asked for.
- Touch only what the task needs and match the surrounding style; don't reformat or refactor neighbouring code. Remove what your change left unused; mention other dead code, don't delete it.
- Turn the task into a check you can run (a failing test, an analyzer run) and loop until it passes. For multi-step work, state a short plan with a check per step.

## Always

- Tests come first for new features and bug fixes; a bug fix starts with a test that reproduces it and fails.
- Tests check the intended behavior, not what the code happens to do. Never weaken, skip or delete a failing test to get green: fix the code, or ask.
- Run the tests you touched, then `dart run melos run test`, before calling the work done.
- Fake only at boundaries (repositories, storage, the HTTP adapter). Fakes are hand-written; no mocks.
- No `setState` in app code (`features/`, `shared/`); state lives in Riverpod.
- Never navigate home after login or to login after logout; changing the Session is enough.
- Record an exception with `ref.read(errorReporterProvider).report(error, stackTrace)`, not `log.warning`. Never log headers, bodies, tokens, passwords or personal data.
- Every `GoRoute` sets `name:`.
- No imports between Features. Only `lib/app/theme.dart` imports `lib/app/tokens.dart`. Only `test/`, `widgetbook/` and other `fakes/` folders import from a `fakes/` folder.
- Before writing a new screen, Shared widget, use case or test, read an existing one of the same kind.
- When the Dart MCP server is connected, prefer its tools (analyze, pub, hot reload, runtime errors) over the CLI; the CLI is fine otherwise.

## Rules by area

The detailed rules live in `.claude/rules/` and load when you read or edit a file their `paths:` match: `presentation.md` (screens, Shared widgets, the catalog), `theming.md`, `networking.md`, `session-permissions.md`, `routing.md`, `logging.md`, `shell.md` (entry, flavors, config, Modules, force update, platforms), `widgetbook.md`, `ci-release.md`, `lint-plugins.md` and `testing.md`. A new file loads nothing until it exists, so read a neighbouring file of the same kind first.

## Repo layout

The repo is a Dart pub workspace. The root `pubspec.yaml` is workspace-only (`publish_to: none`, `workspace:` list, Melos config under `melos:`) and holds no code. One `pubspec.lock` and one `.dart_tool/` live at the root.
- `app/`: the whole app (pubspec, `lib/`, `test/`, `assets/`, platform folders). App paths below are relative to `app/`.
- `packages/core/` (package `core`): infrastructure every app gets. It depends on nothing else in the repo. It holds `bootstrap`, per-flavor config, the network layer (shared Dio, `ApiException`, `apiCall`), the session layer (encrypted Hive boxes, `Session`, the auth interceptor, the router redirect), permissions (`Permissions`, loading and reloading, the route guard, `PermissionGate`, the menu filter, the no-permission and under-construction pages), the Module contract, the `ErrorReporter` / `Analytics` / `RemoteFlags` interfaces, logging and error-report dispatch, and the router transition extensions and navigation observer; import it via `package:core/core.dart`.
- `packages/firebase_module/` and `packages/sentry_module/`: the optional Modules (Firebase `Analytics` and Remote Config `RemoteFlags`; Sentry errors and crash-free statistics). Details in `.claude/rules/shell.md`; setup and removal in the README.
- `packages/app_lints/`: the analyzer plugin with the template's architecture rules and the app's own (`.claude/rules/lint-plugins.md`).
- `widgetbook/` (package `widgetbook_catalog`): the web-only Widgetbook catalog; the app never depends on it. Run it with `dart run melos run widgetbook` (`.claude/rules/widgetbook.md`).
- Every workspace member has its own `test/` and an `analysis_options.yaml` that includes the root one (plus its own `exclude:` globs, since excludes resolve relative to the file that declares them).
- New packages go in `packages/` and must be added to the root `workspace:` list; each member's pubspec has `resolution: workspace`. The app depends on `core` by `path: ../packages/core`.
- The README is the human guide: "Create a new app" is the app-creation checklist, and "Remove a Module" (plus each Module's own extras), "Remove Widgetbook" and "Minimum OS" live there. When a change adds a setup step (a placeholder, secret, variable or repo setting) or a new place a Module or Widgetbook touches, update those lists in the same change.

## Commands

Run from the repo root unless noted. Melos 7 is a root dev dependency, so call it as `dart run melos ...` (or a global `melos`).
- Install deps: `flutter pub get` (resolves every workspace member and runs gen-l10n in every package with an `l10n.yaml`, regenerating `lib/l10n/*_localizations*.dart`; commit them). Inside one package, `flutter gen-l10n` does the same.
- Codegen in every package that uses build_runner (Riverpod, Freezed, json_serializable, retrofit clients, Hive CE adapters; Core too, for `BaseResponse`): `dart run melos run gen`. While iterating in the app: `dart run build_runner watch --delete-conflicting-outputs` from `app/`. Rerun after changing any `@riverpod`, `@freezed`, `@JsonSerializable`, or `@GenerateAdapters` code. Generated `*.g.dart` / `*.freezed.dart` files are committed, so commit regenerated output alongside source changes.
- Tests in every package: `dart run melos run test`. Inside one package (`cd app` or `cd packages/core`): `flutter test`; single file: `flutter test test/features/login_controller_test.dart`; single test: add `--plain-name "successful login updates state correctly"`.
- Regenerate `DESIGN.md`'s frontmatter from the theme after changing a token: `dart run melos run design:update` (runs `test/conventions/design_md_test.dart` with `--update-goldens` from `app/`; without the flag that test fails when the frontmatter is stale).
- Analyze every package (matches CI): `dart run melos run analyze` (runs `flutter analyze --no-pub --fatal-infos --fatal-warnings` and `dart analyze --fatal-infos --fatal-warnings` per package).
- Run (flavors), from `app/`: `flutter run --flavor dev -t lib/main_dev.dart` (also `staging` / `lib/main_staging.dart`, `prod` / `lib/main_prod.dart`). VS Code launch configs for all three flavors are committed in `.vscode/launch.json`.

Flutter must be `>=3.47.4` (root pubspec `environment`); CI always uses the latest stable.

Five workflows in `.github/workflows/` (`ci.yaml`, `desktop.yaml`, `widgetbook.yaml`, `widgetbook-preview.yaml`, `release.yaml`); none needs a secret until a repo turns on releases or per-PR previews. Details in `.claude/rules/ci-release.md` and `.claude/rules/widgetbook.md`.

## Lint rules

`lint_rules.yaml` enables almost every Dart lint; the root `analysis_options.yaml` turns off the conflicting ones and adds the analyzer plugins (below) plus strict-casts/inference/raw-types. Each package includes it. In practice:
- Explicit types everywhere (`always_specify_types`): `final String x = ...`, typed collection literals (`<Locale>[...]`), typed closure params.
- Relative imports inside a package's `lib/` (`prefer_relative_imports`); other packages via `package:core/...`; app tests import via `package:flutter_riverpod_template/...`.
- Single quotes.
- No imports between Features (`no_cross_feature_imports`): a file in `lib/features/<a>/` must not import or export anything from `lib/features/<b>/`. Move shared code to Core or `lib/shared/`, or navigate through the router. Files outside a Feature folder (`lib/app/`, `test/`) may import any Feature.
- Only `lib/app/theme.dart` imports `lib/app/tokens.dart` (`tokens_only_in_theme`, also for tests and other packages). Everything else reads tokens through `Theme.of(context)` or `CoreTokens.of(context)`.

The template's rules (`no_cross_feature_imports`, `tokens_only_in_theme`, `no_set_state`, `no_shrink_wrap`, `no_widget_functions`) come from the `packages/app_lints` analyzer plugin. Only `dart analyze` runs plugins; `flutter analyze` does not, so a clean `flutter analyze` alone proves nothing for them. The Melos `analyze` script runs both.

## Local files

Gitignored and never committed: `CLAUDE.local.md`, `.claude/worktrees/`, `.claude/settings.local.json`, `graphify-out/`, `.idea/`, `*.iml`, `app/ios/Flutter/Signing.xcconfig`, `app/macos/Runner/Configs/Signing.xcconfig`, `app/android/key.properties`, signing material (`*.jks`, `*.keystore`, `*.p8`, `*.p12`, service-account JSON), fastlane output (`report.xml`, its generated `README.md`, `*.aab`, `*.ipa`, ...), and everything in `.vscode/` except `launch.json` and `extensions.json`.

`.claude/settings.json` is committed: it registers the dart-flutter and impeccable plugin marketplaces and turns on only `dart-flutter@dart-flutter`. Keep it free of machine paths, credentials and personal permissions; those go in the gitignored `.claude/settings.local.json`.

## Architecture

**State management.** Riverpod 3 with code generation (`@riverpod` / `@Riverpod(keepAlive: true)` + `part '*.g.dart'`). Generated provider names are `<name>Provider` (e.g. `authenticationRepository` → `authenticationRepositoryProvider`). Immutable models and UI state use Freezed.

**Features** (`lib/features/<feature>/{data,domain,presentation}`):
- `domain/`: Freezed request/response models only; may be empty. There are no use-case classes: controllers call repositories.
- `data/`: repositories. An abstract interface plus implementation exposed through a provider (e.g. `AuthenticationRepository` / `HttpAuthRepository` via `authenticationRepositoryProvider`), so tests can override them.
- `presentation/`: screens plus an async notifier controller holding a Freezed UI model (e.g. `LoginController` → `AuthUiModel`).

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues (Erengun/Flutter-Riverpod-Quickstart-Template) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.

### Code graph (graphify)

`graphify-out/` is gitignored and built locally. When `graphify-out/graph.json` is missing or stale (fresh clone, new worktree, after a pull or branch switch, after code edits), run `graphify update .` from the repo root: a code-only rebuild of about a second, no API key. Use that CLI command, not the skill's `--update` path (it runs LLM extraction). Never commit `graphify-out/`, the `.gitattributes` line `graphify hook install` adds, or what `graphify claude install` writes (a CLAUDE.md section, and a hook in `.claude/settings.json` that holds a machine-specific path); this rule replaces them.

Before reading many files to find where something lives or how it connects, ask the graph: `graphify query "<question>"` for a question about the code, `graphify path "A" "B"` for how two symbols connect, `graphify explain "X"` for one symbol and its neighbours.
