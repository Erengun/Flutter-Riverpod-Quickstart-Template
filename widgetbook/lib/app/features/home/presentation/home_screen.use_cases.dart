import 'package:core/core.dart';
import 'package:flutter_riverpod_template/fakes/fake_scope.dart';
import 'package:flutter_riverpod_template/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod_template/shared/permission_keys.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// The demo home screen, signed in, one use case per set of permissions. Its
// links need the app's router, so they do nothing here. The theme and
// language switches save the choice, but the catalog's theme and locale
// come from its addons.

/// The demo permissions: reports is missing, so the menu leaves it out, and
/// the component rules row shows a readonly, a disabled and a hidden
/// control.
@widgetbook.UseCase(
  name: 'Demo permissions',
  type: HomeScreen,
  path: '[App]/home',
)
Widget buildHomeScreen(BuildContext context) {
  return const FakeScope(seed: FakeSeed(signedIn: true), child: HomeScreen());
}

/// Every area granted and no component rules: the menu lists every area and
/// every control in the component rules row is shown and enabled.
@widgetbook.UseCase(name: 'All granted', type: HomeScreen, path: '[App]/home')
Widget buildHomeScreenAllGranted(BuildContext context) {
  return const FakeScope(
    seed: FakeSeed(
      signedIn: true,
      permissions: Permissions(
        areas: <String>{
          AppAreas.profile,
          AppAreas.settings,
          AppAreas.reports,
          AppAreas.orders,
        },
      ),
    ),
    child: HomeScreen(),
  );
}
