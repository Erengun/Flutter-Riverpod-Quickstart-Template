import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const String _componentKey = 'widgetbook.control';

/// A form section behind a [PermissionGate], with [rule] as its component
/// rule. `permissionsProvider` is overridden like the gate's tests do.
Widget _gated(ComponentState? rule, String caption) {
  return ProviderScope(
    overrides: <Override>[
      permissionsProvider.overrideWithValue(
        Permissions(
          components: <String, ComponentState>{_componentKey: ?rule},
        ),
      ),
    ],
    child: Builder(
      builder: (BuildContext context) {
        final KonteynerTokens tokens = KonteynerTokens.of(context);
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(caption, style: Theme.of(context).textTheme.bodySmall),
                    SizedBox(height: tokens.spaceMd),
                    PermissionGate(
                      componentKey: _componentKey,
                      child: Column(
                        key: const ValueKey<String>('gated-control'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            initialValue: 'eve.holt@reqres.in',
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: tokens.spaceSm),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'No rule',
  type: PermissionGate,
  path: '[Core]/permissions',
)
Widget buildPermissionGateNoRule(BuildContext context) {
  return _gated(null, 'No rule: the control is shown and works.');
}

@widgetbook.UseCase(
  name: 'Hidden',
  type: PermissionGate,
  path: '[Core]/permissions',
)
Widget buildPermissionGateHidden(BuildContext context) {
  return _gated(
    ComponentState.hidden,
    'Hidden: the control below is removed.',
  );
}

@widgetbook.UseCase(
  name: 'Readonly',
  type: PermissionGate,
  path: '[Core]/permissions',
)
Widget buildPermissionGateReadonly(BuildContext context) {
  return _gated(
    ComponentState.readonly,
    'Readonly: shown as it is, but taps and focus never reach it.',
  );
}

@widgetbook.UseCase(
  name: 'Disabled',
  type: PermissionGate,
  path: '[Core]/permissions',
)
Widget buildPermissionGateDisabled(BuildContext context) {
  return _gated(
    ComponentState.disabled,
    'Disabled: greyed out, and taps and focus never reach it.',
  );
}
