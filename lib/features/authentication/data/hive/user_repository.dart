// domain/repositories/user_repo.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/login_request.dart';
import 'local_user_ds.dart';

part 'user_repository.g.dart';


@Riverpod(keepAlive: true)
class UserRepository extends _$UserRepository {
  @override
  FutureOr<LoginCredentials?> build() async {
    final LoginCredentials? user = await getCachedUser();
    if (user != null) {
      ref.keepAlive();
    }
    return user;
  }

  Future<void> cacheUser(LoginCredentials user) {
    final LocalUserDatasource ds = ref.read(localUserDatasourceProvider);
    return ds.save(user);
  }

  Future<LoginCredentials?> getCachedUser() {
    final LocalUserDatasource ds = ref.read(localUserDatasourceProvider);
    return ds.fetch();
  }

  Future<void> logout() {
    final LocalUserDatasource ds = ref.read(localUserDatasourceProvider);
    return ds.clear();
  }

}
