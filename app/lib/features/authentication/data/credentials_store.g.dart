// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The encrypted credentials box. Tests override it with a box of their own.

@ProviderFor(credentialsBox)
final credentialsBoxProvider = CredentialsBoxProvider._();

/// The encrypted credentials box. Tests override it with a box of their own.

final class CredentialsBoxProvider
    extends
        $FunctionalProvider<
          AsyncValue<Box<LoginCredentials>>,
          Box<LoginCredentials>,
          FutureOr<Box<LoginCredentials>>
        >
    with
        $FutureModifier<Box<LoginCredentials>>,
        $FutureProvider<Box<LoginCredentials>> {
  /// The encrypted credentials box. Tests override it with a box of their own.
  CredentialsBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsBoxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsBoxHash();

  @$internal
  @override
  $FutureProviderElement<Box<LoginCredentials>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Box<LoginCredentials>> create(Ref ref) {
    return credentialsBox(ref);
  }
}

String _$credentialsBoxHash() => r'88001a8ca8f2b58bb5f189f78bec87810b9d9f47';

@ProviderFor(credentialsStore)
final credentialsStoreProvider = CredentialsStoreProvider._();

final class CredentialsStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<CredentialsStore>,
          CredentialsStore,
          FutureOr<CredentialsStore>
        >
    with $FutureModifier<CredentialsStore>, $FutureProvider<CredentialsStore> {
  CredentialsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsStoreHash();

  @$internal
  @override
  $FutureProviderElement<CredentialsStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CredentialsStore> create(Ref ref) {
    return credentialsStore(ref);
  }
}

String _$credentialsStoreHash() => r'600dac2a0599aad2dfe7d97ca64a5cd6579e371e';
