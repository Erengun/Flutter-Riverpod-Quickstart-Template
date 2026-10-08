import 'package:core/core.dart';

// The values that change per flavor. Each `main_<flavor>.dart` passes one to
// `bootstrap`. Nothing here is secret: anything compiled into the app can be
// read back out of it. The template points every flavor at the reqres demo
// backend; replace these with your own backends.

/// reqres's demo key. Demo only: https://reqres.in/signup
const String _reqresDemoKey = 'reqres-free-v1';

const AppConfig devConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'https://reqres.in/',
  apiKey: _reqresDemoKey,
);

const AppConfig stagingConfig = AppConfig(
  flavor: Flavor.staging,
  apiBaseUrl: 'https://reqres.in/',
  apiKey: _reqresDemoKey,
);

const AppConfig prodConfig = AppConfig(
  flavor: Flavor.prod,
  apiBaseUrl: 'https://reqres.in/',
  apiKey: _reqresDemoKey,
  // Add `storeLinks: StoreLinks(...)` once the app is listed in the stores.
  // An empty id or link turns the update check off on that platform.
);
