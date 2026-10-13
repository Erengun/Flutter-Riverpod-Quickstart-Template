import 'package:flutter/foundation.dart';

/// The six platforms an app built from the template can run on.
enum CorePlatform {
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
  static CorePlatform get current {
    if (kIsWeb) return CorePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => CorePlatform.android,
      TargetPlatform.iOS => CorePlatform.ios,
      TargetPlatform.macOS => CorePlatform.macos,
      TargetPlatform.windows => CorePlatform.windows,
      TargetPlatform.linux => CorePlatform.linux,
      TargetPlatform.fuchsia => throw UnsupportedError(
        'The template does not support Fuchsia.',
      ),
    };
  }
}
