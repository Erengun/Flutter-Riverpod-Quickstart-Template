import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';

/// The name the Hive encryption key is saved under in the [HiveKeyStore].
const String hiveEncryptionKeyName = 'konteyner.hive.key';

/// Where the Hive encryption key is kept. [SecureHiveKeyStore] (Keychain,
/// Android Keystore, ...) by default; tests pass an in-memory one.
abstract interface class HiveKeyStore {
  Future<String?> read(String name);

  Future<void> write(String name, String value);
}

/// [HiveKeyStore] over `flutter_secure_storage`.
class SecureHiveKeyStore implements HiveKeyStore {
  const SecureHiveKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String name) => _storage.read(key: name);

  @override
  Future<void> write(String name, String value) =>
      _storage.write(key: name, value: value);
}

final Logger _log = Logger('storage');

/// One key lookup per store, shared by boxes opened at the same time, so
/// two first-run opens never create two different keys. A failed lookup is
/// dropped, so the next open reads the store again.
final Expando<Future<List<int>>> _keys = Expando<Future<List<int>>>();

/// Opens the Hive box [name], AES-encrypted with the app's one key.
///
/// The key is created randomly (`Hive.generateSecureKey`) on first use and
/// kept in [keyStore] (secure storage by default). A stored key that reads
/// fine but is malformed is replaced by a new one.
///
/// If [keyStore] throws while reading (the iOS Keychain before the first
/// unlock, the Android Keystore briefly unavailable, ...), nothing is
/// written and the error is rethrown: overwriting the saved key would lose
/// every box for good. The next open reads the key again, so once the store
/// is readable the same key and data come back.
///
/// A box that fails to open (for example a restored backup whose key stayed
/// on the old device) is deleted and created again, empty. A box written
/// with another key opens empty too: Hive drops the entries it can't
/// decrypt.
///
/// Hive must be initialized (`Hive.init`) before this is called.
Future<Box<T>> openEncryptedBox<T>(
  String name, {
  HiveKeyStore keyStore = const SecureHiveKeyStore(),
}) async {
  final HiveAesCipher cipher = HiveAesCipher(await _encryptionKey(keyStore));
  try {
    return await Hive.openBox<T>(name, encryptionCipher: cipher);
  } catch (_) {
    // Never log the error itself: it may quote the box's contents.
    _log.warning('Box "$name" could not be opened; recreating it empty.');
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox<T>(name, encryptionCipher: cipher);
  }
}

Future<List<int>> _encryptionKey(HiveKeyStore store) {
  final Future<List<int>>? pending = _keys[store];
  if (pending != null) return pending;
  final Future<List<int>> created = _readOrCreateKey(store);
  _keys[store] = created;
  // A failed lookup is retried on the next open.
  created.catchError((Object _) {
    _keys[store] = null;
    return const <int>[];
  }).ignore();
  return created;
}

Future<List<int>> _readOrCreateKey(HiveKeyStore store) async {
  final String? saved;
  try {
    saved = await store.read(hiveEncryptionKeyName);
  } catch (_) {
    // Possibly transient: keep the saved key and let the open fail.
    _log.warning('The storage key could not be read; not opening the box.');
    rethrow;
  }
  if (saved != null) {
    try {
      final List<int> key = base64Url.decode(saved);
      if (key.length == 32) return key;
    } on FormatException {
      // Falls through to a new key.
    }
    _log.warning('The stored storage key is invalid; creating a new one.');
  }
  final List<int> key = Hive.generateSecureKey();
  await store.write(hiveEncryptionKeyName, base64Url.encode(key));
  return key;
}
