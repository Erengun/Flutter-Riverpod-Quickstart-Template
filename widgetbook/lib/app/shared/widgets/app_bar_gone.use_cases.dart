import 'package:core/core.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/shared/widgets/app_bar_gone.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// An app bar of no height that only sets the status bar's color and icon
/// brightness from the theme, so the body starts at the top of the screen.
@widgetbook.UseCase(name: 'Default', type: EmptyAppBar, path: '[App]/shared')
Widget buildEmptyAppBar(BuildContext context) {
  return Scaffold(
    appBar: const EmptyAppBar(),
    body: Padding(
      padding: EdgeInsets.all(CoreTokens.of(context).spaceMd),
      child: Text(AppLocalizations.of(context).homeIntro),
    ),
  );
}
