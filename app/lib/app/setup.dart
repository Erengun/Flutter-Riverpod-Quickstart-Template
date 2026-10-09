import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:material_ui/material_ui.dart';

import '../hive/hive.dart';
import '../my_app.dart';

/// App-owned startup work that runs before Core's `bootstrap`.
Future<void> setUpApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FlutterDisplayMode.setHighRefreshRate();
  }
}

/// The root widget `bootstrap` runs inside its `ProviderScope`.
Widget buildAppRoot() => const MyApp();
