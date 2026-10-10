import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../../demo_scope.dart';

/// The demo home screen, signed in with the demo permissions saved: the
/// component rules row shows readonly, disabled and hidden controls, and the
/// menu lists only granted areas. Its links need the app's router, so they
/// do nothing here. The theme and language switches save the choice, but
/// the catalog's theme and locale come from its addons.
@widgetbook.UseCase(
  name: 'Demo permissions',
  type: HomeScreen,
  path: '[App]/home',
)
Widget buildHomeScreen(BuildContext context) {
  return const DemoScope(seed: DemoSeed(signedIn: true), child: HomeScreen());
}
