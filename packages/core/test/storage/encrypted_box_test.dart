import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// An in-memory [HiveKeyStore]. [readError] makes every read throw.
class _MemoryKeyStore implements HiveKeyStore {
  final Map<String, String> values = <String, String>{};
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

  test('an unreadable key store gets a new key', () async {
    keys.readError = Exception('Failed to unwrap key');

    final Box<String> box = await openEncryptedBox<String>(
      'secrets',
      keyStore: keys,
    );

    expect(box.isOpen, isTrue);
    expect(keys.values[hiveEncryptionKeyName], isNotNull);
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
