import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'app_code.dart';

/// Reports a call to Flutter's `State.setState` in app code
/// (`lib/features/` and `lib/shared/`).
///
/// App state lives in Riverpod providers. Core's widgets may still use
/// `setState`. A call that resolves to a class's own `setState` method (not
/// `State.setState`) is not reported.
class NoSetState extends AnalysisRule {
  NoSetState()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'no_set_state',
    "App code can't call 'setState'.",
    correctionMessage:
        'Keep the state in a provider and watch it, or keep only a '
        'TextEditingController, FocusNode or AnimationController in the State.',
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
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final SimpleIdentifier name = node.methodName;
    if (name.name != 'setState') return;
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null || !isAppCode(current)) return;
    if (_isFlutterSetState(name.element)) rule.reportAtNode(name);
  }

  /// Whether [element] is `setState` declared on Flutter's `State`. An
  /// unresolved call is not reported.
  bool _isFlutterSetState(Element? element) {
    if (element is! MethodElement) return false;
    final Element? owner = element.enclosingElement;
    return owner is ClassElement &&
        owner.name == 'State' &&
        owner.library.uri.toString() ==
            'package:flutter/src/widgets/framework.dart';
  }
}
