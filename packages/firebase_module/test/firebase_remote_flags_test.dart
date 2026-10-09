import 'dart:async';
import 'dart:convert';

import 'package:firebase_module/src/firebase_remote_flags.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

class _Value extends RemoteConfigValue {
  _Value(String? value, ValueSource source)
    : super(value == null ? null : utf8.encode(value), source);
}

/// Stands in for Remote Config: [fetched] holds the values on the server,
/// [active] the ones reads see.
class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  Map<String, String> active = <String, String>{};
  Map<String, String> fetched = <String, String>{};
  final StreamController<RemoteConfigUpdate> _updates =
      StreamController<RemoteConfigUpdate>.broadcast();

  StreamSink<RemoteConfigUpdate> get updates => _updates.sink;

  Future<void> close() => _updates.close();
  Exception? fetchError;
  int activations = 0;

  @override
  RemoteConfigValue getValue(String key) {
    final String? value = active[key];
    return value == null
        ? _Value(null, ValueSource.valueStatic)
        : _Value(value, ValueSource.valueRemote);
  }

  @override
  Future<bool> activate() async {
    activations++;
    final bool changed = !mapEquals(active, fetched);
    active = Map<String, String>.of(fetched);
    return changed;
  }

  @override
  Future<bool> fetchAndActivate() async {
    final Exception? error = fetchError;
    if (error != null) throw error;
    return activate();
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => _updates.stream;
}

bool mapEquals(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length &&
    a.entries.every((MapEntry<String, String> e) => b[e.key] == e.value);

void main() {
  late _FakeRemoteConfig remote;
  late FirebaseRemoteFlags flags;

  setUp(() {
    remote = _FakeRemoteConfig();
    flags = FirebaseRemoteFlags(remote);
  });

  tearDown(() async {
    await flags.dispose();
    await remote.close();
  });

  group('reads', () {
    test('return the fallback for a key Remote Config does not have', () {
      expect(flags.getBool('missing', fallback: true), isTrue);
      expect(flags.getInt('missing', fallback: 7), 7);
      expect(flags.getString('missing', fallback: 'x'), 'x');
    });

    test('return the active remote values', () {
      remote.active = <String, String>{
        'on': 'true',
        'off': 'false',
        'count': '42',
        'text': 'hello',
        'empty': '',
      };

      expect(flags.getBool('on', fallback: false), isTrue);
      expect(flags.getBool('off', fallback: true), isFalse);
      expect(flags.getInt('count', fallback: 0), 42);
      expect(flags.getString('text', fallback: ''), 'hello');
      expect(flags.getString('empty', fallback: 'x'), '');
    });

    test('return the fallback when a value has the wrong type', () {
      remote.active = <String, String>{'text': 'hello'};

      expect(flags.getBool('text', fallback: true), isTrue);
      expect(flags.getInt('text', fallback: 3), 3);
    });
  });

  group('refresh', () {
    test('fetches and activates, then emits onChanged', () async {
      remote.fetched = <String, String>{'count': '5'};
      final Future<void> changed = flags.onChanged.first;

      await flags.refresh();
      await changed;

      expect(flags.getInt('count', fallback: 0), 5);
    });

    test('does not emit when nothing changed', () async {
      final List<void> events = <void>[];
      final StreamSubscription<void> sub = flags.onChanged.listen(events.add);

      await flags.refresh();
      await pumpEventQueue();

      expect(events, isEmpty);
      await sub.cancel();
    });

    test('keeps the cached values when the fetch fails', () async {
      remote
        ..active = <String, String>{'count': '1'}
        ..fetchError = Exception('offline');

      await expectLater(flags.refresh(), completes);

      expect(flags.getInt('count', fallback: 0), 1);
    });
  });

  group('start', () {
    test('activates the values fetched last time', () async {
      remote.fetched = <String, String>{'count': '9'};

      await flags.start();

      expect(flags.getInt('count', fallback: 0), 9);
    });

    test('a real-time update is activated before onChanged emits', () async {
      await flags.start();
      remote.fetched = <String, String>{'count': '2'};
      final Future<int> seen = flags.onChanged.first.then(
        (_) => flags.getInt('count', fallback: 0),
      );

      remote.updates.add(RemoteConfigUpdate(<String>{'count'}));

      expect(await seen, 2);
    });

    test('a failing real-time listener is logged, not thrown', () async {
      await flags.start();

      remote.updates.addError(Exception('stream failed'));
      await pumpEventQueue();

      expect(flags.getInt('count', fallback: 4), 4);
    });
  });
}
