# Contributing

Thanks for helping improve the Flutter Riverpod Quickstart Template. Report bugs and suggest features through [GitHub issues](../../issues), and follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Set up

1. Install Flutter 3.47.4 or newer (CI uses the latest stable).
2. Fork and clone the repo, then from its root:
    ```bash
    flutter pub get
    dart run melos run gen
    ```
3. Run the app from `app/`: `flutter run --flavor dev -t lib/main_dev.dart`.

## Before you open a pull request

- Branch from `main` and keep each pull request to one change.
- Write the tests first for a new feature or a bug fix; a fix starts with a test that fails without it.
- A new screen or Shared widget needs a widget test and a Widgetbook use case at its mirrored paths (`app/test/...` and `widgetbook/lib/app/...`); CI checks both.
- Run what CI runs, from the repo root: `dart run melos run analyze` (any lint info fails) and `dart run melos run test`.
- Commit generated files (`*.g.dart`, `*.freezed.dart`, the generated localizations) with the source that produced them. CI fails when they are out of date.
- A pull request from a fork gets no hosted catalog preview; reviewers check its Widgetbook catalog with a local `dart run melos run widgetbook`.
- When your change adds a setup step, or a new place a Module or Widgetbook touches, update the README's checklists in the same pull request.

## Where the rules live

The rules the code follows are not repeated here. [CLAUDE.md](CLAUDE.md) and the per-area files in [`.claude/rules/`](.claude/rules) are written for Claude Code and for people alike; read the file for the area you change. [CONTEXT.md](CONTEXT.md) is the project's vocabulary: use its terms in code, issues and pull requests.
