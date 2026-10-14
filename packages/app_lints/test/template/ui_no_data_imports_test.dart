// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:app_lints/src/template/ui_no_data_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UiNoDataImportsTest);
  });
}

@reflectiveTest
class UiNoDataImportsTest extends AnalysisRuleTest {
  String get _auth => '$testPackageLibPath/features/auth';

  String get _login => '$_auth/presentation/login';

  @override
  void setUp() {
    rule = UiNoDataImports();
    // Another package with a Feature data/ folder of its own.
    newPackage('other').addFile(
      'lib/features/orders/data/order_repository.dart',
      'class OrderRepository {}',
    );
    super.setUp();
    newFile('$_auth/data/auth_repository.dart', 'class AuthRepository {}');
    newFile('$_auth/domain/user.dart', 'class User {}');
    // A barrel outside data/ that re-exports a data/ file.
    newFile('$_auth/auth.dart', "export 'data/auth_repository.dart';");
    newFile('$_login/login_stub.dart', 'class AuthRepository {}');
    newFile('$testPackageLibPath/shared/keys.dart', 'class Keys {}');
  }

  // Forbidden

  Future<void> test_relativeImportInScreen() async {
    const String content = '''
import '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 33)]);
  }

  Future<void> test_packageImportInScreen() async {
    const String content = '''
import 'package:test/features/auth/data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 54)]);
  }

  Future<void> test_exportFromUiFile() async {
    const String content = '''
export '../../data/auth_repository.dart';
''';
    final String path = '$_login/login.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 33)]);
  }

  Future<void> test_newFileInPresentationIsUiFile() async {
    const String content = '''
import '../../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/widgets/brand_new_thing.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 36)]);
  }

  Future<void> test_sharedWidgetImportsData() async {
    const String content = '''
import '../../features/auth/data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$testPackageLibPath/shared/widgets/user_card.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 47)]);
  }

  Future<void> test_importOfAnotherPackagesData() async {
    const String content = '''
import 'package:other/features/orders/data/order_repository.dart';
OrderRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 58)]);
  }

  Future<void> test_conditionalImportOfData() async {
    const String content = '''
import 'login_stub.dart' if (dart.library.io) '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(46, 33)]);
  }

  Future<void> test_conditionalImportWithDataAsDefault() async {
    const String content = '''
import '../../data/auth_repository.dart' if (dart.library.io) 'login_stub.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 33)]);
  }

  Future<void> test_conditionalExportOfData() async {
    const String content = '''
export 'login_stub.dart' if (dart.library.html) '../../data/auth_repository.dart';
''';
    final String path = '$_login/login.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(48, 33)]);
  }

  // Allowed

  Future<void> test_controllerImportsData() async {
    const String content = '''
import '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_controller.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_uiModelImportsData() async {
    const String content = '''
import '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/auth_ui_model.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_generatedFileImportsData() async {
    const String content = '''
import '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.g.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_freezedFileImportsData() async {
    const String content = '''
import '../../data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$_login/auth_ui_model.freezed.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_barrelReExportingDataIsAKnownGap() async {
    // The barrel lib/features/auth/auth.dart re-exports data/; only the URI
    // the UI file names is checked, so this gets past the rule.
    const String content = '''
import '../../auth.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_uiFileImportsDomainSharedAndSdk() async {
    const String content = '''
import 'dart:async';
import '../../../../shared/keys.dart';
import '../../domain/user.dart';
import 'login_stub.dart';
Future<void>? f;
Keys? k;
User? u;
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_conditionalImportWithoutData() async {
    newFile('$_login/login_io.dart', 'class AuthRepository {}');
    const String content = '''
import 'login_stub.dart' if (dart.library.io) 'login_io.dart';
AuthRepository? r;
''';
    final String path = '$_login/login_screen.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_dataFileImportsData() async {
    newFile('$_auth/data/auth_api.dart', 'class AuthApi {}');
    const String content = '''
import 'auth_api.dart';
AuthApi? a;
''';
    final String path = '$_auth/data/http_auth_repository.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_sharedFileOutsideWidgetsImportsData() async {
    const String content = '''
import '../features/auth/data/auth_repository.dart';
AuthRepository? r;
''';
    final String path = '$testPackageLibPath/shared/session_tools.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_catalogMirroredPathImportsData() async {
    // The catalog mirrors the app's paths under lib/app/; it isn't UI code.
    const String content = '''
import 'package:test/features/auth/data/auth_repository.dart';
AuthRepository? r;
''';
    final String path =
        '$testPackageLibPath/app/features/auth/presentation/login/'
        'login_screen.use_cases.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFileImportsData() async {
    const String content = '''
import 'package:test/features/auth/data/auth_repository.dart';
AuthRepository? r;
''';
    final String path =
        '$testPackageTestPath/features/auth/presentation/login_screen_test.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }
}
