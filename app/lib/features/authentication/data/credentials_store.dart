import 'package:core/core.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/login_request.dart';

part 'credentials_store.g.dart';

/// Name of the encrypted box holding the remembered credentials.
const String credentialsBoxName = 'credentials';

const String _credentialsKey = 'credentials';

/// The encrypted credentials box. Tests override it with a box of their own.
@Riverpod(keepAlive: true)
Future<Box<LoginCredentials>> credentialsBox(Ref ref) =>
    openEncryptedBox<LoginCredentials>(credentialsBoxName);

/// Remember me: the email and password saved only to pre-fill the login
/// form. They are never used to sign in on their own, and logout keeps them.
class CredentialsStore {
  const CredentialsStore(Box<LoginCredentials> box) : _box = box;

  final Box<LoginCredentials> _box;

  LoginCredentials? read() => _box.get(_credentialsKey);

  Future<void> save(LoginCredentials credentials) =>
      _box.put(_credentialsKey, credentials);

  Future<void> clear() => _box.delete(_credentialsKey);
}

@Riverpod(keepAlive: true)
Future<CredentialsStore> credentialsStore(Ref ref) async =>
    CredentialsStore(await ref.watch(credentialsBoxProvider.future));
