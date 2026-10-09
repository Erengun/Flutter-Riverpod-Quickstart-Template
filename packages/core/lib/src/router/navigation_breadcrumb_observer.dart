import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Logs push, pop and replace of named routes to `Logger('navigation')` at
/// `INFO`, so each becomes a breadcrumb in the `navigation` category.
///
/// Only route names are recorded, never parameters, so every `GoRoute` must
/// be named. Routes without a name are skipped; go_router names its own
/// pages by path when a route has no `name`, which would leak through here.
///
/// Add one to the app's `GoRouter(observers: ...)`. An instance belongs to
/// one `Navigator`.
class NavigationBreadcrumbObserver extends NavigatorObserver {
  static final Logger _log = Logger('navigation');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record('replace', newRoute);
  }

  void _record(String action, Route<dynamic>? route) {
    final String? name = route?.settings.name;
    if (name == null) return;
    _log.info('$action $name');
  }
}
