import 'package:core/core.dart';

import '../shared/permission_keys.dart';
import 'app_router.dart';

/// The menu's entries, in order: Permission area keys. This app's menu is a
/// fixed list; an app whose backend sends the menu tree builds this list
/// from it instead.
const List<String> appMenuKeys = <String>[
  AppAreas.profile,
  AppAreas.settings,
  AppAreas.reports,
  AppAreas.orders,
];

/// Core's menu filter for [appMenuKeys]: the route of each key that has a
/// screen. A key left out (orders) opens the under-construction page.
final PermissionMenu appMenu = PermissionMenu(
  routes: <String, String>{
    AppAreas.profile: SGRoute.profile.route,
    AppAreas.settings: SGRoute.settings.route,
    AppAreas.reports: SGRoute.reports.route,
  },
  underConstructionPath: SGRoute.underConstruction.route,
);
