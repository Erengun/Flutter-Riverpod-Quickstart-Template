import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/konteyner_platform.dart';
import '../reporting/remote_flags.dart';

/// The minimum and recommended app versions for one platform, as `x.y.z`
/// version names (never build numbers).
///
/// An empty value means "no constraint".
class AppVersionConstraints {
  const AppVersionConstraints({this.minimum = '', this.recommended = ''});

  /// Below it the app is blocked until the user updates (hard update).
  final String minimum;

  /// Below it the user gets a prompt they can dismiss (soft update).
  final String recommended;
}

/// Where force update reads the [AppVersionConstraints] for a platform from.
///
/// Throwing, or returning empty values, never blocks anyone.
typedef AppVersionSource = Future<AppVersionConstraints> Function(
  KonteynerPlatform platform,
);

/// The `RemoteFlags` key holding the minimum app version for [platform].
String appMinVersionKey(KonteynerPlatform platform) =>
    'app_min_version_${platform.name}';

/// The `RemoteFlags` key holding the recommended app version for [platform].
String appRecommendedVersionKey(KonteynerPlatform platform) =>
    'app_recommended_version_${platform.name}';

/// Core's default [AppVersionSource]: reads [appMinVersionKey] and
/// [appRecommendedVersionKey] from [flags]. The fallback for every key is
/// "no constraint".
AppVersionSource remoteFlagsAppVersionSource(RemoteFlags flags) {
  return (KonteynerPlatform platform) async => AppVersionConstraints(
    minimum: flags.getString(appMinVersionKey(platform), fallback: '').trim(),
    recommended: flags
        .getString(appRecommendedVersionKey(platform), fallback: '')
        .trim(),
  );
}

/// The [AppVersionSource] force update uses. Defaults to
/// [remoteFlagsAppVersionSource] over `remoteFlagsProvider`.
///
/// An app whose backend serves the versions overrides it with its own
/// source; a backend never poses as `RemoteFlags`.
final Provider<AppVersionSource> appVersionSourceProvider =
    Provider<AppVersionSource>(
      (Ref ref) => remoteFlagsAppVersionSource(ref.watch(remoteFlagsProvider)),
      name: 'appVersionSourceProvider',
    );
