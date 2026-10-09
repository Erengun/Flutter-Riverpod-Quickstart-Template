import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'konteyner_platform.dart';

/// One of an app's three build variants.
///
/// The set is fixed because Modules switch on it and need every case.
enum Flavor { dev, staging, prod }

/// The store ids and links force update sends the user to, per platform.
///
/// An empty value turns the update check off on that platform. Web has no
/// check: a web app updates on reload.
class StoreLinks {
  const StoreLinks({
    this.playStoreId = '',
    this.appStoreId = '',
    this.microsoftStoreProductId = '',
    this.macosLink = '',
    this.linuxLink = '',
  });

  /// The Android application id listed on Google Play.
  final String playStoreId;

  /// The numeric App Store id (the digits after `id` in the store URL).
  final String appStoreId;

  /// The Microsoft Store ProductId.
  final String microsoftStoreProductId;

  /// A Mac App Store link or download page.
  final String macosLink;

  /// A download page for Linux.
  final String linuxLink;

  /// The link to open for an update on [platform], or an empty string when
  /// the check is off there.
  String linkFor(KonteynerPlatform platform) {
    return switch (platform) {
      KonteynerPlatform.android =>
        playStoreId.isEmpty
            ? ''
            : 'https://play.google.com/store/apps/details?id=$playStoreId',
      KonteynerPlatform.ios =>
        appStoreId.isEmpty ? '' : 'https://apps.apple.com/app/id$appStoreId',
      KonteynerPlatform.windows =>
        microsoftStoreProductId.isEmpty
            ? ''
            : 'ms-windows-store://pdp/?ProductId=$microsoftStoreProductId',
      KonteynerPlatform.macos => macosLink,
      KonteynerPlatform.linux => linuxLink,
      KonteynerPlatform.web => '',
    };
  }
}

/// The values that change per [Flavor]. The app owns one constant per flavor
/// and passes it to `bootstrap`.
///
/// Values a Module or Feature owns (a DSN, a second base URL) stay in that
/// Module or Feature and are picked by [flavor]. Nothing here is secret.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.apiKey,
    this.storeLinks = const StoreLinks(),
  });

  final Flavor flavor;

  /// The backend base URL.
  final String apiBaseUrl;

  /// The demo backend's API key, sent as `x-api-key`. Demo only: a key
  /// compiled into a client app is never secret.
  final String apiKey;

  /// Where force update sends the user, per platform.
  final StoreLinks storeLinks;
}

/// The running app's [AppConfig].
///
/// Throws unless `bootstrap` overrides it. Tests override it with
/// `appConfigProvider.overrideWithValue(config)`.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => throw StateError(
    'appConfigProvider was read before bootstrap overrode it. Start the app '
    'through bootstrap, or override appConfigProvider in tests.',
  ),
  name: 'appConfigProvider',
);
