import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hive/user_repository.dart';
import '../login_request.dart';

part 'get_cached_user.g.dart';

typedef GetCachedUser = Future<LoginCredentials?> Function();
@riverpod
GetCachedUser getCachedUser(Ref ref) =>
    () => ref.read(userRepositoryProvider).getCachedUser();
