---
paths:
  - "**/test/**"
  - "**/fakes/**"
---

# Testing

- Controllers: a `ProviderContainer` with `overrides`, keeping autoDispose providers alive with `container.listen(...)`; see `login_controller_test.dart`.
- Storage: app tests get in-memory `prefs`, `session` and `credentials` boxes from `test/support/storage.dart` (`TestStorage.open()`, then `...storage.overrides`). HTTP: swap `dio.httpClientAdapter` for a fake adapter (`packages/core/test/support/fake_http_adapter.dart`) and pass `retryDelays: const <Duration>[]` to `createDio`.
- `test/app/session_flow_test.dart` drives the real router through restart, redirect and logout.
- Riverpod 3 retries failing providers; a test that needs the error state passes `retry: (int retryCount, Object error) => null` to its `ProviderContainer` or `ProviderScope`.
- Logging: `configureLogging(..., printer: records.add)` captures records; `resetLogging()` in `tearDown`. A test that runs `bootstrap` restores `FlutterError.onError` and `PlatformDispatcher.instance.onError` inside the test body.
- Run from the member's folder: `flutter test`, one file `flutter test <path>`, one test `--plain-name "<name>"`. Lint rule tests: `dart run melos run test:lints`.
- Tests written from requirements (a new feature, a bug reproduction) can go to the `test-writer` agent.
