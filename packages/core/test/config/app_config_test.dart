import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

const AppConfig _config = AppConfig(
  flavor: Flavor.staging,
  apiBaseUrl: 'https://example.com/',
  apiKey: 'demo',
);

void main() {
  group('appConfigProvider', () {
    test('throws unless bootstrap overrides it', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => container.read(appConfigProvider), throwsA(anything));
    });

    test('returns the overriding config', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[appConfigProvider.overrideWithValue(_config)],
      );
      addTearDown(container.dispose);

      expect(container.read(appConfigProvider), same(_config));
    });
  });

  group('StoreLinks', () {
    test('every link is empty by default, which means no check', () {
      const StoreLinks links = StoreLinks();

      for (final CorePlatform platform in CorePlatform.values) {
        expect(links.linkFor(platform), isEmpty);
      }
    });

    test('returns the link set for each platform and none for web', () {
      const StoreLinks links = StoreLinks(
        playStoreId: 'com.example.app',
        appStoreId: '123',
        microsoftStoreProductId: '9ABC',
        macosLink: 'https://example.com/mac',
        linuxLink: 'https://example.com/linux',
      );

      expect(
        links.linkFor(CorePlatform.android),
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
      expect(
        links.linkFor(CorePlatform.ios),
        'https://apps.apple.com/app/id123',
      );
      expect(
        links.linkFor(CorePlatform.windows),
        'ms-windows-store://pdp/?ProductId=9ABC',
      );
      expect(links.linkFor(CorePlatform.macos), 'https://example.com/mac');
      expect(
        links.linkFor(CorePlatform.linux),
        'https://example.com/linux',
      );
      expect(links.linkFor(CorePlatform.web), isEmpty);
    });
  });

  group('checkNativeFlavor', () {
    test('throws on Android and iOS when the native flavor differs', () {
      for (final CorePlatform platform in <CorePlatform>[
        CorePlatform.android,
        CorePlatform.ios,
      ]) {
        expect(
          () => checkNativeFlavor(
            Flavor.dev,
            nativeFlavor: 'prod',
            platform: platform,
          ),
          throwsA(isA<FlavorMismatchError>()),
        );
        expect(
          () => checkNativeFlavor(
            Flavor.prod,
            nativeFlavor: null,
            platform: platform,
          ),
          throwsA(isA<FlavorMismatchError>()),
        );
      }
    });

    test('passes on Android and iOS when the flavors match', () {
      checkNativeFlavor(
        Flavor.staging,
        nativeFlavor: 'staging',
        platform: CorePlatform.android,
      );
      checkNativeFlavor(
        Flavor.prod,
        nativeFlavor: 'prod',
        platform: CorePlatform.ios,
      );
    });

    test('is skipped on web and desktop, where the entrypoint decides', () {
      for (final CorePlatform platform in <CorePlatform>[
        CorePlatform.web,
        CorePlatform.macos,
        CorePlatform.windows,
        CorePlatform.linux,
      ]) {
        checkNativeFlavor(Flavor.prod, nativeFlavor: 'dev', platform: platform);
      }
    });
  });

  group('CorePlatform.current', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('follows the target platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(CorePlatform.current, CorePlatform.ios);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(CorePlatform.current, CorePlatform.windows);
    });
  });
}
