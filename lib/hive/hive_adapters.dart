// lib/hive/hive_adapters.dart   ← keep registrar but REMOVE the spec
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

import '../config/theme/theme_ui_model.dart';
import '../features/authentication/domain/login_request.dart';

@GenerateAdapters(<AdapterSpec<dynamic>>[
  AdapterSpec<LoginCredentials>(),
  AdapterSpec<ThemeUiModel>(),
  // Add other models here
]) // or just omit the list entirely
part 'hive_adapters.g.dart';
