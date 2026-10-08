import 'app_config.dart';
import 'konteyner_platform.dart';

/// Thrown when the native flavor (`--flavor`) differs from the entrypoint's
/// flavor, for example a prod app id wrapped around dev config.
class FlavorMismatchError extends Error {
  FlavorMismatchError({required this.entrypoint, required this.native});

  final Flavor entrypoint;
  final String? native;

  @override
  String toString() =>
      'FlavorMismatchError: the entrypoint is "${entrypoint.name}" but the '
      'native flavor is "${native ?? 'none'}". Run with '
      '--flavor ${entrypoint.name} -t lib/main_${entrypoint.name}.dart.';
}

/// Throws [FlavorMismatchError] on Android and iOS when [nativeFlavor]
/// (Flutter's `appFlavor`) is not [entrypoint]'s name.
///
/// Only Android and iOS have native per-flavor ids. On web and desktop the
/// entrypoint alone decides, so the check is skipped there.
void checkNativeFlavor(
  Flavor entrypoint, {
  required String? nativeFlavor,
  required KonteynerPlatform platform,
}) {
  if (platform != KonteynerPlatform.android &&
      platform != KonteynerPlatform.ios) {
    return;
  }
  if (nativeFlavor != entrypoint.name) {
    throw FlavorMismatchError(entrypoint: entrypoint, native: nativeFlavor);
  }
}
