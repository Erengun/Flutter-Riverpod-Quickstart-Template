import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

import '../config/app_config.dart';
import '../config/flavor_check.dart';
import '../config/konteyner_platform.dart';
import '../modules/konteyner_module.dart';
import 'app_shell.dart';

/// Starts the app. Each flavor entrypoint (`main_<flavor>.dart`) calls it
/// with its own [config].
///
/// In order, it:
/// 1. throws [FlavorMismatchError] on Android and iOS when the native
///    `--flavor` differs from [config]'s flavor, in every build mode;
/// 2. starts [modules] (see [startModules]);
/// 3. runs [app] inside a `ProviderScope` that overrides
///    [appConfigProvider], [konteynerThemeProvider], [splashProvider] and the
///    interfaces the Modules contributed.
///
/// [theme] holds the app's light and dark themes. [splash] replaces Core's
/// default progress indicator.
Future<void> bootstrap(
  AppConfig config, {
  required Widget app,
  required KonteynerTheme theme,
  Widget splash = const KonteynerSplash(),
  List<KonteynerModule> modules = const <KonteynerModule>[],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final KonteynerPlatform platform = KonteynerPlatform.current;
  checkNativeFlavor(config.flavor, nativeFlavor: appFlavor, platform: platform);

  if (kReleaseMode) {
    // Silence debugPrint in release builds.
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Readable stack traces in release builds.
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  final StartedModules started = await startModules(
    modules,
    config,
    platform: platform,
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
        konteynerThemeProvider.overrideWithValue(theme),
        splashProvider.overrideWithValue(splash),
        ...started.overrides,
      ],
      child: app,
    ),
  );
}
