import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports a `shrinkWrap:` named argument whose value isn't the literal
/// `false`, in any file under a package's `lib/`.
///
/// A shrink-wrapped scroll view lays out all its children at once. Use a
/// non-scrolling `Column` for a short fixed list, and `ListView.builder` or
/// slivers for one of unknown length. `MaterialTapTargetSize.shrinkWrap` is
/// not an argument name and never matches. A nested case that really needs
/// it uses `// ignore: no_shrink_wrap`.
class NoShrinkWrap extends AnalysisRule {
  NoShrinkWrap()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'no_shrink_wrap',
    "Don't use 'shrinkWrap'.",
    correctionMessage:
        'Use a Column for a short fixed list, or ListView.builder or slivers '
        'inside a CustomScrollView instead.',
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
    registry.addNamedArgument(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme != 'shrinkWrap') return;
    // Files under lib/ have package: URIs; tests and tools have file: URIs.
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null || current.scheme != 'package') return;
    final Expression value = node.argumentExpression;
    if (value is BooleanLiteral && !value.value) return;
    rule.reportAtNode(node);
  }
}
