// core/local_storage/hive_box_providers.dart
import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/login_request.dart';

part 'hive_box_providers.g.dart';

/// 1️⃣ Derive a per-device AES-256 key (hash + salt).
Future<List<int>> _deviceKey() async {
  if (kIsWeb) {
    // Web doesn't have a unique device ID, so we use a fixed salt.
    return sha256.convert(utf8.encode('web-device-🔥salt')).bytes;
  }
  final String? rawId = Platform.isAndroid
      ? await const AndroidId().getId()          // android_id pkg
      : await DeviceInfoPlugin().iosInfo
          .then((IosDeviceInfo v) => v.identifierForVendor);   // device_info_plus
  final Uint8List bytes = utf8.encode('$rawId-🔥salt');
  return sha256.convert(bytes).bytes;            // crypto pkg
}

/// 2️⃣ Open the encrypted box.
/// Use `@Riverpod(keepAlive: true)` if you *never* want it disposed;
/// plain `@riverpod` auto-disposes when no-longer-used.
@riverpod
Future<Box<LoginCredentials>> userBox(Ref ref) async {
  await Hive.initFlutter();               // hive_ce_flutter
  final List<int> key = await _deviceKey();
  return Hive.openBox<LoginCredentials>(
    'userBox',
    encryptionCipher: HiveAesCipher(key),        // AES-256-CBC
  );                                            
}

@riverpod
Future<Box<String>> themeBox(Ref ref) async {
  await Hive.initFlutter();               // hive_ce_flutter
  return Hive.openBox<String>(
    'themeBox',
  );                                          
}
