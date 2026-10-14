import 'package:core/core.dart';
import 'package:flutter_riverpod_template/shared/widgets/grid_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// A grid of link tiles; tapping one opens its link in the browser.
@widgetbook.UseCase(
  name: 'With and without version',
  type: GridItem,
  path: '[App]/shared',
)
Widget buildGridItem(BuildContext context) {
  final CoreTokens tokens = CoreTokens.of(context);
  return Scaffold(
    body: GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(tokens.spaceMd),
      mainAxisSpacing: tokens.spaceSm,
      crossAxisSpacing: tokens.spaceSm,
      children: <Widget>[
        GridItem(
          title: 'Riverpod',
          icon: Icons.water_drop_outlined,
          url: Uri.parse('https://riverpod.dev'),
          version: '3.0.0',
        ),
        GridItem(
          title: 'Flutter',
          icon: Icons.flutter_dash,
          url: Uri.parse('https://flutter.dev'),
        ),
      ],
    ),
  );
}
