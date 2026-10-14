import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../utils/context_extensions.dart';
import 'widgets/app_menu_drawer.dart';
import 'widgets/component_rules_demo.dart';
import 'widgets/header.dart';
import 'widgets/language_tile.dart';
import 'widgets/social_tile_widget.dart';
import 'widgets/theme_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.logout_outlined, color: context.colorScheme.primary),
          // The router's redirect replaces home with login, so back can't
          // undo it.
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
        ),
      ),
      // Only the granted areas; opened from the app bar's menu button.
      endDrawer: const AppMenuDrawer(),
      backgroundColor: context.colorScheme.surface,
      // Spread over the screen when it fits; scrolls when it doesn't (every
      // control shown, a small phone or a large text scale).
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Header(text: AppLocalizations.of(context).homeIntro),
                const Divider(),
                const ThemeWidget(),
                const LanguageTile(),
                const _PermissionDemoLinks(),
                const ComponentRulesDemo(),
                // Four fixed tiles: a Column, not a shrink-wrapped ListView.
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SocialTile(
                        leadingIcon: Icon(
                          Ionicons.logoGithub,
                          color: context.colorScheme.primary,
                        ),
                        title: 'Github',
                        url: Uri.parse('https://github.com/erengun'),
                      ),
                      const Gap(5),
                      SocialTile(
                        leadingIcon: Icon(
                          Ionicons.logoLinkedin,
                          color: context.colorScheme.primary,
                        ),
                        title: 'Linkedin',
                        url: Uri.parse('https://www.linkedin.com/in/erengun'),
                      ),
                      const Gap(5),
                      SocialTile(
                        leadingIcon: Icon(
                          Ionicons.logoMedium,
                          color: context.colorScheme.primary,
                        ),
                        title: 'Medium',
                        url: Uri.parse('https://erengun.medium.com/'),
                      ),
                      const Gap(5),
                      SocialTile(
                        leadingIcon: Icon(
                          Ionicons.globeOutline,
                          color: context.colorScheme.primary,
                        ),
                        title: 'Website',
                        url: Uri.parse('https://erengun.dev'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the permission demo screens. The demo loader grants profile and
/// settings but not reports, so reports opens Core's no-permission page.
class _PermissionDemoLinks extends StatelessWidget {
  const _PermissionDemoLinks();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(l10n.demoPermissionsTitle),
          ActionChip(
            label: Text(l10n.demoProfileTitle),
            onPressed: () => context.push(SGRoute.profile.route),
          ),
          ActionChip(
            label: Text(l10n.demoSettingsTitle),
            onPressed: () => context.push(SGRoute.settings.route),
          ),
          ActionChip(
            label: Text(l10n.demoReportsTitle),
            onPressed: () => context.push(SGRoute.reports.route),
          ),
        ],
      ),
    );
  }
}
