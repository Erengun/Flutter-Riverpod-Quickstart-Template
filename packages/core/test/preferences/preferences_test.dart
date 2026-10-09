import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late Directory directory;
  late Box<String> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('core_prefs_test');
    Hive.init(directory.path);
    box = await Hive.openBox<String>(prefsBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[prefsBoxProvider.overrideWithValue(box)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('localeProvider', () {
    test('follows the device (null) when nothing is saved', () {
      expect(createContainer().read(localeProvider), isNull);
    });

    test('a chosen locale is saved and read back after a restart', () async {
      await createContainer().read(localeProvider.notifier).set(
        const Locale('tr'),
      );

      expect(box.get('locale'), 'tr');
      expect(createContainer().read(localeProvider), const Locale('tr'));
    });

    test('a locale with a country code survives a restart', () async {
      await createContainer().read(localeProvider.notifier).set(
        const Locale('en', 'GB'),
      );

      expect(createContainer().read(localeProvider), const Locale('en', 'GB'));
    });

    test('a locale with a script code survives a restart', () async {
      const Locale chinese = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      await createContainer().read(localeProvider.notifier).set(chinese);

      expect(createContainer().read(localeProvider), chinese);
    });

    test('setting null goes back to the device locale', () async {
      final ProviderContainer container = createContainer();
      await container.read(localeProvider.notifier).set(const Locale('tr'));
      await container.read(localeProvider.notifier).set(null);

      expect(container.read(localeProvider), isNull);
      expect(box.containsKey('locale'), isFalse);
      expect(createContainer().read(localeProvider), isNull);
    });
  });

  group('themeModeProvider', () {
    test('follows the system when nothing is saved', () {
      expect(createContainer().read(themeModeProvider), ThemeMode.system);
    });

    test('a chosen mode is saved and read back after a restart', () async {
      final ProviderContainer container = createContainer();
      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(box.get('themeMode'), 'dark');
      expect(createContainer().read(themeModeProvider), ThemeMode.dark);
    });

    test('reads the value the old theme provider saved', () async {
      await box.put('themeMode', 'ThemeMode.light');

      expect(createContainer().read(themeModeProvider), ThemeMode.light);
    });

    test('an unknown saved value falls back to the system', () async {
      await box.put('themeMode', 'sepia');

      expect(createContainer().read(themeModeProvider), ThemeMode.system);
    });
  });
}
