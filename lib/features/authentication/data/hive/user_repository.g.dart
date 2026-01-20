// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends $AsyncNotifierProvider<UserRepository, LoginCredentials?> {
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  UserRepository create() => UserRepository();
}

String _$userRepositoryHash() => r'b897639ccaee1621e267479909e060a0d90566c5';

abstract class _$UserRepository extends $AsyncNotifier<LoginCredentials?> {
  FutureOr<LoginCredentials?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LoginCredentials?>, LoginCredentials?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoginCredentials?>, LoginCredentials?>,
              AsyncValue<LoginCredentials?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
