// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:konteyner_lints/src/tokens_only_in_theme.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokensOnlyInThemeTest);
  });
}

@reflectiveTest
class TokensOnlyInThemeTest extends AnalysisRuleTest {
  String get _app => '$testPackageLibPath/app';

  @override
  void setUp() {
    rule = TokensOnlyInTheme();
    // Another package with a tokens file of its own.
    newPackage('other')
        .addFile('lib/app/tokens.dart', 'const int otherGap = 8;');
    super.setUp();
    newFile('$_app/tokens.dart', 'const int gap = 8;');
    newFile('$_app/tokens_stub.dart', 'const int gap = 8;');
    newFile(
      '$testPackageLibPath/features/login/tokens.dart',
      'const int gap = 8;',
    );
  }

  // Forbidden

  Future<void> test_relativeImportFromFeature() async {
    const String content = '''
import '../../../app/tokens.dart';
int g = gap;
''';
    final String path =
        '$testPackageLibPath/features/login/presentation/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 26)]);
  }

  Future<void> test_importFromAnotherAppFile() async {
    const String content = '''
import 'tokens.dart';
int g = gap;
''';
    final String path = '$_app/config.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 13)]);
  }

  Future<void> test_packageImportFromTest() async {
    const String content = '''
import 'package:test/app/tokens.dart';
int g = gap;
''';
    final String path = '$testPackageTestPath/theme_test.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 30)]);
  }

  Future<void> test_relativeImportFromTest() async {
    const String content = '''
import '../lib/app/tokens.dart';
int g = gap;
''';
    final String path = '$testPackageTestPath/theme_test.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 24)]);
  }

  Future<void> test_importOfAnotherPackagesTokens() async {
    const String content = '''
import 'package:other/app/tokens.dart';
int g = otherGap;
''';
    final String path = '$testPackageLibPath/widgets/card.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 31)]);
  }

  Future<void> test_themeOfAnotherPackageImportsTokens() async {
    // This package's theme.dart may import only this package's tokens.
    const String content = '''
import 'package:other/app/tokens.dart';
int g = otherGap;
''';
    final String path = '$_app/theme.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 31)]);
  }

  Future<void> test_export() async {
    const String content = '''
export 'tokens.dart';
''';
    final String path = '$_app/app.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 13)]);
  }

  Future<void> test_conditionalImport() async {
    const String content = '''
import 'tokens_stub.dart' if (dart.library.io) 'tokens.dart';
int g = gap;
''';
    final String path = '$_app/config.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(47, 13)]);
  }

  Future<void> test_conditionalImportWithTokensAsDefault() async {
    const String content = '''
import 'tokens.dart' if (dart.library.io) 'tokens_stub.dart';
int g = gap;
''';
    final String path = '$_app/config.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 13)]);
  }

  // Allowed

  Future<void> test_themeImportsTokensRelatively() async {
    const String content = '''
import 'tokens.dart';
int g = gap;
''';
    final String path = '$_app/theme.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_themeImportsTokensByPackageUri() async {
    const String content = '''
import 'package:test/app/tokens.dart';
int g = gap;
''';
    final String path = '$_app/theme.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_otherFileNamedTokens() async {
    const String content = '''
import '../features/login/tokens.dart';
int g = gap;
''';
    final String path = '$_app/config.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_otherAppFiles() async {
    newFile('$_app/config.dart', 'const int config = 1;');
    const String content = '''
import 'dart:async';
import 'config.dart';
Future<void>? f;
int c = config;
''';
    final String path = '$_app/modules.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }
}
