import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'firebase_analytics_adapter.dart';
import 'firebase_not_configured.dart';
import 'firebase_remote_flags.dart';
import 'options/firebase_options_dev.dart' as dev;
import 'options/firebase_options_prod.dart' as prod;
import 'options/firebase_options_staging.dart' as staging;

/// How often Remote Config may fetch for [flavor]: 12 hours, Firebase's
/// default, except on dev, where changes in the console should show up
/// quickly.
Duration minimumFetchIntervalFor(Flavor flavor) {
  return switch (flavor) {
    Flavor.dev => const Duration(minutes: 5),
    Flavor.staging || Flavor.prod => const Duration(hours: 12),
  };
}

/// The options `flutterfire configure` wrote for [flavor] and the current
/// platform.
///
/// Throws [FirebaseNotConfiguredException] while the file for [flavor] is
/// still the template's placeholder.
FirebaseOptions firebaseOptionsFor(Flavor flavor) {
  return switch (flavor) {
    Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
    Flavor.staging => staging.DefaultFirebaseOptions.currentPlatform,
    Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
  };
}

/// Firebase Analytics and Remote Config, provided to Core as `Analytics` and
/// `RemoteFlags`.
///
/// Runs on android, ios and web; Core skips it on the desktop platforms.
/// Each flavor uses its own Firebase project, whose options live in
/// `lib/src/options/firebase_options_<flavor>.dart`.
class FirebaseModule implements KonteynerModule {
  const FirebaseModule();

  @override
  String get name => 'firebase';

  @override
  Set<KonteynerPlatform> get platforms => const <KonteynerPlatform>{
    KonteynerPlatform.android,
    KonteynerPlatform.ios,
    KonteynerPlatform.web,
  };

  @override
  Future<ModuleContributions> init(AppConfig config) async {
    // Resolved first, so an unconfigured flavor fails before any plugin call.
    final FirebaseOptions options = firebaseOptionsFor(config.flavor);
    await Firebase.initializeApp(options: options);

    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: minimumFetchIntervalFor(config.flavor),
      ),
    );
    final FirebaseRemoteFlags remoteFlags = FirebaseRemoteFlags(remoteConfig);
    await remoteFlags.start();
    // Startup never waits on the network: reads use the cached values until
    // this completes, then onChanged fires.
    unawaited(remoteFlags.refresh());

    return ModuleContributions(
      analytics: FirebaseAnalyticsAdapter(FirebaseAnalytics.instance),
      remoteFlags: remoteFlags,
    );
  }
}
