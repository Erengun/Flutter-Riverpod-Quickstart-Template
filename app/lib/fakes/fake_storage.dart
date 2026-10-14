import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hive_ce/hive.dart';

import '../features/authentication/data/credentials_store.dart';
import '../features/authentication/data/demo_permissions.dart';
import '../features/authentication/domain/login_request.dart';
import '../hive/hive_adapters.dart';
import '../hive/hive_registrar.g.dart';

/// In-memory stand-ins for the app's Hive boxes, with their real names, for
/// tests and the catalog. A file-backed box's writes never finish inside the
/// widget tests' fake async zone, and the encrypted boxes need secure
/// storage, which tests and the catalog don't have.
class FakeStorage {
  FakeStorage._(this.prefs, this.session, this.credentials);

  /// The token [signIn] saves.
  static const String token = 'token-from-fake-storage';

  final Box<String> prefs;
  final Box<String> session;
  final Box<LoginCredentials> credentials;

  /// Opens (or reuses) the boxes and empties them. Tests call [close] in
  /// `tearDown`; the catalog reopens them each time a use case opens.
  static Future<FakeStorage> open() async {
    if (!Hive.isAdapterRegistered(LoginCredentialsAdapter().typeId)) {
      Hive.registerAdapters();
    }
    final FakeStorage storage = FakeStorage._(
      await Hive.openBox<String>(prefsBoxName, bytes: Uint8List(0)),
      await Hive.openBox<String>(sessionBoxName, bytes: Uint8List(0)),
      await Hive.openBox<LoginCredentials>(
        credentialsBoxName,
        bytes: Uint8List(0),
      ),
    );
    await storage.prefs.clear();
    await storage.session.clear();
    await storage.credentials.clear();
    return storage;
  }

  /// Saves remembered [credentials].
  Future<void> remember(LoginCredentials credentials) =>
      this.credentials.put('credentials', credentials);

  /// Saves a session and [permissions] (by default the demo permissions),
  /// as after a login.
  Future<void> signIn({Permissions? permissions}) async {
    const Session saved = Session(accessToken: token);
    await session.putAll(<String, String>{
      'accessToken': saved.accessToken,
      permissionsKey: (permissions ?? await loadDemoPermissions(saved))
          .encode(),
    });
  }

  /// Overrides every box provider with these boxes.
  List<Override> get overrides => overridesWith();

  /// [overrides], with the session box coming from [openSession] when given
  /// (for example a future that never completes, to hold the splash).
  List<Override> overridesWith({Future<Box<String>> Function()? openSession}) =>
      <Override>[
        prefsBoxProvider.overrideWithValue(prefs),
        sessionBoxProvider.overrideWith(
          (Ref ref) =>
              openSession?.call() ?? Future<Box<String>>.value(session),
        ),
        credentialsBoxProvider.overrideWith((Ref ref) async => credentials),
      ];

  Future<void> close() async {
    await prefs.close();
    await session.close();
    await credentials.close();
  }
}
