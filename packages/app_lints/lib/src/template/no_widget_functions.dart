import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'app_code.dart';

/// Reports a top-level function or a method without `@override` whose
/// declared return type is Flutter's `Widget` or a subtype, in app code
/// (`lib/features/` and `lib/shared/`).
///
/// Split a widget into widget classes, which rebuild on their own and keep
/// their own `BuildContext`. Closures, local functions and helpers returning
/// `List<Widget>` are not reported, nor is anything in the catalog
/// (`widgetbook/`), whose `@UseCase` builders are functions by design. An
/// abstract `Widget buildBody()` on a base class is reported too; it needs
/// `// ignore: no_widget_functions`.
class NoWidgetFunctions extends AnalysisRule {
  NoWidgetFunctions()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'no_widget_functions',
    "'{0}' returns a Widget; use a widget class instead.",
    correctionMessage:
        'Move the subtree into its own StatelessWidget or ConsumerWidget.',
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
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Only top-level functions; local functions count as closures.
    if (node.parent is! CompilationUnit) return;
    _check(node.returnType, node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.declaredFragment?.element.metadata.hasOverride ?? false) return;
    _check(node.returnType, node.name);
  }

  void _check(TypeAnnotation? returnType, Token name) {
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null || !isAppCode(current)) return;
    if (_isWidget(returnType?.type)) {
      rule.reportAtToken(name, arguments: <Object>[name.lexeme]);
    }
  }

  /// Whether [type] is Flutter's `Widget` or a subtype of it.
  bool _isWidget(DartType? type) {
    if (type is! InterfaceType) return false;
    return <InterfaceType>[type, ...type.allSupertypes].any(
      (InterfaceType t) =>
          t.element.name == 'Widget' &&
          t.element.library.uri.toString() ==
              'package:flutter/src/widgets/framework.dart',
    );
  }
}
