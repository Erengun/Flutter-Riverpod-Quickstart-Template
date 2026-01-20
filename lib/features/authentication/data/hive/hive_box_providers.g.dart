// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_box_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 2️⃣ Open the encrypted box.
/// Use `@Riverpod(keepAlive: true)` if you *never* want it disposed;
/// plain `@riverpod` auto-disposes when no-longer-used.

@ProviderFor(userBox)
final userBoxProvider = UserBoxProvider._();

/// 2️⃣ Open the encrypted box.
/// Use `@Riverpod(keepAlive: true)` if you *never* want it disposed;
/// plain `@riverpod` auto-disposes when no-longer-used.

final class UserBoxProvider
    extends
        $FunctionalProvider<
          AsyncValue<Box<LoginCredentials>>,
          Box<LoginCredentials>,
          FutureOr<Box<LoginCredentials>>
        >
    with
        $FutureModifier<Box<LoginCredentials>>,
        $FutureProvider<Box<LoginCredentials>> {
  /// 2️⃣ Open the encrypted box.
  /// Use `@Riverpod(keepAlive: true)` if you *never* want it disposed;
  /// plain `@riverpod` auto-disposes when no-longer-used.
  UserBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userBoxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userBoxHash();

  @$internal
  @override
  $FutureProviderElement<Box<LoginCredentials>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Box<LoginCredentials>> create(Ref ref) {
    return userBox(ref);
  }
}

String _$userBoxHash() => r'587dbb06fe2d4fb6c2c521c2e33ac6fe1f45a588';

@ProviderFor(themeBox)
final themeBoxProvider = ThemeBoxProvider._();

final class ThemeBoxProvider
    extends
        $FunctionalProvider<
          AsyncValue<Box<String>>,
          Box<String>,
          FutureOr<Box<String>>
        >
    with $FutureModifier<Box<String>>, $FutureProvider<Box<String>> {
  ThemeBoxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeBoxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeBoxHash();

  @$internal
  @override
  $FutureProviderElement<Box<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Box<String>> create(Ref ref) {
    return themeBox(ref);
  }
}

String _$themeBoxHash() => r'4bb9751bc775083fb3fa0c70c22ee75ac34179fc';
