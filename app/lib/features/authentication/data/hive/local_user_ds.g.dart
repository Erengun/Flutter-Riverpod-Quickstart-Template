// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user_ds.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localUserDatasource)
final localUserDatasourceProvider = LocalUserDatasourceProvider._();

final class LocalUserDatasourceProvider
    extends
        $FunctionalProvider<
          LocalUserDatasource,
          LocalUserDatasource,
          LocalUserDatasource
        >
    with $Provider<LocalUserDatasource> {
  LocalUserDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localUserDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localUserDatasourceHash();

  @$internal
  @override
  $ProviderElement<LocalUserDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalUserDatasource create(Ref ref) {
    return localUserDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalUserDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalUserDatasource>(value),
    );
  }
}

String _$localUserDatasourceHash() =>
    r'f3d168d0ec90befc92c4d6b8a32e04999f503161';
