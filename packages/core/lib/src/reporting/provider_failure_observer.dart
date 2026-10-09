import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';

import '../network/api_exception.dart';
import 'error_reporter.dart';

/// Reports failed providers through [ErrorReporter]. `bootstrap` adds it to
/// the `ProviderScope`.
///
/// It sees errors thrown in a provider's `build` and `AsyncError` states a
/// notifier sets (including through `AsyncValue.guard`). Errors a notifier
/// keeps in its own UI model never reach it; report those explicitly.
///
/// - Each provider is reported once per launch, non-fatal, tagged with its
///   name. Riverpod retries a failed provider and every attempt fails again,
///   so repeats become breadcrumbs.
/// - [ApiException]s are skipped: the network layer already reported them
///   or recorded them as breadcrumbs.
final class ProviderFailureObserver extends ProviderObserver {
  ProviderFailureObserver(this._reporter);

  static final Logger _log = Logger('provider');

  final ErrorReporter _reporter;
  final Set<ProviderBase<Object?>> _reported = <ProviderBase<Object?>>{};

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is ApiException) return;
    final ProviderBase<Object?> provider = context.provider;
    final String name = provider.name ?? provider.runtimeType.toString();
    if (_reported.add(provider)) {
      _reporter.report(
        error,
        stackTrace,
        tags: <String, String>{'provider': name},
      );
    } else {
      _log.warning('$name failed again (${error.runtimeType}).');
    }
  }
}
