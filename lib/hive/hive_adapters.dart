// lib/hive/hive_adapters.dart   ← keep registrar but REMOVE the spec
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../config/theme/theme_ui_model.dart';
import '../features/authentication/domain/login_request.dart';

// ignore: always_specify_types
@GenerateAdapters([
  AdapterSpec<LoginCredentials>(),
  AdapterSpec<ThemeUiModel>(),
  // Add other models here
]) // or just omit the list entirely
part 'hive_adapters.g.dart';
