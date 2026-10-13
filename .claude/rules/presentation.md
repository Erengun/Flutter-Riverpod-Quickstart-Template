---
paths:
  - "app/lib/features/*/presentation/**"
  - "app/lib/shared/widgets/**"
  - "widgetbook/lib/**"
---

# Presentation

A UI file is any file under `app/lib/features/<feature>/presentation/` or `app/lib/shared/widgets/` except `*_controller.dart`, `*_ui_model.dart` and generated files (`*.g.dart`, `*.freezed.dart`). UI files belong to the Designer; controllers and UI models belong to developers.

## UI files

- Draw from the controller's UI model and Core's providers. Never import `data/` or read a repository, `dioProvider`, `apiCallProvider`, the Dio interceptors or `sessionBoxProvider`.
- No `setState`. A `StatefulWidget` only owns a `TextEditingController`, `FocusNode` or `AnimationController`; any other state lives in a provider. No flutter_hooks.
- Split a widget into widget classes, not functions or helper methods that return a `Widget`. `@UseCase` builders in `widgetbook/` are functions by design.
- No `shrinkWrap: true`. Lists of unknown length use `ListView.builder` or slivers, not `.map()` or `for` into `children:`.
- Colors, spacing, radii and text styles come from `Theme.of(context)` and `CoreTokens.of(context)`; strings from `AppLocalizations`. No literal colors or font sizes.
- API errors: `ref.listenApiErrors(provider, context)` for a snackbar, `ApiErrorView` when the screen's main data failed. Gate controls with `PermissionGate`.
- Name a screen `<name>_screen.dart`. A widget several Features use goes in `app/lib/shared/widgets/`; one every app needs goes to Core.
- A use case renders on Fakes alone: `FakeScope(child: TheScreen())`.

## Controllers and UI models

- A screen's controller is an `@riverpod` async notifier in a `*_controller.dart` next to the screen; its state is a Freezed UI model in a `*_ui_model.dart`.
- Controllers call repositories through their providers. There are no use-case classes.
- Let failures reach the screen as `AsyncError`; don't catch an `ApiException` just to show it.
