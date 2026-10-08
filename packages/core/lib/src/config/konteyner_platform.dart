import 'package:flutter/foundation.dart';

/// The six platforms an app built from Konteyner can run on.
enum KonteynerPlatform {
  android,
  ios,
  web,
  macos,
  windows,
  linux;

  /// The platform this app is running on.
  ///
  /// Uses [defaultTargetPlatform], so tests can change it with
  /// `debugDefaultTargetPlatformOverride`.
  static KonteynerPlatform get current {
    if (kIsWeb) return KonteynerPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => KonteynerPlatform.android,
      TargetPlatform.iOS => KonteynerPlatform.ios,
      TargetPlatform.macOS => KonteynerPlatform.macos,
      TargetPlatform.windows => KonteynerPlatform.windows,
      TargetPlatform.linux => KonteynerPlatform.linux,
      TargetPlatform.fuchsia => throw UnsupportedError(
        'Konteyner does not support Fuchsia.',
      ),
    };
  }
}
