// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:konteyner_lints/src/no_cross_feature_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoCrossFeatureImportsTest);
  });
}

@reflectiveTest
class NoCrossFeatureImportsTest extends AnalysisRuleTest {
  String get _features => '$testPackageLibPath/features';

  @override
  void setUp() {
    rule = NoCrossFeatureImports();
    // Another package with a Feature folder of its own.
    newPackage('other').addFile('lib/features/orders/order.dart', 'class Order {}');
    super.setUp();
    newFile('$_features/login/data/login_repository.dart', 'class LoginRepository {}');
    newFile('$_features/login/login.dart', 'class Login {}');
    newFile('$_features/orders/presentation/orders_screen.dart', 'class OrdersScreen {}');
    newFile('$testPackageLibPath/shared/button.dart', 'class Button {}');
  }

  // Forbidden

  Future<void> test_relativeImportFromAnotherFeature() async {
    const String content = '''
import '../../login/data/login_repository.dart';
LoginRepository? r;
''';
    final String path = '$_features/orders/data/orders_repository.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 40)]);
  }

  Future<void> test_packageImportFromAnotherFeature() async {
    const String content = '''
import 'package:test/features/login/login.dart';
Login? l;
''';
    final String path = '$_features/orders/presentation/orders_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 40)]);
  }

  Future<void> test_exportFromAnotherFeature() async {
    const String content = '''
export '../login/login.dart';
''';
    final String path = '$_features/orders/orders.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 21)]);
  }

  Future<void> test_featureFolderNameIsPrefixOfAnother() async {
    newFile('$_features/login_extra/extra.dart', 'class Extra {}');
    const String content = '''
import '../login_extra/extra.dart';
Extra? e;
''';
    final String path = '$_features/login/uses_extra.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 27)]);
  }

  Future<void> test_conditionalImportFromAnotherFeature() async {
    newFile('$_features/orders/orders_stub.dart', 'class Login {}');
    const String content = '''
import '../orders_stub.dart' if (dart.library.io) '../../login/login.dart';
Login? l;
''';
    final String path = '$_features/orders/data/orders_io.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(50, 24)]);
  }

  Future<void> test_conditionalExportFromAnotherFeature() async {
    newFile('$_features/orders/orders_stub.dart', 'class Login {}');
    const String content = '''
export 'orders_stub.dart' if (dart.library.html) '../login/login.dart';
''';
    final String path = '$_features/orders/orders.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(49, 21)]);
  }

  Future<void> test_conditionalImportWithDefaultFromAnotherFeature() async {
    newFile('$_features/orders/orders_io.dart', 'class Login {}');
    const String content = '''
import '../../login/login.dart' if (dart.library.io) '../orders_io.dart';
Login? l;
''';
    final String path = '$_features/orders/data/orders_data.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 24)]);
  }

  Future<void> test_conditionalExportWithDefaultFromAnotherFeature() async {
    newFile('$_features/orders/orders_io.dart', 'class Login {}');
    const String content = '''
export '../login/login.dart' if (dart.library.io) 'orders_io.dart';
''';
    final String path = '$_features/orders/orders.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 21)]);
  }

  Future<void> test_conditionalImportBothUrisFromOtherFeatures() async {
    newFile('$_features/payments/payments.dart', 'class Login {}');
    const String content = '''
import '../../login/login.dart' if (dart.library.io) '../../payments/payments.dart';
Login? l;
''';
    final String path = '$_features/orders/data/orders_data.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[
      lint(7, 24),
      lint(53, 30),
    ]);
  }

  // Allowed

  Future<void> test_importFromSameFeature() async {
    const String content = '''
import '../data/login_repository.dart';
import 'package:test/features/login/login.dart';
LoginRepository? r;
Login? l;
''';
    final String path = '$_features/login/presentation/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_conditionalImportWithinSameFeature() async {
    newFile('$_features/login/login_io.dart', 'class Login {}');
    const String content = '''
import 'login.dart' if (dart.library.io) 'login_io.dart';
Login? l;
''';
    final String path = '$_features/login/uses_login.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_featureImportsShared() async {
    const String content = '''
import '../../shared/button.dart';
Button? b;
''';
    final String path = '$_features/login/login_button.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_featureImportsSdkAndOtherPackages() async {
    const String content = '''
import 'dart:async';
import 'package:other/features/orders/order.dart';
Future<void>? f;
Order? o;
''';
    final String path = '$_features/login/sdk_user.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_appFolderImportsSeveralFeatures() async {
    const String content = '''
import '../features/login/login.dart';
import '../features/orders/presentation/orders_screen.dart';
Login? l;
OrdersScreen? o;
''';
    final String path = '$testPackageLibPath/app/routes.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFileImportsSeveralFeatures() async {
    const String content = '''
import 'package:test/features/login/login.dart';
import 'package:test/features/orders/presentation/orders_screen.dart';
Login? l;
OrdersScreen? o;
''';
    final String path = '$testPackageTestPath/features_test.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_fileDirectlyInFeaturesFolder() async {
    const String content = '''
import 'login/login.dart';
Login? l;
''';
    final String path = '$_features/features.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }
}
