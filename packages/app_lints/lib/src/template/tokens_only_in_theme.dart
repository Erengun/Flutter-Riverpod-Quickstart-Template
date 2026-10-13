import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports an import or export of a package's design tokens file
/// (`lib/app/tokens.dart`) from anywhere but that package's theme file
/// (`lib/app/theme.dart`).
///
/// The tokens file holds raw values. Only the theme turns them into
/// `ThemeData` and theme extensions; widgets read them through
/// `Theme.of(context)`. Tests and other packages are reported too.
class TokensOnlyInTheme extends AnalysisRule {
  TokensOnlyInTheme()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'tokens_only_in_theme',
    "Only 'lib/app/theme.dart' can import 'lib/app/tokens.dart'.",
    correctionMessage:
        'Read the value through Theme.of(context) (ThemeData or a theme '
        'extension filled in lib/app/theme.dart) instead.',
    // A warning, like no_cross_feature_imports, so it fails `dart analyze`.
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final _Visitor visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _checkDirective(node);

  @override
  void visitExportDirective(ExportDirective node) => _checkDirective(node);

  /// Checks the default URI and every conditional URI separately, like
  /// no_cross_feature_imports: the default is resolved from its own string,
  /// because the analyzer's resolved URI is a configuration's URI when
  /// declared variables (`-D`) pick one.
  void _checkDirective(NamespaceDirective node) {
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null) return;

    final String? defaultUri = node.uri.stringValue;
    final Uri? relative = defaultUri == null ? null : Uri.tryParse(defaultUri);
    if (relative != null) {
      _check(current, node.uri, current.resolveUri(relative));
    }
    for (final Configuration configuration in node.configurations) {
      final DirectiveUri? target = configuration.resolvedUri;
      if (target is DirectiveUriWithSource) {
        _check(current, configuration.uri, target.source.uri);
      }
    }
  }

  void _check(Uri current, StringLiteral uriNode, Uri target) {
    if (!_isAppFile(target, 'tokens.dart')) return;
    // The theme file of the same package is the only allowed importer.
    if (_isAppFile(current, 'theme.dart') &&
        _packageOf(current) == _packageOf(target)) {
      return;
    }
    rule.reportAtNode(uriNode);
  }
}

/// Whether [uri] is `lib/app/<name>` of a package: either
/// `package:<package>/app/<name>`, or a `file:` URI ending in
/// `/lib/app/<name>` (a relative import from outside `lib/`, such as a test).
bool _isAppFile(Uri uri, String name) {
  final List<String> segments = uri.pathSegments;
  if (uri.scheme == 'package') {
    return segments.length == 3 && segments[1] == 'app' && segments[2] == name;
  }
  final int n = segments.length;
  return n >= 3 &&
      segments[n - 3] == 'lib' &&
      segments[n - 2] == 'app' &&
      segments[n - 1] == name;
}

/// The package name of a `package:` URI, or the package root path of a
/// `file:` URI inside `lib/`.
String _packageOf(Uri uri) {
  final List<String> segments = uri.pathSegments;
  if (uri.scheme == 'package') return segments.first;
  final int lib = segments.lastIndexOf('lib');
  return segments.take(lib < 0 ? 0 : lib).join('/');
}
