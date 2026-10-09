import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/authentication/data/credentials_store.dart';
import 'package:flutter_riverpod_template/features/authentication/domain/login_request.dart';
import 'package:flutter_riverpod_template/hive/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';

/// In-memory stand-ins for the app's Hive boxes. A file-backed box's writes
/// never finish inside the widget tests' fake async zone, and the encrypted
/// boxes need secure storage, which tests don't have.
class TestStorage {
  TestStorage._(this.prefs, this.session, this.credentials);

  final Box<String> prefs;
  final Box<String> session;
  final Box<LoginCredentials> credentials;

  /// Opens empty boxes. Call [close] in `tearDown`.
  static Future<TestStorage> open() async {
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapters();
    return TestStorage._(
      await Hive.openBox<String>(prefsBoxName, bytes: Uint8List(0)),
      await Hive.openBox<String>(sessionBoxName, bytes: Uint8List(0)),
      await Hive.openBox<LoginCredentials>(
        credentialsBoxName,
        bytes: Uint8List(0),
      ),
    );
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
