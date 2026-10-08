import 'package:core/core.dart';
import 'package:flutter_riverpod_template/app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each flavor config carries its own flavor', () {
    expect(devConfig.flavor, Flavor.dev);
    expect(stagingConfig.flavor, Flavor.staging);
    expect(prodConfig.flavor, Flavor.prod);
  });

  test('every flavor has a base URL and a demo key', () {
    for (final AppConfig config in <AppConfig>[
      devConfig,
      stagingConfig,
      prodConfig,
    ]) {
      expect(Uri.parse(config.apiBaseUrl).isAbsolute, isTrue);
      expect(config.apiKey, isNotEmpty);
    }
  });
}
