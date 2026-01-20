// features/auth/data/datasources/local_user_ds.dart
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/login_request.dart';
import 'hive_box_providers.dart';

part 'local_user_ds.g.dart';

@riverpod
LocalUserDatasource localUserDatasource(Ref ref) => LocalUserDatasource._(ref);

class LocalUserDatasource {
  LocalUserDatasource._(this._ref);
  final Ref _ref;

  Future<Box<LoginCredentials>> _box() async =>
      _ref.watch(userBoxProvider.future); // defined globally

  Future<void> save(LoginCredentials user) async =>
      (await _box()).put('cred', user);

  Future<LoginCredentials?> fetch() async => (await _box()).get('cred');

  Future<void> clear() async => (await _box()).delete('cred');
}
