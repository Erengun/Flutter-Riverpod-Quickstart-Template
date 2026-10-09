import 'package:core/core.dart';

/// Thrown by the placeholder options files until `flutterfire configure` has
/// written real ones for [flavor].
///
/// Core logs it and keeps the no-op `Analytics` and `RemoteFlags`. Run
/// `melos run firebase:configure:<flavor>` to configure the flavor.
class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException(this.flavor);

  final Flavor flavor;

  @override
  String toString() => 'Firebase not configured for ${flavor.name}';
}
