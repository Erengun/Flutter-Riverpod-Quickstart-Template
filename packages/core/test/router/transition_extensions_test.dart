import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRoute buildRoute() => GoRoute(
    path: '/home',
    builder: (BuildContext context, GoRouterState state) =>
        const SizedBox.shrink(),
  );

  Future<Page<Object?>> pumpRoute(WidgetTester tester, GoRoute route) async {
    Page<Object?>? page;
    final GoRouter router = GoRouter(
      initialLocation: route.path,
      routes: <RouteBase>[
        GoRoute(
          path: route.path,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Page<Object?> built = route.pageBuilder!(context, state);
            page = built;
            return built;
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)),
    );
    return page!;
  }

  testWidgets('fade keeps the path and builds a FadeTransitionPage', (
    WidgetTester tester,
  ) async {
    final GoRoute route = buildRoute().fade();

    expect(route.path, '/home');
    final Page<Object?> page = await pumpRoute(tester, route);
    expect(page, isA<FadeTransitionPage>());
    expect(page.key, const ValueKey<String>('/home'));
    expect(find.byType(FadeTransition), findsWidgets);
  });

  testWidgets('slide keeps the path and builds a SlideTransitionPage', (
    WidgetTester tester,
  ) async {
    final GoRoute route = buildRoute().slide();

    expect(route.path, '/home');
    final Page<Object?> page = await pumpRoute(tester, route);
    expect(page, isA<SlideTransitionPage>());
    expect(page.key, const ValueKey<String>('/home'));
    expect(find.byType(SlideTransition), findsWidgets);
  });

  test('fade and slide keep the route name', () {
    GoRoute named() => GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const SizedBox.shrink(),
    );

    expect(named().fade().name, 'home');
    expect(named().slide().name, 'home');
  });

  testWidgets('fade and slide can be used in the same file', (
    WidgetTester tester,
  ) async {
    expect(buildRoute().fade().pageBuilder, isNotNull);
    expect(buildRoute().slide().pageBuilder, isNotNull);
  });
}
