import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const PermissionMenu _menu = PermissionMenu(
  routes: <String, String>{
    'orders': '/orders',
    'reports': '/reports',
    'settings': '/settings',
  },
  underConstructionPath: '/underConstruction',
);

const List<String> _keys = <String>['orders', 'reports', 'stock', 'settings'];

void main() {
  group('PermissionMenu.filter', () {
    test(
      'keeps the granted keys in order, unmapped ones under construction',
      () {
        const Permissions permissions = Permissions(
          areas: <String>{'settings', 'stock', 'orders'},
        );

        expect(_menu.filter(_keys, can: permissions.can), <PermissionMenuEntry>[
          const PermissionMenuEntry(
            key: 'orders',
            location: '/orders',
            underConstruction: false,
          ),
          const PermissionMenuEntry(
            key: 'stock',
            location: '/underConstruction',
            underConstruction: true,
          ),
          const PermissionMenuEntry(
            key: 'settings',
            location: '/settings',
            underConstruction: false,
          ),
        ]);
      },
    );

    test('keeps nothing without areas', () {
      expect(_menu.filter(_keys, can: Permissions.none.can), isEmpty);
    });

    test('keeps everything without a hook', () {
      expect(
        _menu
            .filter(_keys, can: Permissions.unrestricted.can)
            .map((PermissionMenuEntry entry) => entry.key),
        _keys,
      );
    });

    test('locationOf falls back to the under-construction page', () {
      expect(_menu.locationOf('reports'), '/reports');
      expect(_menu.locationOf('stock'), '/underConstruction');
    });
  });

  testWidgets('a menu filtered through canProvider follows the permissions', (
    WidgetTester tester,
  ) async {
    Permissions? permissions;
    late ProviderContainer container;
    final Provider<Permissions?> source = Provider<Permissions?>(
      (Ref ref) => permissions,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          permissionsProvider.overrideWith((Ref ref) => ref.watch(source)),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              container = ProviderScope.containerOf(context);
              final List<PermissionMenuEntry> entries = _menu.filter(
                _keys,
                can: (String area) => ref.watch(canProvider(area)),
              );
              return Column(
                children: <Widget>[
                  for (final PermissionMenuEntry entry in entries)
                    Text('${entry.key} ${entry.location}'),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Not known yet: no entries.
    expect(find.byType(Text), findsNothing);

    permissions = const Permissions(areas: <String>{'reports', 'stock'});
    container.invalidate(source);
    await tester.pump();

    expect(find.text('reports /reports'), findsOneWidget);
    expect(find.text('stock /underConstruction'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
  });
}
