import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every ARB file in the repo keeps one key order, so two branches adding
/// keys rarely touch the same lines: `@@locale` first, then the keys sorted
/// by name, each `@key` metadata block right after its key.
void main() {
  group('arbOrderProblems', () {
    test('accepts a well-ordered file', () {
      expect(
        arbOrderProblems(<String>[
          '@@locale',
          'alpha',
          '@alpha',
          'beta',
          'gamma',
          '@gamma',
        ]),
        isEmpty,
      );
    });

    test('rejects a file that does not start with @@locale', () {
      expect(arbOrderProblems(<String>['alpha', '@@locale']), isNotEmpty);
    });

    test('rejects unsorted keys', () {
      expect(arbOrderProblems(<String>['@@locale', 'beta', 'alpha']), isNotEmpty);
    });

    test('rejects metadata away from its key', () {
      expect(
        arbOrderProblems(<String>['@@locale', 'alpha', 'beta', '@alpha']),
        isNotEmpty,
      );
    });

    test('rejects metadata for a missing key', () {
      expect(arbOrderProblems(<String>['@@locale', '@alpha']), isNotEmpty);
    });
  });

  test('every ARB file in the repo keeps the key order', () {
    final List<File> files = _arbFiles(_repoRoot());
    expect(files, isNotEmpty, reason: 'no ARB files found');

    final Map<String, List<String>> problems = <String, List<String>>{};
    for (final File file in files) {
      final Object? json = jsonDecode(file.readAsStringSync());
      final List<String> keys = (json! as Map<String, Object?>).keys.toList();
      final List<String> fileProblems = arbOrderProblems(keys);
      if (fileProblems.isNotEmpty) problems[file.path] = fileProblems;
    }

    expect(problems, isEmpty);
  });
}

/// The order problems in an ARB file whose keys are [keys], in file order.
List<String> arbOrderProblems(List<String> keys) {
  final List<String> problems = <String>[];
  if (keys.isEmpty || keys.first != '@@locale') {
    problems.add('the first key must be @@locale');
  }

  String? previous;
  for (int i = 0; i < keys.length; i++) {
    final String key = keys[i];
    if (key == '@@locale') continue;
    if (key.startsWith('@')) {
      final String owner = key.substring(1);
      if (i == 0 || keys[i - 1] != owner) {
        problems.add('$key must come right after $owner');
      }
      continue;
    }
    if (previous != null && previous.compareTo(key) >= 0) {
      problems.add('$key must come before $previous');
    }
    previous = key;
  }
  return problems;
}

/// The repo root: tests run from `app/`, whose parent holds the workspace
/// pubspec.
Directory _repoRoot() {
  Directory directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !File(
        '${directory.path}/pubspec.yaml',
      ).readAsStringSync().contains('workspace:')) {
    final Directory parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('workspace root not found');
    }
    directory = parent;
  }
  return directory;
}

/// Every `*.arb` file under [root], skipping hidden folders and `build/`.
List<File> _arbFiles(Directory root) {
  final List<File> files = <File>[];
  for (final FileSystemEntity entity in root.listSync(followLinks: false)) {
    final String name = entity.uri.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .last;
    if (entity is Directory) {
      if (name.startsWith('.') || name == 'build') continue;
      files.addAll(_arbFiles(entity));
    } else if (entity is File && name.endsWith('.arb')) {
      files.add(entity);
    }
  }
  return files;
}
