import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/storage.dart';

Iterable<GoRoute> _goRoutes(List<RouteBase> routes) sync* {
  for (final RouteBase route in routes) {
    if (route is GoRoute) yield route;
    yield* _goRoutes(route.routes);
  }
}

void main() {
  late TestStorage storage;

  setUp(() async {
    storage = await TestStorage.open();
  });

  tearDown(() => storage.close());

  test('every route is named, so breadcrumbs never carry parameters', () {
    final ProviderContainer container = ProviderContainer(
      overrides: storage.overrides,
    );
    addTearDown(container.dispose);

    final GoRouter router = container.read(goRouterProvider);
    final List<GoRoute> routes = _goRoutes(
      router.configuration.routes,
    ).toList();

    expect(routes, isNotEmpty);
    for (final GoRoute route in routes) {
      expect(route.name, isNotNull, reason: '${route.path} has no name');
    }
  });
}
