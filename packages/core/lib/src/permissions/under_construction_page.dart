import 'package:material_ui/material_ui.dart';

import '../../l10n/core_localizations.dart';
import 'message_page.dart';

/// Core's "under construction" page: where a `PermissionMenu` entry leads
/// when its key has no screen yet.
class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({required this.onBackHome, super.key});

  /// Leaves the page, usually `context.go(<home path>)`; Core doesn't know
  /// the app's routes.
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final CoreLocalizations l10n = CoreLocalizations.of(context);
    return MessagePage(
      icon: Icons.construction_outlined,
      iconColor: Theme.of(context).colorScheme.primary,
      title: l10n.underConstructionTitle,
      body: l10n.underConstructionBody,
      buttonLabel: l10n.pageBackHome,
      onPressed: onBackHome,
    );
  }
}
