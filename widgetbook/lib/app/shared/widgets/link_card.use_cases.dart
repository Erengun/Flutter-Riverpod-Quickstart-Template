import 'package:core/core.dart';
import 'package:flutter_riverpod_template/shared/widgets/link_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// A card that opens its link in the browser when tapped.
@widgetbook.UseCase(name: 'Default', type: LinkCard, path: '[App]/shared')
Widget buildLinkCard(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: EdgeInsets.all(CoreTokens.of(context).spaceMd),
      child: LinkCard(
        title: 'Github',
        icon: Icons.code,
        url: Uri.parse('https://github.com/erengun'),
      ),
    ),
  );
}
