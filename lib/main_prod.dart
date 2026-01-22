import 'flavors/app_flavor.dart';
import 'main.dart' as app;

Future<void> main() async {
  print('prod');
  FlavorConfig.setFlavor(AppFlavor.prod);
  await app.bootstrap();
}
