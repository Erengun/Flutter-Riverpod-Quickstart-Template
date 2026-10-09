import 'package:logging/logging.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import '../config/konteyner_platform.dart';
import 'app_version_source.dart';

final Logger _log = Logger('update');

/// Core's only [UpgraderStore]: it returns the versions an
/// [AppVersionSource] holds instead of looking the app up in a store.
///
/// - The recommended version (or the minimum when no recommended one is set,
///   whichever is newer) is returned as the available version, so upgrader
///   prompts only when it is newer than the installed one.
/// - The minimum version is returned as `minAppVersion`, which makes the
///   prompt a hard update.
/// - An empty [storeLink] turns the check off.
/// - Fail-open: when [source] throws, the last values it returned are used;
///   with none, nothing is shown. A value that is not a version is ignored.
class KonteynerUpgraderStore extends UpgraderStore {
  KonteynerUpgraderStore({
    required this.source,
    required this.platform,
    required this.storeLink,
  });

  final AppVersionSource source;
  final KonteynerPlatform platform;

  /// Where the Update button sends the user.
  final String storeLink;

  AppVersionConstraints? _lastLoaded;

  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    if (storeLink.isEmpty) return UpgraderVersionInfo();

    AppVersionConstraints? constraints;
    try {
      constraints = await source(platform);
      _lastLoaded = constraints;
    } catch (error, stackTrace) {
      _log.warning(
        'Reading the app version constraints failed; using the last ones.',
        error,
        stackTrace,
      );
      constraints = _lastLoaded;
    }
    if (constraints == null) return UpgraderVersionInfo();

    final Version? minimum = _parse(constraints.minimum, 'minimum');
    final Version? recommended = _parse(constraints.recommended, 'recommended');
    final Version? available = switch ((minimum, recommended)) {
      (null, null) => null,
      (final Version min, null) => min,
      (null, final Version rec) => rec,
      (final Version min, final Version rec) => min > rec ? min : rec,
    };
    if (available == null) {
      return UpgraderVersionInfo(installedVersion: installedVersion);
    }
    return UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreListingURL: storeLink,
      appStoreVersion: available,
      minAppVersion: minimum,
    );
  }

  Version? _parse(String value, String name) {
    if (value.isEmpty) return null;
    try {
      return Version.parse(value);
    } on FormatException {
      _log.warning('Ignoring the $name app version "$value": not a version.');
      return null;
    }
  }
}
