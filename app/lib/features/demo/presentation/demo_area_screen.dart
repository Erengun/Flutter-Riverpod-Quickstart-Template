import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

/// A placeholder screen guarded by one Permission area, to show the route
/// guard: the demo loader grants some areas and leaves one out.
class DemoAreaScreen extends StatelessWidget {
  const DemoAreaScreen({required this.title, required this.area, super.key});

  final String title;

  /// The Permission area the route declares.
  final String area;

  @override
  Widget build(BuildContext context) {
    final KonteynerTokens tokens = KonteynerTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Text(
            AppLocalizations.of(context).demoAreaBody(area),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
