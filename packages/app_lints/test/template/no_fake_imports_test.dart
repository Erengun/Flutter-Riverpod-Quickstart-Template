// test_reflective_loader finds test methods by their test_ prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
// ExpectedDiagnostic is only exported from src/, but lint() returns it.
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:app_lints/src/template/no_fake_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoFakeImportsTest);
  });
}

@reflectiveTest
class NoFakeImportsTest extends AnalysisRuleTest {
  String get _lib => testPackageLibPath;

  @override
  void setUp() {
    rule = NoFakeImports();
    // Another package with Fakes of its own.
    newPackage('other')
        .addFile('lib/fakes/fake_other.dart', 'class FakeOther {}');
    super.setUp();
    newFile('$_lib/fakes/fake_scope.dart', 'class FakeScope {}');
    newFile(
      '$_lib/features/auth/fakes/fake_auth_repository.dart',
      'class FakeAuthRepository {}',
    );
    newFile('$_lib/app/real_scope.dart', 'class FakeScope {}');
  }

  /// Adds the package [name] next to the test package, with its own
  /// `pubspec.yaml`, package config and analysis options enabling the rule,
  /// so its `lib/` files get `package:<name>/` URIs. Returns its root path.
  ///
  /// The package depends on the test package, whose Fakes it imports.
  String _newSiblingPackage(String name) {
    final String root = convertPath('/home/$name');
    newPubspecYamlFile(root, pubspecYamlContent(name: name));
    final PackageConfigFileBuilder config = PackageConfigFileBuilder()
      ..add(name: name, rootFolder: getFolder(root))
      ..add(name: 'test', rootFolder: getFolder(testPackageRootPath));
    newFile('$root/.dart_tool/package_config.json', config.toContent());
    newAnalysisOptionsYamlFile(
      root,
      analysisOptionsContent(rules: <String>[rule.name]),
    );
    return root;
  }

  // Forbidden

  Future<void> test_relativeImportFromAppFolder() async {
    const String content = '''
import '../fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/app/overrides.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 26)]);
  }

  Future<void> test_packageImportFromMain() async {
    const String content = '''
import 'package:test/fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/main.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 36)]);
  }

  Future<void> test_featureImportsItsOwnFakes() async {
    const String content = '''
import '../fakes/fake_auth_repository.dart';
FakeAuthRepository? r;
''';
    final String path = '$_lib/features/auth/data/auth_providers.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 36)]);
  }

  Future<void> test_export() async {
    const String content = '''
export '../fakes/fake_scope.dart';
''';
    final String path = '$_lib/app/app.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 26)]);
  }

  Future<void> test_importOfAnotherPackagesFakes() async {
    const String content = '''
import 'package:other/fakes/fake_other.dart';
FakeOther? o;
''';
    final String path = '$_lib/app/overrides.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 37)]);
  }

  Future<void> test_conditionalImportOfFakes() async {
    const String content = '''
import 'real_scope.dart' if (dart.library.io) '../fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/app/overrides.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(46, 26)]);
  }

  Future<void> test_conditionalImportWithFakesAsDefault() async {
    const String content = '''
import '../fakes/fake_scope.dart' if (dart.library.io) 'real_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/app/overrides.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 26)]);
  }

  Future<void> test_siblingPackageThatIsNotTheCatalog() async {
    // The control for test_catalogImportsFakes: same setup, other name.
    final String root = _newSiblingPackage('other_app');
    const String content = '''
import 'package:test/fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$root/lib/main.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, <ExpectedDiagnostic>[lint(7, 36)]);
  }

  // Allowed

  Future<void> test_fakeImportsAnotherFake() async {
    const String content = '''
import '../features/auth/fakes/fake_auth_repository.dart';
import 'fake_scope.dart';
FakeAuthRepository? r;
FakeScope? s;
''';
    final String path = '$_lib/fakes/fake_storage.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_featureFakeImportsAppFake() async {
    const String content = '''
import 'package:test/fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/features/auth/fakes/fake_session.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_fileInNestedFakesFolder() async {
    const String content = '''
import '../fake_scope.dart';
FakeScope? s;
''';
    final String path = '$_lib/fakes/storage/fake_boxes.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFileImportsFakes() async {
    const String content = '''
import 'package:test/fakes/fake_scope.dart';
import 'package:test/features/auth/fakes/fake_auth_repository.dart';
FakeScope? s;
FakeAuthRepository? r;
''';
    final String path = '$testPackageTestPath/login_test.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFileInFakesFolderImportsFakesRelatively() async {
    const String content = '''
import '../../lib/fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path = '$testPackageTestPath/fakes/fake_scope_test.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_catalogImportsFakes() async {
    final String root = _newSiblingPackage(NoFakeImports.catalogPackage);
    const String content = '''
import 'package:test/fakes/fake_scope.dart';
FakeScope? s;
''';
    final String path =
        '$root/lib/app/features/home/presentation/home_screen.use_cases.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_namesThatOnlyLookLikeFakes() async {
    newFile('$_lib/shared/fake_name.dart', 'class FakeName {}');
    newFile('$_lib/fakes_extra/extra.dart', 'class Extra {}');
    const String content = '''
import '../fakes_extra/extra.dart';
import '../shared/fake_name.dart';
import 'real_scope.dart';
Extra? e;
FakeName? n;
FakeScope? s;
''';
    final String path = '$_lib/app/overrides.dart';
    newFile(path, content);
    await assertNoDiagnosticsInFile(path);
  }
}
