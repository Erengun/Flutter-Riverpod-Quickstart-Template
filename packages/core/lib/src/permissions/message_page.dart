import 'package:material_ui/material_ui.dart';

import '../theme/konteyner_tokens.dart';

/// The layout Core's full-page messages share: an icon, a title, a body and
/// one button. Not exported.
class MessagePage extends StatelessWidget {
  const MessagePage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final KonteynerTokens tokens = KonteynerTokens.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: tokens.spaceXl * 2, color: iconColor),
              SizedBox(height: tokens.spaceMd),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: tokens.spaceLg),
              FilledButton.tonal(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
