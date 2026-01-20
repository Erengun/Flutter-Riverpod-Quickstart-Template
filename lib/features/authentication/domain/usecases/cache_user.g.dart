// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cacheUser)
final cacheUserProvider = CacheUserProvider._();

final class CacheUserProvider
    extends $FunctionalProvider<CacheUser, CacheUser, CacheUser>
    with $Provider<CacheUser> {
  CacheUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheUserHash();

  @$internal
  @override
  $ProviderElement<CacheUser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheUser create(Ref ref) {
    return cacheUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheUser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheUser>(value),
    );
  }
}

String _$cacheUserHash() => r'0ae3390ca7d32cd8c3b8cef251471b6817211cc1';
