import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Native project files that no build in CI runs: a release build that
/// misses one of these still compiles, then fails on users' devices.
/// Paths are relative to `app/`, where `flutter test` runs.
void main() {
  group('network access', () {
    test('the main Android manifest declares INTERNET', () {
      // Debug and profile manifests add it for the Flutter tool; a release
      // build gets only the main manifest (plus whatever plugins merge in),
      // and Core's network layer needs it without any Module.
      final String manifest = _read('android/app/src/main/AndroidManifest.xml');

      expect(
        manifest,
        contains('<uses-permission android:name="android.permission.INTERNET"'),
      );
    });

    for (final String file in <String>[
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      test('$file allows outgoing connections', () {
        expect(
          _read(file),
          matches(
            RegExp(
              r'<key>com\.apple\.security\.network\.client</key>\s*<true/>',
            ),
          ),
        );
      });
    }
  });

  group('identity', () {
    test('the macOS copyright comes from Identity.xcconfig', () {
      expect(
        _read('Identity.xcconfig'),
        matches(RegExp(r'^IDENTITY_MACOS_COPYRIGHT = \S', multiLine: true)),
      );
      expect(
        _read('macos/Runner/Configs/AppInfo.xcconfig'),
        matches(
          RegExp(
            r'^PRODUCT_COPYRIGHT = \$\(IDENTITY_MACOS_COPYRIGHT\)$',
            multiLine: true,
          ),
        ),
      );
    });

    test('the Linux window title comes from APP_NAME', () {
      expect(
        _read('linux/CMakeLists.txt'),
        matches(RegExp(r'^set\(APP_NAME "[^"]+"\)$', multiLine: true)),
      );
      final String runner = _read('linux/runner/CMakeLists.txt');
      expect(runner, contains(r'APPLICATION_TITLE=\"${APP_NAME}\"'));
      expect(runner, isNot(contains(r'APPLICATION_TITLE="${BINARY_NAME}"')));
    });
  });
}

String _read(String path) => File(path).readAsStringSync();
