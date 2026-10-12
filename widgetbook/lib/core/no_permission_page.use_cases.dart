import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: NoPermissionPage,
  path: '[Core]/permissions',
)
Widget buildNoPermissionPage(BuildContext context) {
  return NoPermissionPage(onBackHome: () {});
}
