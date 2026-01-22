import 'flavors/app_flavor.dart';
import 'main.dart' as app;

Future<void> main() async {
  print('staging');
  FlavorConfig.setFlavor(AppFlavor.staging);
  await app.bootstrap();
}
