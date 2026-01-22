// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A repository class that extends _$NetworkRepository to handle network-related operations.
/// This class serves as an abstraction layer for managing network requests and responses,
/// providing a clean interface for the rest of the application to interact with network data.

@ProviderFor(NetworkRepository)
final networkRepositoryProvider = NetworkRepositoryProvider._();

/// A repository class that extends _$NetworkRepository to handle network-related operations.
/// This class serves as an abstraction layer for managing network requests and responses,
/// providing a clean interface for the rest of the application to interact with network data.
final class NetworkRepositoryProvider
    extends $NotifierProvider<NetworkRepository, Dio> {
  /// A repository class that extends _$NetworkRepository to handle network-related operations.
  /// This class serves as an abstraction layer for managing network requests and responses,
  /// providing a clean interface for the rest of the application to interact with network data.
  NetworkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkRepositoryHash();

  @$internal
  @override
  NetworkRepository create() => NetworkRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$networkRepositoryHash() => r'1faa007371d8b7b744768f0613bedb57565f201f';

/// A repository class that extends _$NetworkRepository to handle network-related operations.
/// This class serves as an abstraction layer for managing network requests and responses,
/// providing a clean interface for the rest of the application to interact with network data.

abstract class _$NetworkRepository extends $Notifier<Dio> {
  Dio build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Dio, Dio>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Dio, Dio>,
              Dio,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
