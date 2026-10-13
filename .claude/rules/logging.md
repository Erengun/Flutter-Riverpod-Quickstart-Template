---
paths:
  - "packages/core/lib/src/logging/**"
  - "packages/core/lib/src/reporting/**"
  - "packages/core/lib/src/bootstrap/**"
  - "packages/sentry_module/**"
---

# Logging and error reporting

**Logging and error reporting.** Three channels: a log (developer line), a breadcrumb (short note attached to the next report) and an error report (sent through `ErrorReporter.report`).
- Log through named loggers from the `logging` package, one per Feature or area: `static final Logger _log = Logger('auth');`. Nothing wraps `logging`; `bootstrap` attaches the only root-logger listener (`configureLogging` in `packages/core/lib/src/logging/log_setup.dart`). Outside Core's console printer, never use `print`, `debugPrint` or `dart:developer` `log`.
- Levels per flavor (`LogPolicy.forFlavor`): dev keeps `ALL` and prints, staging keeps `INFO` (plus `FINE` for `Logger('network')`, through `LogPolicy.loggerLevels`, which turns on `hierarchicalLoggingEnabled`) and prints, prod keeps `INFO` with no console. The console printer writes through `debugPrint`, which `bootstrap` silences only in prod release builds.
- Kept records at `INFO` and above become breadcrumbs (category = logger name). A record carrying an error never does. Feature and app code logs; it never calls `addBreadcrumb` directly (Core infrastructure that needs structured `data` may).
- Never log headers, bodies, query values, tokens, passwords or personal data: every log line may reach the error tracker.
- To record an exception, call `ref.read(errorReporterProvider).report(error, stackTrace)`, not `log.warning(msg, error)`. A log record with an error attached is Core's own echo of a report or an uncaught error.
- `errorReporterProvider` is Core's `ReportDispatcher`: every `report` is first logged at `SEVERE`, then sent to the Module's reporter. Until every Module has started, reports are buffered and breadcrumbs dropped.
- `bootstrap` installs log-only `FlutterError.onError` / `PlatformDispatcher.onError` before Modules start (an error-tracker Module chains to them; Core never reports uncaught errors), and each `main_<flavor>.dart` wraps its body in `runGuarded`: on web, whose engine never calls `PlatformDispatcher.onError`, it runs the body (binding init included) in a zone that forwards uncaught async errors to that handler; elsewhere it adds no zone. `bootstrap` also adds `ProviderFailureObserver` to the `ProviderScope`: a failed provider (thrown in `build` or an `AsyncError` state) is reported once per provider per launch, repeats become breadcrumbs, and `ApiException` (Core's marker for errors the network layer already handled) and Riverpod's `ProviderException` (a dependent rethrowing a watched provider's failure, which the source reports) are skipped. Errors handled without failing a provider need an explicit `report`.
- Tests: `configureLogging(..., printer: records.add)` captures records; call `resetLogging()` in `tearDown`. A test that runs `bootstrap` must restore `FlutterError.onError` and `PlatformDispatcher.instance.onError` inside the test body (see `packages/core/test/bootstrap/bootstrap_test.dart`).
