import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hive/user_repository.dart';
import '../login_request.dart';

part 'cache_user.g.dart';

typedef CacheUser = Future<void> Function(LoginCredentials);
@riverpod
CacheUser cacheUser(Ref ref) =>
    (LoginCredentials u) => ref.read(userRepositoryProvider.notifier).cacheUser(u);
