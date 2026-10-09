import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_menu.dart';
import '../../../../shared/permission_keys.dart';

/// The home screen's menu: only the granted areas of [appMenuKeys]. With
/// the demo permissions, reports is left out and orders opens the
/// under-construction page.
class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<PermissionMenuEntry> entries = appMenu.filter(
      appMenuKeys,
      can: (String area) => ref.watch(canProvider(area)),
    );
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                l10n.homeMenuTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final PermissionMenuEntry entry in entries)
              ListTile(
                title: Text(_label(l10n, entry.key)),
                trailing: entry.underConstruction
                    ? const Icon(Icons.construction_outlined)
                    : null,
                onTap: () {
                  final GoRouter router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(entry.location);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// The menu's look belongs to the app, labels included.
  static String _label(AppLocalizations l10n, String key) => switch (key) {
    AppAreas.profile => l10n.demoProfileTitle,
    AppAreas.settings => l10n.demoSettingsTitle,
    AppAreas.reports => l10n.demoReportsTitle,
    AppAreas.orders => l10n.demoOrdersTitle,
    _ => key,
  };
}
