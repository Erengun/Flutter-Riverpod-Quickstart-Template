import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports an import or export from one Feature folder
/// (`lib/features/<feature>/`) into another Feature folder of the same
/// package.
///
/// A Feature depends on Core and on the Modules the app opted into, never on
/// another Feature. Moving between Features goes through the router. Files
/// outside `lib/features/<feature>/` (such as `lib/app/` or `test/`) may
/// import any Feature.
class NoCrossFeatureImports extends AnalysisRule {
  NoCrossFeatureImports()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'no_cross_feature_imports',
    "The Feature '{0}' can't import from the Feature '{1}'.",
    correctionMessage:
        'Move the shared code to Core or lib/shared/, or navigate through '
        'the router instead.',
    // A warning, like riverpod_lint's rules, so it stands out in the IDE and
    // fails `dart analyze` with the default `--fatal-warnings`.
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
  void visitImportDirective(ImportDirective node) =>
      _check(node, node.libraryImport?.uri);

  @override
  void visitExportDirective(ExportDirective node) =>
      _check(node, node.libraryExport?.uri);

  void _check(UriBasedDirective node, DirectiveUri? target) {
    if (target is! DirectiveUriWithSource) return;
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null) return;

    final _Feature? from = _Feature.of(current);
    if (from == null) return;
    final _Feature? to = _Feature.of(target.source.uri);
    if (to == null) return;

    if (from.package == to.package && from.name != to.name) {
      rule.reportAtNode(node.uri, arguments: <Object>[from.name, to.name]);
    }
  }
}

/// The Feature folder a `package:` URI belongs to, if any.
class _Feature {
  const _Feature(this.package, this.name);

  final String package;
  final String name;

  /// Returns the Feature for `package:<package>/features/<name>/...`, or null
  /// when [uri] isn't inside a Feature folder.
  static _Feature? of(Uri uri) {
    if (uri.scheme != 'package') return null;
    final List<String> segments = uri.pathSegments;
    // <package>, features, <name>, and at least one more segment.
    if (segments.length < 4 || segments[1] != 'features') return null;
    return _Feature(segments[0], segments[2]);
  }
}
