import 'package:flutter/services.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The app around every use case: a material_ui `MaterialApp` with [theme],
/// the locale addon's locale and the app's localizations delegates.
///
/// Widgetbook's own shell is built with `package:flutter/material.dart`,
/// whose `Theme`, `ScaffoldMessenger` and localizations are other types than
/// material_ui's, so the app's widgets can't see them. This gives them their
/// own: snackbars, dialogs and `Theme.of` work as in the app.
///
/// It has no router: a use case that navigates with go_router (the demo
/// screens' links) does nothing in the catalog.
class CatalogApp extends StatelessWidget {
  const CatalogApp({required this.theme, required this.child, super.key});

  /// One of the app's themes from `buildAppTheme`.
  final ThemeData theme;

  /// The use case.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The browser tab keeps Widgetbook's title.
      title: 'Widgetbook',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: Localizations.maybeLocaleOf(context),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      // Not `home`: the app's navigator would report its route to the
      // browser and replace Widgetbook's URL. This navigator doesn't.
      builder: (BuildContext context, Widget? _) => DefaultAssetBundle(
        bundle: _appAssetBundle,
        child: Navigator(
          pages: <Page<void>>[
            MaterialPage<void>(
              key: const ValueKey<String>('use-case'),
              child: child,
            ),
          ],
          onDidRemovePage: (Page<Object?> page) {},
        ),
      ),
    );
  }
}

final AssetBundle _appAssetBundle = _AppAssetBundle();

/// The app's assets live under `packages/flutter_riverpod_template/` in the
/// catalog, but its widgets load them without a package (for example
/// `Image.asset('assets/img/...')`). This bundle adds the prefix.
class _AppAssetBundle extends CachingAssetBundle {
  static const String _prefix = 'packages/flutter_riverpod_template/';

  @override
  Future<ByteData> load(String key) {
    return rootBundle.load(key.startsWith('assets/') ? '$_prefix$key' : key);
  }
}
