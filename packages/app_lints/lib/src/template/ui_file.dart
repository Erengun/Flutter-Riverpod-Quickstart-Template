/// Whether [uri] is a UI file.
///
/// A UI file is any file under `app/lib/features/<feature>/presentation/` or
/// `app/lib/shared/widgets/` except `*_controller.dart`, `*_ui_model.dart`
/// and generated files (`*.g.dart`, `*.freezed.dart`). UI files belong to the
/// Designer; controllers and UI models belong to developers.
///
/// It checks `lib/features/<feature>/presentation/**` and
/// `lib/shared/widgets/**` of any package, given as `package:` URIs. Any other
/// file name, including a new one, makes a UI file. Files outside `lib/` (such
/// as tests) and the catalog's mirrored paths (`lib/app/features/...` in
/// `widgetbook/`) are not UI files. Every rule that needs "UI file" uses this
/// one classifier.
bool isUiFile(Uri uri) {
  if (uri.scheme != 'package') return false;
  final List<String> segments = uri.pathSegments;
  final bool inPresentation =
      // <package>, features, <feature>, presentation, and at least the file.
      segments.length >= 5 &&
      segments[1] == 'features' &&
      segments[3] == 'presentation';
  final bool inSharedWidgets =
      // <package>, shared, widgets, and at least the file.
      segments.length >= 4 &&
      segments[1] == 'shared' &&
      segments[2] == 'widgets';
  if (!inPresentation && !inSharedWidgets) return false;
  return !_developerOwnedSuffixes.any(segments.last.endsWith);
}

/// File name endings of the files in UI folders that aren't UI files.
const List<String> _developerOwnedSuffixes = <String>[
  '_controller.dart',
  '_ui_model.dart',
  '.g.dart',
  '.freezed.dart',
];
