import 'package:material_ui/material_ui.dart';

import '../../l10n/core_localizations.dart';
import '../theme/konteyner_tokens.dart';

/// Core's "no permission" page: where `permissionRedirect` sends a user who
/// opens a route outside their Permission areas.
class NoPermissionPage extends StatelessWidget {
  const NoPermissionPage({required this.onBackHome, super.key});

  /// Leaves the page, usually `context.go(<home path>)`; Core doesn't know
  /// the app's routes.
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final CoreLocalizations l10n = CoreLocalizations.of(context);
    final KonteynerTokens tokens = KonteynerTokens.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.noPermissionTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                size: tokens.spaceXl * 2,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: tokens.spaceMd),
              Text(
                l10n.noPermissionBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: tokens.spaceLg),
              FilledButton.tonal(
                onPressed: onBackHome,
                child: Text(l10n.pageBackHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
