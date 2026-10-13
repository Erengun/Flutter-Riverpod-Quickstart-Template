import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'ui_file.dart';

/// Reports an import or export in a UI file (see [isUiFile]) of anything in a
/// Feature's `data/` folder (`lib/features/<feature>/data/`), by relative or
/// `package:` URI, conditional import URIs included.
///
/// A UI file draws from its controller's UI model and Core's providers; only
/// the controller calls repositories. Known gap: a barrel outside `data/`
/// that re-exports a `data/` file is not reported, since only the URI the UI
/// file names is checked.
class UiNoDataImports extends AnalysisRule {
  UiNoDataImports()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'ui_no_data_imports',
    "A UI file can't import from a Feature's 'data/' folder.",
    correctionMessage:
        "Read the data through the screen's controller and its UI model "
        'instead.',
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
    if (current == null || !isUiFile(current)) return;

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
    if (_isFeatureData(target)) rule.reportAtNode(uriNode);
  }
}

/// Whether [uri] is `package:<package>/features/<feature>/data/...`.
bool _isFeatureData(Uri uri) {
  if (uri.scheme != 'package') return false;
  final List<String> segments = uri.pathSegments;
  // <package>, features, <feature>, data, and at least the file.
  return segments.length >= 5 &&
      segments[1] == 'features' &&
      segments[3] == 'data';
}
