import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Iterable<GoRoute> _goRoutes(List<RouteBase> routes) sync* {
  for (final RouteBase route in routes) {
    if (route is GoRoute) yield route;
    yield* _goRoutes(route.routes);
  }
}

void main() {
  test('every route is named, so breadcrumbs never carry parameters', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final GoRouter router = container.read(goRouterProvider);
    addTearDown(router.dispose);
    final List<GoRoute> routes = _goRoutes(
      router.configuration.routes,
    ).toList();

    expect(routes, isNotEmpty);
    for (final GoRoute route in routes) {
      expect(route.name, isNotNull, reason: '${route.path} has no name');
    }
  });
}
