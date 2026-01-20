// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoginController)
final loginControllerProvider = LoginControllerProvider._();

final class LoginControllerProvider
    extends $NotifierProvider<LoginController, AuthUiModel> {
  LoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginControllerHash();

  @$internal
  @override
  LoginController create() => LoginController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthUiModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthUiModel>(value),
    );
  }
}

String _$loginControllerHash() => r'9fb5ce40bca8865e767ec35c64c8ee389b107912';

abstract class _$LoginController extends $Notifier<AuthUiModel> {
  AuthUiModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthUiModel, AuthUiModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthUiModel, AuthUiModel>,
              AuthUiModel,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
