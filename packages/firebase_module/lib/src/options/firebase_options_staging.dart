// Placeholder: the template ships without a Firebase project.
//
// `melos run firebase:configure:staging` replaces this file with the options
// `flutterfire configure` generates for the staging Firebase project. Commit the
// generated file; its values are identifiers, not secrets.
import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import '../firebase_not_configured.dart';

/// Has the same shape as the generated class, so the Module reads either.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw const FirebaseNotConfiguredException(Flavor.staging);
}
