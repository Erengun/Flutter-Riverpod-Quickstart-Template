// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:app_lints/src/template/no_shrink_wrap.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoShrinkWrapTest);
  });
}

@reflectiveTest
class NoShrinkWrapTest extends AnalysisRuleTest {
  static const String _shrinkWrapTrue = '''
import 'package:flutter/widgets.dart';

Widget list = CustomScrollView(shrinkWrap: true);
''';

  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = NoShrinkWrap();
    super.setUp();
  }

  // Forbidden

  Future<void> test_trueInFeature() async {
    final String path =
        '$testPackageLibPath/features/home/presentation/home_screen.dart';
    newFile(path, _shrinkWrapTrue);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(71, 16)]);
  }

  Future<void> test_trueOutsideFeatures() async {
    // Core's widgets and lib/app/ are covered too: the rule is for all of lib/.
    final String path = '$testPackageLibPath/src/widgets/list.dart';
    newFile(path, _shrinkWrapTrue);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(71, 16)]);
  }

  Future<void> test_nonLiteralValue() async {
    const String content = '''
import 'package:flutter/widgets.dart';

const bool wrap = false;
Widget list = CustomScrollView(shrinkWrap: wrap);
''';
    final String path = '$testPackageLibPath/shared/widgets/list.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(96, 16)]);
  }

  Future<void> test_anyCallsNamedArgument() async {
    const String content = '''
int layout({bool shrinkWrap = false}) => 0;
int size = layout(shrinkWrap: true);
''';
    final String path = '$testPackageLibPath/app/layout.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(62, 16)]);
  }

  // Allowed

  Future<void> test_literalFalse() async {
    const String content = '''
import 'package:flutter/widgets.dart';

Widget list = CustomScrollView(shrinkWrap: false);
''';
    final String path = '$testPackageLibPath/features/home/list.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_materialTapTargetSizeShrinkWrap() async {
    const String content = '''
enum MaterialTapTargetSize { padded, shrinkWrap }

int button({MaterialTapTargetSize? tapTargetSize}) => 0;
int b = button(tapTargetSize: MaterialTapTargetSize.shrinkWrap);
MaterialTapTargetSize size = MaterialTapTargetSize.shrinkWrap;
''';
    final String path = '$testPackageLibPath/features/login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_ignoredNestedCase() async {
    const String content = '''
import 'package:flutter/widgets.dart';

// ignore: no_shrink_wrap
Widget list = CustomScrollView(shrinkWrap: true);
''';
    final String path = '$testPackageLibPath/shared/widgets/nested_list.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_inTest() async {
    final String path = '$testPackageTestPath/list_test.dart';
    newFile(path, _shrinkWrapTrue);
    await assertNoDiagnosticsInFile(path);
  }
}
