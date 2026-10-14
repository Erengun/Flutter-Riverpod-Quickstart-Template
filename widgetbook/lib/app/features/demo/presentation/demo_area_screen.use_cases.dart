import 'package:flutter_riverpod_template/features/demo/presentation/demo_area_screen.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_riverpod_template/shared/permission_keys.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// The placeholder screen the router opens for a granted demo area, here
/// the orders area. It reads no providers, so it needs no `FakeScope`.
@widgetbook.UseCase(
  name: 'Granted area',
  type: DemoAreaScreen,
  path: '[App]/demo',
)
Widget buildDemoAreaScreen(BuildContext context) {
  return DemoAreaScreen(
    title: AppLocalizations.of(context).demoOrdersTitle,
    area: AppAreas.orders,
  );
}
