import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ui_file.dart';

/// Reports a reference in a UI file (see [isUiFile]) to a backend provider:
/// any identifier named `*RepositoryProvider`, or `dioProvider`,
/// `apiCallProvider`, `dioInterceptorsProvider`, `authInterceptorProvider` or
/// `sessionBoxProvider`.
///
/// A UI file draws from its controller's UI model and Core's providers; only
/// the controller calls repositories. The providers are matched by name, not
/// by where they are declared, because `package:core/core.dart` is one barrel
/// that also exports the providers a UI file may read. Names in `show` and
/// `hide` combinators are not references and are not reported.
class UiNoBackendProviders extends AnalysisRule {
  UiNoBackendProviders()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const LintCode code = LintCode(
    'ui_no_backend_providers',
    "A UI file can't read '{0}'.",
    correctionMessage:
        "Move the call into the screen's controller and read its UI model "
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
    registry.addSimpleIdentifier(this, _Visitor(this, context));
  }
}

/// The backend providers a UI file may not read, besides
/// `*RepositoryProvider`.
const Set<String> _backendProviders = <String>{
  'dioProvider',
  'apiCallProvider',
  'dioInterceptorsProvider',
  'authInterceptorProvider',
  'sessionBoxProvider',
};

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final String name = node.name;
    if (!_backendProviders.contains(name) &&
        !name.endsWith('RepositoryProvider')) {
      return;
    }
    if (node.parent is Combinator) return;
    final Uri? current = context.currentUnit?.unit.declaredFragment?.source.uri;
    if (current == null || !isUiFile(current)) return;
    rule.reportAtNode(node, arguments: <Object>[name]);
  }
}
