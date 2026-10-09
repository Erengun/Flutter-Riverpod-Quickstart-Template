import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const Permissions _permissions = Permissions(
  areas: <String>{'orders'},
  components: <String, ComponentState>{
    'orders.delete': ComponentState.hidden,
    'orders.price': ComponentState.readonly,
    'orders.export': ComponentState.disabled,
  },
);

/// Holds the permissions a test hands to `permissionsProvider`.
class _Permissions extends Notifier<Permissions?> {
  @override
  Permissions? build() => _permissions;

  void set(Permissions? permissions) => state = permissions;
}

final NotifierProvider<_Permissions, Permissions?> _source =
    NotifierProvider<_Permissions, Permissions?>(_Permissions.new);

void main() {
  late int taps;

  setUp(() => taps = 0);

  /// A [PermissionGate] for [componentKey] around a button counting taps.
  Future<ProviderContainer> pumpGate(
    WidgetTester tester,
    String componentKey, {
    Permissions? permissions = _permissions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          permissionsProvider.overrideWith((Ref ref) => ref.watch(_source)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: PermissionGate(
                componentKey: componentKey,
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('Control'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    if (permissions != _permissions) {
      container.read(_source.notifier).set(permissions);
      await tester.pump();
    }
    return container;
  }

  Finder opacity() => find.ancestor(
    of: find.byType(ElevatedButton),
    matching: find.byType(Opacity),
  );

  Future<void> tapControl(WidgetTester tester) async {
    // The gate absorbs the tap, so the button itself is never hit.
    await tester.tap(find.text('Control'), warnIfMissed: false);
    await tester.pump();
  }

  testWidgets('a control without a rule is shown and works', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester, 'orders.create');

    expect(find.text('Control'), findsOneWidget);
    expect(opacity(), findsNothing);
    await tapControl(tester);
    expect(taps, 1);
  });

  testWidgets('hidden removes the control', (WidgetTester tester) async {
    await pumpGate(tester, 'orders.delete');

    expect(find.text('Control'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('readonly shows the control, not greyed, but not interactive', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester, 'orders.price');

    expect(find.text('Control'), findsOneWidget);
    expect(opacity(), findsNothing);
    expect(
      find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
    await tapControl(tester);
    expect(taps, 0);
    expect(
      tester
          .widget<ExcludeFocus>(
            find
                .ancestor(
                  of: find.byType(ElevatedButton),
                  matching: find.byType(ExcludeFocus),
                )
                .first,
          )
          .excluding,
      isTrue,
    );
  });

  testWidgets('disabled greys the control out and makes it inert', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester, 'orders.export');

    expect(find.text('Control'), findsOneWidget);
    final BuildContext context = tester.element(find.byType(ElevatedButton));
    expect(
      tester.widget<Opacity>(opacity()).opacity,
      Theme.of(context).disabledColor.a,
    );
    expect(
      find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(ColorFiltered),
      ),
      findsOneWidget,
    );
    await tapControl(tester);
    expect(taps, 0);
  });

  testWidgets('hides the control until the permissions are known', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpGate(
      tester,
      'orders.create',
      permissions: null,
    );
    expect(find.text('Control'), findsNothing);

    container.read(_source.notifier).set(_permissions);
    await tester.pump();
    expect(find.text('Control'), findsOneWidget);
  });

  testWidgets('follows the rule when the permissions change', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpGate(tester, 'orders.delete');
    expect(find.text('Control'), findsNothing);

    container
        .read(_source.notifier)
        .set(const Permissions(areas: <String>{'orders'}));
    await tester.pump();
    expect(find.text('Control'), findsOneWidget);
    await tapControl(tester);
    expect(taps, 1);
  });

  testWidgets('without a hook every control is shown', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      'orders.delete',
      permissions: Permissions.unrestricted,
    );

    expect(find.text('Control'), findsOneWidget);
  });

  group('code checks', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: <Override>[
          permissionsProvider.overrideWith((Ref ref) => ref.watch(_source)),
        ],
      );
      addTearDown(container.dispose);
    });

    test('canProvider checks an area, fail-closed while unknown', () {
      expect(container.read(canProvider('orders')), isTrue);
      expect(container.read(canProvider('reports')), isFalse);

      container.read(_source.notifier).set(null);
      expect(container.read(canProvider('orders')), isFalse);
    });

    test('componentStateProvider returns the rule, hidden while unknown', () {
      expect(
        container.read(componentStateProvider('orders.price')),
        ComponentState.readonly,
      );
      expect(container.read(componentStateProvider('orders.create')), isNull);

      container.read(_source.notifier).set(null);
      expect(
        container.read(componentStateProvider('orders.create')),
        ComponentState.hidden,
      );
    });
  });
}
