import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: UnderConstructionPage,
  path: '[Core]/permissions',
)
Widget buildUnderConstructionPage(BuildContext context) {
  return UnderConstructionPage(onBackHome: () {});
}
