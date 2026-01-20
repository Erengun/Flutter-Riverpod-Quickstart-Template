// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_cached_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getCachedUser)
final getCachedUserProvider = GetCachedUserProvider._();

final class GetCachedUserProvider
    extends $FunctionalProvider<GetCachedUser, GetCachedUser, GetCachedUser>
    with $Provider<GetCachedUser> {
  GetCachedUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCachedUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCachedUserHash();

  @$internal
  @override
  $ProviderElement<GetCachedUser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetCachedUser create(Ref ref) {
    return getCachedUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCachedUser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCachedUser>(value),
    );
  }
}

String _$getCachedUserHash() => r'944f206d179c98ac85c346fda1e716f57957f2c5';
