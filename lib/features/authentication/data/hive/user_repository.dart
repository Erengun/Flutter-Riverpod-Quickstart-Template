// domain/repositories/user_repo.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/login_request.dart';
import 'local_user_ds.dart';

part 'user_repository.g.dart';

abstract interface class UserRepository {
  Future<void> cacheUser(LoginCredentials user);
  Future<LoginCredentials?> getCachedUser();
  Future<void> logout();
}

@riverpod
UserRepository userRepository(Ref ref) =>
    _UserRepoImpl(ref.read(localUserDatasourceProvider));

class _UserRepoImpl implements UserRepository {
  _UserRepoImpl(this._ds);
  final LocalUserDatasource _ds;

  @override
  Future<void> cacheUser(LoginCredentials user) => _ds.save(user);

  @override
  Future<LoginCredentials?> getCachedUser() => _ds.fetch();

  @override
  Future<void> logout() => _ds.clear();
}
