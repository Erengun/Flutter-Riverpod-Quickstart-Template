final RegExp _numeric = RegExp(r'^\d+$');
final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// [uri]'s path with numeric and UUID segments replaced by `:id`, so
/// `/orders/42` and `/orders/7` group together. Query values are dropped.
String normalizeRequestPath(Uri uri) {
  final String path = uri.path.isEmpty ? '/' : uri.path;
  return path
      .split('/')
      .map(
        (String segment) =>
            _numeric.hasMatch(segment) || _uuid.hasMatch(segment)
            ? ':id'
            : segment,
      )
      .join('/');
}
