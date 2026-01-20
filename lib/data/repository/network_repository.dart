import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants/endpoints.dart';
import '../../utils/cachefor_extension.dart';

part 'network_repository.g.dart';

/// A repository class that extends _$NetworkRepository to handle network-related operations.
/// This class serves as an abstraction layer for managing network requests and responses,
/// providing a clean interface for the rest of the application to interact with network data.
@Riverpod(keepAlive: true)
class NetworkRepository extends _$NetworkRepository {
  @override
  Dio build() {
    final Dio dio = Dio(BaseOptions(baseUrl: Endpoints.baseUrl));
    // Accept: application/json"
    dio.options.headers['Accept'] = 'application/json';

    // Content-Type: application/json
    dio.options.headers['Content-Type'] = 'application/json';

    // set api key
    dio.options.headers['x-api-key'] = Endpoints.apiKey;

    /// Add Logger for debugging
    dio.interceptors
      ..add(
        LogInterceptor(
          responseBody: true,
          requestBody: true,
          logPrint: (Object object) {
            /// Prefer using developer.log for better logging in Flutter
            /// and secure logging practices.
            developer.log(object.toString());
          },
        ),
      )
      ..add(RetryInterceptor(dio: dio)) // dio_smart_retry
      ..add(
        DioCacheInterceptor(options: CacheOptions(store: MemCacheStore())),
      ); // dio_cache_interceptor
    return dio;
  }

  String get baseUrl => state.options.baseUrl;

  set baseUrl(String baseUrl) {
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
