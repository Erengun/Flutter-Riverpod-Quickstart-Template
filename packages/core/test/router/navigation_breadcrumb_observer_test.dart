import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../support/recording_reporter.dart';

PageRouteBuilder<void> _route(String? name) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name),
  pageBuilder: (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox.shrink(),
);

void main() {
  late RecordingReporter reporter;

  setUp(() {
    reporter = RecordingReporter();
    configureLogging(
      LogPolicy.forFlavor(Flavor.prod),
      reporter: reporter,
      printer: (LogRecord record) {},
    );
  });

  tearDown(resetLogging);

  List<String> navigationCrumbs() => reporter.breadcrumbs
      .where((RecordedBreadcrumb b) => b.category == 'navigation')
      .map((RecordedBreadcrumb b) => b.message)
      .toList();

  test('push, pop and replace of named routes become breadcrumbs', () {
    final NavigationBreadcrumbObserver observer =
        NavigationBreadcrumbObserver();
    final PageRouteBuilder<void> login = _route('login');
    final PageRouteBuilder<void> home = _route('home');
    final PageRouteBuilder<void> profile = _route('profile');

    observer
      ..didPush(login, null)
      ..didReplace(newRoute: home, oldRoute: login)
      ..didPush(profile, home)
      ..didPop(profile, home);

    expect(navigationCrumbs(), <String>[
      'push login',
      'replace home',
      'push profile',
      'pop profile',
    ]);
  });

  test('unnamed routes are skipped', () {
    NavigationBreadcrumbObserver()
      ..didPush(_route(null), null)
      ..didPop(_route(null), null);

    expect(navigationCrumbs(), isEmpty);
  });

  testWidgets('go_router pages carry the route name, never parameters', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/orders/42',
      observers: <NavigatorObserver>[NavigationBreadcrumbObserver()],
      routes: <RouteBase>[
        GoRoute(
          path: '/orders/:id',
          name: 'order',
          builder: (BuildContext context, GoRouterState state) =>
              const SizedBox.shrink(),
        ).fade(),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)),
    );

    expect(navigationCrumbs(), <String>['push order']);
  });

  testWidgets('slide pages carry the route name too', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/orders/42',
      observers: <NavigatorObserver>[NavigationBreadcrumbObserver()],
      routes: <RouteBase>[
        GoRoute(
          path: '/orders/:id',
          name: 'order',
          builder: (BuildContext context, GoRouterState state) =>
              const SizedBox.shrink(),
        ).slide(),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)),
    );

    expect(navigationCrumbs(), <String>['push order']);
  });
}
