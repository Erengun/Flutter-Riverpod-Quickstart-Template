import 'package:hive_ce/hive.dart';

import '../features/authentication/domain/login_request.dart';

/// Every type stored in a Hive box. Add new ones here and rerun
/// build_runner; `hive_registrar.g.dart` registers them.
@GenerateAdapters(<AdapterSpec<dynamic>>[AdapterSpec<LoginCredentials>()])
part 'hive_adapters.g.dart';
