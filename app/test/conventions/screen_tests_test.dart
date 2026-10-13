import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen and Shared widget has a widget test at its mirrored path:
/// `app/lib/features/home/presentation/home_screen.dart` is tested in
/// `app/test/features/home/presentation/home_screen_test.dart`. The catalog
/// checks the use cases the same way (`widgetbook/test/catalog_coverage_test.dart`).
void main() {
  group('needsWidgetTest', () {
    test('counts screens anywhere under a presentation folder', () {
      expect(
        needsWidgetTest('features/home/presentation/home_screen.dart'),
        isTrue,
      );
      expect(
        needsWidgetTest('features/auth/presentation/login/login_screen.dart'),
        isTrue,
      );
    });

    test('skips other Feature files', () {
      expect(
        needsWidgetTest(
          'features/auth/presentation/register/register_dialog.dart',
        ),
        isFalse,
      );
      expect(
        needsWidgetTest('features/home/presentation/widgets/header.dart'),
        isFalse,
      );
      expect(needsWidgetTest('features/home/data/home_screen.dart'), isFalse);
      expect(
        needsWidgetTest('features/home/presentation/home_screen.g.dart'),
        isFalse,
      );
    });

    test('counts files directly under shared/widgets/', () {
      expect(needsWidgetTest('shared/widgets/link_card.dart'), isTrue);
    });

    test('skips generated, nested and other shared files', () {
      expect(needsWidgetTest('shared/widgets/link_card.g.dart'), isFalse);
      expect(needsWidgetTest('shared/widgets/card.freezed.dart'), isFalse);
      expect(needsWidgetTest('shared/widgets/cards/link_card.dart'), isFalse);
      expect(needsWidgetTest('shared/permission_keys.dart'), isFalse);
    });
  });

  test('mirroredTestPath adds _test before .dart', () {
    expect(
      mirroredTestPath('features/home/presentation/home_screen.dart'),
      'features/home/presentation/home_screen_test.dart',
    );
  });

  test('every screen and Shared widget has a mirrored widget test', () {
    final Directory app = Directory('${_repoRoot().path}/app');
    final List<String> counted = _dartFiles(Directory('${app.path}/lib'))
        .where(needsWidgetTest)
        .toList();
    expect(counted, isNotEmpty, reason: 'no screens found');

    final List<String> missing = <String>[
      for (final String path in counted)
        if (!File('${app.path}/test/${mirroredTestPath(path)}').existsSync())
          'app/test/${mirroredTestPath(path)} (for app/lib/$path)',
    ];

    expect(missing, isEmpty, reason: 'widget tests are missing');
  });
}

/// Whether the file at [path] (relative to `app/lib/`) needs a widget test
/// and a use case: a `*_screen.dart` under `features/<feature>/presentation/`,
/// or a non-generated file directly under `shared/widgets/`.
bool needsWidgetTest(String path) {
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
    return false;
  }
  final List<String> segments = path.split('/');
  if (segments.length >= 4 &&
      segments[0] == 'features' &&
      segments[2] == 'presentation') {
    return segments.last.endsWith('_screen.dart');
  }
  return segments.length == 3 &&
      segments[0] == 'shared' &&
      segments[1] == 'widgets' &&
      segments.last.endsWith('.dart');
}

/// The widget test for [path], both relative to their folders.
String mirroredTestPath(String path) =>
    '${path.substring(0, path.length - '.dart'.length)}_test.dart';

/// Every `.dart` file under [root], relative to it, with `/` separators.
List<String> _dartFiles(Directory root) {
  final String prefix = '${root.absolute.path}${Platform.pathSeparator}';
  return <String>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.absolute.path
            .substring(prefix.length)
            .replaceAll(Platform.pathSeparator, '/'),
  ]..sort();
}

/// The repo root: tests run from `app/`, whose parent holds the workspace
/// pubspec.
Directory _repoRoot() {
  Directory directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !File('${directory.path}/pubspec.yaml')
          .readAsStringSync()
          .contains('workspace:')) {
    final Directory parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('workspace root not found');
    }
    directory = parent;
  }
  return directory;
}
