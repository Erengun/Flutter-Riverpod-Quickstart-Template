import 'package:core/core.dart';
import 'package:firebase_module/firebase_module.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _configFor(Flavor flavor) => AppConfig(
  flavor: flavor,
  apiBaseUrl: 'https://example.com/',
  apiKey: 'demo',
);

void main() {
  test('is named firebase and runs on android, ios and web only', () {
    const FirebaseModule module = FirebaseModule();

    expect(module.name, 'firebase');
    expect(module.platforms, <KonteynerPlatform>{
      KonteynerPlatform.android,
      KonteynerPlatform.ios,
      KonteynerPlatform.web,
    });
  });

  for (final Flavor flavor in Flavor.values) {
    test('init throws while ${flavor.name} has only placeholder options', () {
      expect(
        () => const FirebaseModule().init(_configFor(flavor)),
        throwsA(
          isA<FirebaseNotConfiguredException>()
              .having(
                (FirebaseNotConfiguredException e) => e.flavor,
                'flavor',
                flavor,
              )
              .having(
                (FirebaseNotConfiguredException e) => e.toString(),
                'message',
                'Firebase not configured for ${flavor.name}',
              ),
        ),
      );
    });
  }

  test('an unconfigured Module leaves the no-op defaults in place', () async {
    final StartedModules started = await startModules(
      <KonteynerModule>[const FirebaseModule()],
      _configFor(Flavor.dev),
      platform: KonteynerPlatform.android,
    );

    expect(started.analytics, isA<NoopAnalytics>());
    expect(started.remoteFlags, isA<NoopRemoteFlags>());
    expect(started.failures.single.moduleName, 'firebase');
    expect(
      started.failures.single.error.toString(),
      'Firebase not configured for dev',
    );
  });

  test('is skipped on the build-only desktop platforms', () async {
    for (final KonteynerPlatform platform in <KonteynerPlatform>[
      KonteynerPlatform.macos,
      KonteynerPlatform.windows,
      KonteynerPlatform.linux,
    ]) {
      final StartedModules started = await startModules(
        <KonteynerModule>[const FirebaseModule()],
        _configFor(Flavor.dev),
        platform: platform,
      );

      expect(started.failures, isEmpty, reason: platform.name);
    }
  });

  test('Remote Config fetches at most every 12 h, more often on dev', () {
    expect(minimumFetchIntervalFor(Flavor.prod), const Duration(hours: 12));
    expect(minimumFetchIntervalFor(Flavor.staging), const Duration(hours: 12));
    expect(
      minimumFetchIntervalFor(Flavor.dev),
      lessThan(const Duration(hours: 12)),
    );
  });
}
