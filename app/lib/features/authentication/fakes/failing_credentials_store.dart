import '../data/credentials_store.dart';
import '../domain/login_request.dart';

/// A [CredentialsStore] whose [save] always fails, like a full disk.
class FailingCredentialsStore extends CredentialsStore {
  const FailingCredentialsStore(super.box);

  @override
  Future<void> save(LoginCredentials credentials) async {
    throw StateError('disk full');
  }
}
