import 'package:core/core.dart';
import 'package:firebase_module/firebase_module.dart';

/// The Modules this app opts into, started in order by `bootstrap`.
///
/// To add a Module, depend on its `packages/<name>_module` package and list
/// it here. To remove one, delete it here, from the app's dependencies and
/// from the workspace.
List<KonteynerModule> buildAppModules() => <KonteynerModule>[
  const FirebaseModule(),
];
