import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

const Permissions _tree = Permissions(
  areas: <String>{'orders'},
  components: <String, ComponentState>{'orders.delete': ComponentState.hidden},
);

/// Holds the permissions a test hands to `permissionsProvider`.
class _Permissions extends Notifier<Permissions?> {
  @override
  Permissions? build() => null;

  void set(Permissions? permissions) => state = permissions;
}

final NotifierProvider<_Permissions, Permissions?> _source =
    NotifierProvider<_Permissions, Permissions?>(_Permissions.new);

void main() {
  late List<LogRecord> records;
  late StreamSubscription<LogRecord> subscription;

  setUp(() {
    records = <LogRecord>[];
    subscription = Logger.root.onRecord
        .where((LogRecord record) => record.loggerName == 'permissions')
        .listen(records.add);
  });

  tearDown(() => subscription.cancel());

  List<String> logged() => <String>[
    for (final LogRecord record in records) record.message,
  ];

  group('PermissionKeyLog', () {
    test('judges keys checked before a tree when it loads, once each', () {
      final PermissionKeyLog log = PermissionKeyLog()
        ..checked('orders')
        ..checked('orders.delete')
        ..checked('ordres')
        ..checked('orders.create');
      expect(records, isEmpty);

      log
        ..loaded(_tree)
        ..loaded(_tree)
        ..checked('ordres');

      expect(log.logged, <String>{'ordres', 'orders.create'});
      expect(records, hasLength(2));
      expect(records.every((LogRecord r) => r.level == Level.WARNING), isTrue);
      expect(logged().first, contains('"ordres"'));
    });

    test('judges a key checked after a tree at once', () {
      final PermissionKeyLog log = PermissionKeyLog()
        ..loaded(_tree)
        ..checked('orders.delete');
      expect(records, isEmpty);

      log.checked('reports');
      expect(log.logged, <String>{'reports'});
    });

    test('a key seen in any loaded tree counts as seen', () {
      final PermissionKeyLog log = PermissionKeyLog()
        ..loaded(const Permissions(areas: <String>{'reports'}))
        ..loaded(_tree)
        ..checked('reports');

      expect(log.logged, isEmpty);
    });

    test('no tree, an empty one or unrestricted judges nothing', () {
      final PermissionKeyLog log = PermissionKeyLog()
        ..checked('orders')
        ..loaded(null)
        ..loaded(Permissions.none)
        ..loaded(Permissions.unrestricted)
        ..checked('reports');

      expect(log.logged, isEmpty);
      expect(records, isEmpty);
    });

    test('logs nothing when off (release and profile builds)', () {
      final PermissionKeyLog log = PermissionKeyLog(enabled: false)
        ..checked('ordres')
        ..loaded(_tree)
        ..checked('reports');

      expect(log.logged, isEmpty);
      expect(records, isEmpty);
    });

    test('is on in debug builds', () {
      expect(PermissionKeyLog().enabled, isTrue);
    });
  });

  test('canProvider and componentStateProvider note their keys', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        permissionsProvider.overrideWith((Ref ref) => ref.watch(_source)),
      ],
    );
    addTearDown(container.dispose);

    container
      ..read(canProvider('orders'))
      ..read(canProvider('ordres'))
      ..read(componentStateProvider('orders.delete'))
      ..read(componentStateProvider('orders.dlete'));
    expect(records, isEmpty);

    container.read(_source.notifier).set(_tree);

    expect(container.read(permissionKeyLogProvider).logged, <String>{
      'ordres',
      'orders.dlete',
    });
    expect(records, hasLength(2));
  });
}
