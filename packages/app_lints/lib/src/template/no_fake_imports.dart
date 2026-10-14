import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports an import or export of a file in a `fakes/` folder (such as
/// `lib/fakes/` or `lib/features/<feature>/fakes/`) from a file under `lib/`
/// that isn't itself in a `fakes/` folder, by relative or `package:` URI,
/// conditional import URIs included.
///
/// Fakes are for tests and the catalog; production code imports none of
/// them. Files outside `lib/` (such as `test/`), files in a `fakes/` folder
/// and the whole catalog package (`widgetbook_catalog`) may import Fakes.
class NoFakeImports extends AnalysisRule {
  NoFakeImports()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'no_fake_imports',
    "Only tests, the catalog and other 'fakes/' folders can import from a "
        "'fakes/' folder.",
    correctionMessage:
        'Depend on the real implementation through its provider, and let '
        'tests and the catalog override it with the Fake.',
    // A warning, like no_cross_feature_imports, so it fails `dart analyze`.
    severity: DiagnosticSeverity.WARNING,
  );

  /// The package of the Widgetbook catalog, which draws screens on Fakes.
  static const String catalogPackage = 'widgetbook_catalog';

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
    // Files under lib/ have package: URIs; tests and tools have file: URIs.
    if (current == null || current.scheme != 'package') return;
    if (current.pathSegments.first == NoFakeImports.catalogPackage) return;
    if (_isInFakes(current)) return;

    final String? defaultUri = node.uri.stringValue;
    final Uri? relative = defaultUri == null ? null : Uri.tryParse(defaultUri);
    if (relative != null) {
      _check(node.uri, current.resolveUri(relative));
    }
    for (final Configuration configuration in node.configurations) {
      final DirectiveUri? target = configuration.resolvedUri;
      if (target is DirectiveUriWithSource) {
        _check(configuration.uri, target.source.uri);
      }
    }
  }

  void _check(StringLiteral uriNode, Uri target) {
    if (_isInFakes(target)) rule.reportAtNode(uriNode);
  }
}

/// Whether the `package:` URI [uri] is inside a `fakes/` folder of its
/// package's `lib/`, at any depth.
bool _isInFakes(Uri uri) {
  if (uri.scheme != 'package') return false;
  final List<String> segments = uri.pathSegments;
  // Skip the package name and the file name: only folders count.
  return segments.length >= 3 &&
      segments.sublist(1, segments.length - 1).contains('fakes');
}
