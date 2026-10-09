import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'catalog_app.dart';

/// The catalog's addons, outermost first:
///
/// - device frames: phone, tablet and desktop (or none);
/// - locale: the app's locales (en, tr) with its gen-l10n delegates;
/// - text scale;
/// - accessibility checks (`accessibility_tools`);
/// - theme: the app's light and dark themes. It must come last: it wraps the
///   use case in [CatalogApp], which reads the locale addon's locale.
List<WidgetbookAddon<dynamic>> catalogAddons(KonteynerTheme theme) {
  return <WidgetbookAddon<dynamic>>[
    ViewportAddon(const <ViewportData>[
      IosViewports.iPhone13,
      IosViewports.iPadPro11Inches,
      MacosViewports.desktop,
      Viewports.none,
    ]),
    LocalizationAddon(
      locales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
    ),
    TextScaleAddon(),
    BuilderAddon(
      name: 'Accessibility',
      builder: (BuildContext context, Widget child) =>
          AccessibilityTools(child: child),
    ),
    ThemeAddon<ThemeData>(
      themes: <WidgetbookTheme<ThemeData>>[
        WidgetbookTheme<ThemeData>(name: 'Light', data: theme.light),
        WidgetbookTheme<ThemeData>(name: 'Dark', data: theme.dark),
      ],
      themeBuilder: (BuildContext context, ThemeData data, Widget child) =>
          CatalogApp(theme: data, child: child),
    ),
  ];
}
