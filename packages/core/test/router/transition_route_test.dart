import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

typedef Transition = GoRoute Function(GoRoute route);

final Map<String, Transition> transitions = <String, Transition>{
  'fade': (GoRoute route) => route.fade(),
  'slide': (GoRoute route) => route.slide(),
};

Widget label(String text) => Text(text, textDirection: TextDirection.ltr);

Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required String initialLocation,
  required List<RouteBase> routes,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: routes,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  GoRoute buildRoute() => GoRoute(
    path: '/home',
    builder: (BuildContext context, GoRouterState state) =>
        const SizedBox.shrink(),
  );

  Future<Page<Object?>> pumpRoute(WidgetTester tester, GoRoute route) async {
    Page<Object?>? page;
    ValueKey<String>? pageKey;
    await pumpRouter(
      tester,
      initialLocation: route.path,
      routes: <RouteBase>[
        GoRoute(
          path: route.path,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Page<Object?> built = route.pageBuilder!(context, state);
            page = built;
            pageKey = state.pageKey;
            return built;
          },
        ),
      ],
    );
    expect(page!.key, pageKey);
    return page!;
  }

  testWidgets('fade keeps the path and builds a FadeTransitionPage', (
    WidgetTester tester,
  ) async {
    final GoRoute route = buildRoute().fade();

    expect(route.path, '/home');
    final Page<Object?> page = await pumpRoute(tester, route);
    expect(page, isA<FadeTransitionPage>());
  });

  testWidgets('slide keeps the path and builds a SlideTransitionPage', (
    WidgetTester tester,
  ) async {
    final GoRoute route = buildRoute().slide();

    expect(route.path, '/home');
    final Page<Object?> page = await pumpRoute(tester, route);
    expect(page, isA<SlideTransitionPage>());
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

  for (final MapEntry<String, Transition> entry in transitions.entries) {
    final String kind = entry.key;
    final Transition transition = entry.value;

    group(kind, () {
      testWidgets('gives each pushed location its own page', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpRouter(
          tester,
          initialLocation: '/item/1',
          routes: <RouteBase>[
            transition(
              GoRoute(
                path: '/item/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    label('item ${state.pathParameters['id']}'),
              ),
            ),
          ],
        );
        expect(find.text('item 1'), findsOneWidget);

        unawaited(router.push('/item/2'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('item 2'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();

        expect(find.text('item 1'), findsOneWidget);
        expect(find.text('item 2'), findsNothing);
      });

      testWidgets('keeps the sub-routes', (WidgetTester tester) async {
        final GoRouter router = await pumpRouter(
          tester,
          initialLocation: '/a',
          routes: <RouteBase>[
            transition(
              GoRoute(
                path: '/a',
                builder: (BuildContext context, GoRouterState state) =>
                    label('a'),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'b',
                    builder: (BuildContext context, GoRouterState state) =>
                        label('b'),
                  ),
                ],
              ),
            ),
          ],
        );
        expect(find.text('a'), findsOneWidget);

        router.go('/a/b');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('b'), findsOneWidget);
      });

      testWidgets('keeps the route redirect', (WidgetTester tester) async {
        await pumpRouter(
          tester,
          initialLocation: '/old',
          routes: <RouteBase>[
            transition(
              GoRoute(
                path: '/old',
                builder: (BuildContext context, GoRouterState state) =>
                    label('old'),
                redirect: (BuildContext context, GoRouterState state) => '/new',
              ),
            ),
            GoRoute(
              path: '/new',
              builder: (BuildContext context, GoRouterState state) =>
                  label('new'),
            ),
          ],
        );

        expect(find.text('new'), findsOneWidget);
        expect(find.text('old'), findsNothing);
      });

      test('keeps every other GoRoute field', () {
        final GlobalKey<NavigatorState> navigatorKey =
            GlobalKey<NavigatorState>();
        String? redirect(BuildContext context, GoRouterState state) => null;
        Future<bool> onExit(BuildContext context, GoRouterState state) async =>
            true;
        final Map<String, dynamic> metadata = <String, dynamic>{'k': 'v'};
        final List<RouteBase> children = <RouteBase>[
          GoRoute(
            path: 'child',
            builder: (BuildContext context, GoRouterState state) =>
                const SizedBox.shrink(),
          ),
        ];
        final GoRoute source = GoRoute(
          path: '/Case',
          name: 'case',
          builder: (BuildContext context, GoRouterState state) =>
              const SizedBox.shrink(),
          parentNavigatorKey: navigatorKey,
          redirect: redirect,
          metadata: metadata,
          onExit: onExit,
          caseSensitive: false,
          routes: children,
        );

        final GoRoute route = transition(source);

        expect(route.path, '/Case');
        expect(route.name, 'case');
        expect(route.parentNavigatorKey, same(navigatorKey));
        expect(route.redirect, same(source.redirect));
        expect(route.metadata, same(metadata));
        expect(route.onExit, same(source.onExit));
        expect(route.caseSensitive, isFalse);
        expect(route.routes, same(children));
      });

      test('rejects a route without a builder', () {
        final GoRoute pageOnly = GoRoute(
          path: '/page',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              const NoTransitionPage<void>(child: SizedBox.shrink()),
        );
        final GoRoute redirectOnly = GoRoute(
          path: '/redirect',
          redirect: (BuildContext context, GoRouterState state) => '/page',
        );

        expect(() => transition(pageOnly), throwsArgumentError);
        expect(() => transition(redirectOnly), throwsArgumentError);
      });
    });
  }
}
