import 'package:core/core.dart';
import 'package:flutter_riverpod_template/shared/widgets/grid_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// A link tile in a two-column grid, as the app lays them out; tapping one
// opens its link in the browser.

/// A tile with a version line under its title.
@widgetbook.UseCase(name: 'With version', type: GridItem, path: '[App]/shared')
Widget buildGridItemWithVersion(BuildContext context) {
  return _InGrid(
    child: GridItem(
      title: 'Riverpod',
      icon: Icons.water_drop_outlined,
      url: Uri.parse('https://riverpod.dev'),
      version: '3.0.0',
    ),
  );
}

/// A tile with only its icon and title.
@widgetbook.UseCase(
  name: 'Without version',
  type: GridItem,
  path: '[App]/shared',
)
Widget buildGridItemWithoutVersion(BuildContext context) {
  return _InGrid(
    child: GridItem(
      title: 'Flutter',
      icon: Icons.flutter_dash,
      url: Uri.parse('https://flutter.dev'),
    ),
  );
}

/// One grid cell's size, so a single tile looks as it does in the app.
class _InGrid extends StatelessWidget {
  const _InGrid({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CoreTokens tokens = CoreTokens.of(context);
    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(tokens.spaceMd),
        mainAxisSpacing: tokens.spaceSm,
        crossAxisSpacing: tokens.spaceSm,
        children: <Widget>[child],
      ),
    );
  }
}
