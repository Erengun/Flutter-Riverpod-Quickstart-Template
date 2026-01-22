import 'flavors/app_flavor.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.setFlavor(AppFlavor.staging);
  await app.bootstrap();
}
