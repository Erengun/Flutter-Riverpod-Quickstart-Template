/// Whether [uri] is app code: a file under `lib/features/` or `lib/shared/`
/// of a package, given as `package:<package>/features/...` or
/// `package:<package>/shared/...`.
///
/// Core's widgets, `lib/app/`, the catalog (`lib/app/features/...` in
/// `widgetbook/`) and files outside `lib/` (such as tests) are not app code.
bool isAppCode(Uri uri) {
  if (uri.scheme != 'package') return false;
  final List<String> segments = uri.pathSegments;
  // <package>, features or shared, and at least one more segment.
  return segments.length >= 3 &&
      (segments[1] == 'features' || segments[1] == 'shared');
}
