import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen and Shared widget of the app has a use case at its mirrored
/// path: `app/lib/features/home/presentation/home_screen.dart` has
/// `widgetbook/lib/app/features/home/presentation/home_screen.use_cases.dart`.
/// The app checks the widget tests the same way
/// (`app/test/conventions/screen_tests_test.dart`).
void main() {
  group('needsUseCase', () {
    test('counts screens anywhere under a presentation folder', () {
      expect(
        needsUseCase('features/home/presentation/home_screen.dart'),
        isTrue,
      );
      expect(
        needsUseCase('features/auth/presentation/login/login_screen.dart'),
        isTrue,
      );
    });

    test('skips other Feature files', () {
      expect(
        needsUseCase(
          'features/auth/presentation/register/register_dialog.dart',
        ),
        isFalse,
      );
      expect(
        needsUseCase('features/home/presentation/widgets/header.dart'),
        isFalse,
      );
      expect(needsUseCase('features/home/data/home_screen.dart'), isFalse);
      expect(
        needsUseCase('features/home/presentation/home_screen.g.dart'),
        isFalse,
      );
    });

    test('counts files directly under shared/widgets/', () {
      expect(needsUseCase('shared/widgets/link_card.dart'), isTrue);
    });

    test('skips generated, nested and other shared files', () {
      expect(needsUseCase('shared/widgets/link_card.g.dart'), isFalse);
      expect(needsUseCase('shared/widgets/card.freezed.dart'), isFalse);
      expect(needsUseCase('shared/widgets/cards/link_card.dart'), isFalse);
      expect(needsUseCase('shared/permission_keys.dart'), isFalse);
    });
  });

  test('mirroredUseCasePath swaps .dart for .use_cases.dart', () {
    expect(
      mirroredUseCasePath('features/home/presentation/home_screen.dart'),
      'features/home/presentation/home_screen.use_cases.dart',
    );
  });

  test('every screen and Shared widget has a mirrored use case', () {
    final Directory root = _repoRoot();
    final List<String> counted = _dartFiles(Directory('${root.path}/app/lib'))
        .where(needsUseCase)
        .toList();
    expect(counted, isNotEmpty, reason: 'no screens found');

    final List<String> missing = <String>[
      for (final String path in counted)
        if (!File(
          '${root.path}/widgetbook/lib/app/${mirroredUseCasePath(path)}',
        ).existsSync())
          'widgetbook/lib/app/${mirroredUseCasePath(path)} (for app/lib/$path)',
    ];

    expect(missing, isEmpty, reason: 'use cases are missing');
  });
}

/// Whether the file at [path] (relative to `app/lib/`) needs a use case and
/// a widget test: a `*_screen.dart` under `features/<feature>/presentation/`,
/// or a non-generated file directly under `shared/widgets/`.
bool needsUseCase(String path) {
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

/// The use case file for [path], both relative to their folders.
String mirroredUseCasePath(String path) =>
    '${path.substring(0, path.length - '.dart'.length)}.use_cases.dart';

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

/// The repo root: tests run from `widgetbook/`, whose parent holds the
/// workspace pubspec.
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
