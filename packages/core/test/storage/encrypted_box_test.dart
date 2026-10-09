import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// An in-memory [HiveKeyStore]. [readError] makes every read throw. Pass
/// another store's [values] to simulate an app restart: Core caches the key
/// per store object.
class _MemoryKeyStore implements HiveKeyStore {
  _MemoryKeyStore([Map<String, String>? values])
    : values = values ?? <String, String>{};

  final Map<String, String> values;
  Exception? readError;
  int writes = 0;
  Duration delay = Duration.zero;

  @override
  Future<String?> read(String name) async {
    await Future<void>.delayed(delay);
    final Exception? error = readError;
    if (error != null) throw error;
    return values[name];
  }

  @override
  Future<void> write(String name, String value) async {
    await Future<void>.delayed(delay);
    writes++;
    values[name] = value;
  }
}

void main() {
  late Directory directory;
  late _MemoryKeyStore keys;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('core_encrypted_box');
    Hive.init(directory.path);
    keys = _MemoryKeyStore();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('creates a random key on first use and keeps it', () async {
    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    await box.put('token', 'abc');
    await box.close();

    final String? stored = keys.values[hiveEncryptionKeyName];
    expect(stored, isNotNull);
    expect(base64Url.decode(stored!), hasLength(32));

    final Box<String> reopened = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    expect(reopened.get('token'), 'abc');
    expect(keys.writes, 1);
  });

  test('the box file is encrypted', () async {
    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    await box.put('token', 'plain-text-token');
    await box.close();

    final List<int> bytes = await File('${directory.path}/secrets.hive')
        .readAsBytes();
    expect(utf8.decode(bytes, allowMalformed: true), isNot(contains('plain')));
  });

  test('a box whose key was lost is recreated empty', () async {
    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    await box.put('token', 'abc');
    await box.close();

    // A restored backup on a new device: the file is back, the key is not.
    final _MemoryKeyStore newDevice = _MemoryKeyStore();
    final Box<String> reopened = await openEncryptedBox<String>(
      'secrets',
      keyStore: newDevice,
    );

    expect(reopened.get('token'), isNull);
    await reopened.put('token', 'new');
    await reopened.close();
    final Box<String> again = await openEncryptedBox<String>(
      'secrets',
      keyStore: newDevice,
    );
    expect(again.get('token'), 'new');
  });

  test('a corrupted box opens empty and stays usable', () async {
    // A file Hive cannot read at all.
    await File('${directory.path}/secrets.hive')
        .writeAsBytes(List<int>.filled(64, 0xff));

    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    expect(box.isEmpty, isTrue);
    await box.put('token', 'abc');
    expect(box.get('token'), 'abc');
  });

  test('an unreadable key store keeps the saved key and data', () async {
    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );
    await box.put('token', 'abc');
    await Hive.close();
    final String? savedKey = keys.values[hiveEncryptionKeyName];

    // Next launch, before the Keychain is unlocked.
    final _MemoryKeyStore relaunched = _MemoryKeyStore(keys.values)
      ..readError = Exception('Failed to unwrap key');
    await expectLater(
      openEncryptedBox<String>('secrets', keyStore: relaunched),
      throwsA(same(relaunched.readError)),
    );
    expect(relaunched.writes, 0);
    expect(keys.values[hiveEncryptionKeyName], savedKey);

    // The store is readable again: the same key opens the same data.
    relaunched.readError = null;
    final Box<String> reopened = await openEncryptedBox<String>(
      'secrets',
      keyStore: relaunched,
    );
    expect(reopened.get('token'), 'abc');
    expect(relaunched.writes, 0);
    expect(keys.values[hiveEncryptionKeyName], savedKey);
  });

  test('a missing key is created exactly once', () async {
    await openEncryptedBox<String>('a', keyStore: keys);
    await openEncryptedBox<String>('b', keyStore: keys);
    await Hive.close();
    final _MemoryKeyStore relaunched = _MemoryKeyStore(keys.values);
    await openEncryptedBox<String>('a', keyStore: relaunched);

    expect(keys.writes, 1);
    expect(relaunched.writes, 0);
  });

  test('a malformed saved key is replaced', () async {
    keys.values[hiveEncryptionKeyName] = 'not a key';

    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );

    expect(box.isOpen, isTrue);
    expect(keys.writes, 1);
    expect(
      base64Url.decode(keys.values[hiveEncryptionKeyName]!),
      hasLength(32),
    );
  });

  test('boxes opened at the same time share one new key', () async {
    keys.delay = const Duration(milliseconds: 5);

    final List<Box<String>> boxes = await Future.wait(<Future<Box<String>>>[
      openEncryptedBox<String>('a', keyStore: keys),
      openEncryptedBox<String>('b', keyStore: keys),
    ]);
    await boxes[0].put('k', 'a');
    await boxes[1].put('k', 'b');
    await Hive.close();

    expect(keys.writes, 1);
    expect((await openEncryptedBox<String>('a', keyStore: keys)).get('k'), 'a');
    expect((await openEncryptedBox<String>('b', keyStore: keys)).get('k'), 'b');
  });
}
