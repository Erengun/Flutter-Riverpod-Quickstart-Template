import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'catalog/catalog_addons.dart';
import 'main.directories.g.dart';

/// The Widgetbook catalog: Core's screens and the app's demo screens.
///
/// Run it with `melos run widgetbook` (or `flutter run -d chrome` here).
/// Use cases live next to this file, in paths that mirror the widget's
/// (`lib/core/...`, `lib/app/features/...`); `melos run gen` regenerates
/// `main.directories.g.dart` from their `@UseCase` annotations.
///
/// There is no ProviderScope at the root: each use case that needs Riverpod
/// makes its own, so its overrides stay in that use case.
void main() {
  // The theme starts loading the bundled fonts, which needs the binding.
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: riverpod_lint/missing_provider_scope
  runApp(WidgetbookApp(theme: buildAppTheme()));
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({
    required this.theme,
    this.initialRoute = '/',
    super.key,
  });

  /// The app's light and dark themes.
  final CoreTheme theme;

  /// Widgetbook's first route; `/?path=<use case path>` opens a use case.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      directories: directories,
      addons: catalogAddons(theme),
      initialRoute: initialRoute,
      // The theme addon already wraps each use case in CatalogApp, the app
      // around it. Widgetbook's default builder adds a WidgetsApp with `home`
      // and no page route builder, which throws on its first route.
      appBuilder: (BuildContext context, Widget child) => child,
    );
  }
}
