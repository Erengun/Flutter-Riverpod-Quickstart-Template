import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

/// Name of the unencrypted Hive box that holds the user's preferences. It
/// must be open before `bootstrap` runs the app.
const String prefsBoxName = 'prefs';

const String _localeKey = 'locale';
const String _themeModeKey = 'themeMode';

/// The unencrypted preferences box. Defaults to the open Hive box named
/// [prefsBoxName]; tests override it with a box of their own.
final Provider<Box<String>> prefsBoxProvider = Provider<Box<String>>(
  (Ref ref) => Hive.box<String>(prefsBoxName),
  name: 'prefsBoxProvider',
);

/// The language the user chose, saved in [prefsBoxProvider]. `null` follows
/// the device. `MaterialApp.locale` reads it.
final NotifierProvider<LocaleNotifier, Locale?> localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(
      LocaleNotifier.new,
      name: 'localeProvider',
    );

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final String? tag = ref.watch(prefsBoxProvider).get(_localeKey);
    if (tag == null || tag.isEmpty) return null;
    // A language tag: language, then an optional 4-letter script, then an
    // optional country (`en`, `en-GB`, `zh-Hant-TW`).
    final List<String> parts = tag.split('-');
    final Iterable<String> subtags = parts.skip(1);
    final String? script = subtags
        .where((String part) => part.length == 4)
        .firstOrNull;
    final String? country = subtags
        .where((String part) => part.length != 4)
        .firstOrNull;
    return Locale.fromSubtags(
      languageCode: parts.first,
      scriptCode: script,
      countryCode: country,
    );
  }

  /// Saves [locale]; `null` goes back to the device language.
  Future<void> set(Locale? locale) async {
    state = locale;
    final Box<String> box = ref.read(prefsBoxProvider);
    if (locale == null) {
      await box.delete(_localeKey);
    } else {
      await box.put(_localeKey, locale.toLanguageTag());
    }
  }
}

/// The theme mode the user chose, saved in [prefsBoxProvider]. Defaults to
/// [ThemeMode.system]. `MaterialApp.themeMode` reads it.
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(
      ThemeModeNotifier.new,
      name: 'themeModeProvider',
    );

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final String? saved = ref.watch(prefsBoxProvider).get(_themeModeKey);
    for (final ThemeMode mode in ThemeMode.values) {
      // Also accepts `ThemeMode.dark`, the format the template saved before.
      if (saved == mode.name || saved == mode.toString()) return mode;
    }
    return ThemeMode.system;
  }

  /// Saves [mode].
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(prefsBoxProvider).put(_themeModeKey, mode.name);
  }
}
