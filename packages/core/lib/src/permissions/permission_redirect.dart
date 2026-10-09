import 'permissions.dart';

/// The route guard: where the router sends the user for [permissions], or
/// `null` to stay on [location]. Run it after `sessionRedirect` returned
/// `null`: `sessionRedirect(...) ?? permissionRedirect(...)`.
///
/// - [area] is the Permission area the route at [location] declares;
///   `null` means any signed-in user may open it.
/// - While [permissions] are not known yet (`null`), a guarded route waits
///   on [splashPath].
/// - A missing area sends the user to [noPermissionPath]. A link or a direct
///   `go()` to the route hits the same check.
String? permissionRedirect(
  Permissions? permissions,
  String location, {
  required String? area,
  required String splashPath,
  required String noPermissionPath,
}) {
  if (area == null) return null;
  if (permissions == null) return location == splashPath ? null : splashPath;
  if (permissions.can(area)) return null;
  return location == noPermissionPath ? null : noPermissionPath;
}
