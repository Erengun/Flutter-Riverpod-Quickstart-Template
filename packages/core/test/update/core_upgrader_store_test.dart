import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

class _MapFlags implements RemoteFlags {
  _MapFlags(this.values);

  final Map<String, String> values;

  @override
  bool getBool(String key, {required bool fallback}) => fallback;

  @override
  int getInt(String key, {required int fallback}) => fallback;

  @override
  String getString(String key, {required String fallback}) =>
      values[key] ?? fallback;

  @override
  Future<void> refresh() async {}

  @override
  Stream<void> get onChanged => const Stream<void>.empty();
}

void main() {
  final Version installed = Version.parse('1.2.0');

  Future<UpgraderVersionInfo> versionInfo(
    AppVersionSource source, {
    String storeLink = 'https://example.com/app',
  }) {
    return CoreUpgraderStore(
      source: source,
      platform: CorePlatform.ios,
      storeLink: storeLink,
    ).getVersionInfo(
      state: Upgrader().state,
      installedVersion: installed,
      country: null,
      language: null,
    );
  }

  AppVersionSource constraints({String minimum = '', String recommended = ''}) {
    return (CorePlatform platform) async =>
        AppVersionConstraints(minimum: minimum, recommended: recommended);
  }

  group('remoteFlagsAppVersionSource', () {
    test('reads the per-platform keys', () async {
      final AppVersionSource source = remoteFlagsAppVersionSource(
        _MapFlags(<String, String>{
          'app_min_version_android': '1.0.0',
          'app_recommended_version_android': ' 1.1.0 ',
          'app_min_version_ios': '2.0.0',
        }),
      );

      final AppVersionConstraints android = await source(
        CorePlatform.android,
      );
      expect(android.minimum, '1.0.0');
      expect(android.recommended, '1.1.0');

      final AppVersionConstraints ios = await source(CorePlatform.ios);
      expect(ios.minimum, '2.0.0');
      expect(ios.recommended, isEmpty);
    });

    test("Core's default RemoteFlags means no constraint", () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AppVersionConstraints result = await container.read(
        appVersionSourceProvider,
      )(CorePlatform.windows);

      expect(result.minimum, isEmpty);
      expect(result.recommended, isEmpty);
    });

    test('follows remoteFlagsProvider', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          remoteFlagsProvider.overrideWithValue(
            _MapFlags(<String, String>{'app_min_version_linux': '3.0.0'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final AppVersionConstraints result = await container.read(
        appVersionSourceProvider,
      )(CorePlatform.linux);

      expect(result.minimum, '3.0.0');
    });
  });

  group('CoreUpgraderStore', () {
    test('no constraint: nothing is available', () async {
      final UpgraderVersionInfo info = await versionInfo(constraints());

      expect(info.appStoreVersion, isNull);
      expect(info.minAppVersion, isNull);
    });

    test('recommended only: a soft update to it', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(recommended: '1.3.0'),
      );

      expect(info.appStoreVersion, Version.parse('1.3.0'));
      expect(info.minAppVersion, isNull);
      expect(info.appStoreListingURL, 'https://example.com/app');
      expect(info.installedVersion, installed);
    });

    test('minimum only: the minimum is the available version', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(minimum: '2.0.0'),
      );

      expect(info.appStoreVersion, Version.parse('2.0.0'));
      expect(info.minAppVersion, Version.parse('2.0.0'));
    });

    test('both: the recommended version is available', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(minimum: '1.1.0', recommended: '1.5.0'),
      );

      expect(info.appStoreVersion, Version.parse('1.5.0'));
      expect(info.minAppVersion, Version.parse('1.1.0'));
    });

    test('a minimum above the recommended version still blocks', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(minimum: '2.0.0', recommended: '1.1.0'),
      );

      expect(info.appStoreVersion, Version.parse('2.0.0'));
      expect(info.minAppVersion, Version.parse('2.0.0'));
    });

    test('a value that is not a version is ignored', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(minimum: 'soon', recommended: '1.3.0'),
      );

      expect(info.appStoreVersion, Version.parse('1.3.0'));
      expect(info.minAppVersion, isNull);
    });

    test('an empty store link turns the check off', () async {
      final UpgraderVersionInfo info = await versionInfo(
        constraints(minimum: '9.0.0'),
        storeLink: '',
      );

      expect(info.appStoreVersion, isNull);
      expect(info.minAppVersion, isNull);
    });

    test('fail-open: a failing source with no earlier values', () async {
      final UpgraderVersionInfo info = await versionInfo(
        (CorePlatform platform) async => throw StateError('offline'),
      );

      expect(info.appStoreVersion, isNull);
      expect(info.minAppVersion, isNull);
    });

    test('fail-open: a failing source keeps the last values', () async {
      bool fail = false;
      final CoreUpgraderStore store = CoreUpgraderStore(
        source: (CorePlatform platform) async {
          if (fail) throw StateError('offline');
          return const AppVersionConstraints(minimum: '2.0.0');
        },
        platform: CorePlatform.android,
        storeLink: 'https://example.com/app',
      );
      Future<UpgraderVersionInfo> read() => store.getVersionInfo(
        state: Upgrader().state,
        installedVersion: installed,
        country: null,
        language: null,
      );

      expect((await read()).minAppVersion, Version.parse('2.0.0'));
      fail = true;
      expect((await read()).minAppVersion, Version.parse('2.0.0'));
    });
  });

  group('CoreUpgraderMessages', () {
    test("reads Core's strings, with the body for the update kind", () {
      final CoreUpgraderMessages hard =
          CoreUpgraderMessages.forLocale(
            const Locale('en'),
            updateRequired: true,
          );
      final CoreUpgraderMessages soft =
          CoreUpgraderMessages.forLocale(
            const Locale('en'),
            updateRequired: false,
          );
      final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));

      expect(hard.message(UpgraderMessage.title), en.updateTitle);
      expect(hard.message(UpgraderMessage.body), en.updateBodyRequired);
      expect(soft.message(UpgraderMessage.body), en.updateBodyOptional);
      expect(soft.message(UpgraderMessage.buttonTitleUpdate), 'Update');
      expect(soft.message(UpgraderMessage.buttonTitleIgnore), 'Ignore');
      expect(soft.message(UpgraderMessage.buttonTitleLater), 'Later');
      expect(soft.message(UpgraderMessage.prompt), isEmpty);
    });

    test('uses the given locale', () {
      final CoreUpgraderMessages tr = CoreUpgraderMessages.forLocale(
        const Locale('tr'),
        updateRequired: false,
      );

      expect(tr.languageCode, 'tr');
      expect(tr.message(UpgraderMessage.buttonTitleUpdate), 'Güncelle');
    });

    test('falls back to English for a locale Core has no strings for', () {
      final CoreUpgraderMessages de = CoreUpgraderMessages.forLocale(
        const Locale('de'),
        updateRequired: false,
      );

      expect(de.message(UpgraderMessage.buttonTitleLater), 'Later');
    });
  });
}
