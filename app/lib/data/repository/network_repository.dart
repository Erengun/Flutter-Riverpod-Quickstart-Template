import 'dart:async';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/cachefor_extension.dart';

part 'network_repository.g.dart';

/// A repository class that extends _$NetworkRepository to handle network-related operations.
/// This class serves as an abstraction layer for managing network requests and responses,
/// providing a clean interface for the rest of the application to interact with network data.
@Riverpod(keepAlive: true)
class NetworkRepository extends _$NetworkRepository {
  static final Logger _log = Logger('network');

  @override
  Dio build() {
    final AppConfig config = ref.watch(appConfigProvider);
    final Dio dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
    // Accept: application/json"
    dio.options.headers['Accept'] = 'application/json';

    // Content-Type: application/json
    dio.options.headers['Content-Type'] = 'application/json';

    // The demo backend's key; never secret in a client app.
    dio.options.headers['x-api-key'] = config.apiKey;

    /// Add Logger for debugging
    dio.interceptors
      ..add(
        LogInterceptor(
          responseBody: true,
          requestBody: true,
          // FINE: kept on dev only. Never raise it to INFO, or request and
          // response bodies would become breadcrumbs.
          logPrint: (Object object) => _log.fine(object.toString()),
        ),
      )
      ..add(RetryInterceptor(dio: dio)) // dio_smart_retry
      ..add(
        DioCacheInterceptor(options: CacheOptions(store: MemCacheStore())),
      ); // dio_cache_interceptor
    return dio;
  }

  void setBaseUrl(String baseUrl) {
    state.options.baseUrl = baseUrl;
  }

  void setApiKey(String apiKey) {
    state.options.headers['x-api-key'] = apiKey;
  }

  void setToken(String token) {
    state.options.headers['Authorization'] = 'Bearer $token';

    /// Cache the token for 1 day
    ref.cacheFor(const Duration(days: 1));
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
  }) async {
    if (baseUrl != null) {
      state.options.baseUrl = baseUrl;
    }
    return state.get(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
  }) async {
    if (baseUrl != null) {
      state.options.baseUrl = baseUrl;
    }
    return state.post(path, data: data, queryParameters: queryParameters);
  }
}
