import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vault_pass_mobile/src/common/configs/app_config.dart';
import 'package:vault_pass_mobile/src/core/domain/base_response.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/datasources/local_storage.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/datasources/network/api/configs/endpoint.dart';

class RestfulRequest {
  late final Dio _dio;
  late final Dio _refreshDio;
  final String baseUrl;
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
  RestfulRequest({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _refreshDio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecuredStorage.instance.accessToken;
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        debugPrint('[HTTP REQ] ${options.method}: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[HTTP RES] ${response.requestOptions.path} -> ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        debugPrint('[HTTP ERR] ${error.requestOptions.path} -> ${error.response?.statusCode} (${error.type}: ${error.message})');
        if (error.response?.statusCode == 401) {
          final currentToken = await SecuredStorage.instance.accessToken;
          final reqAuth = error.requestOptions.headers['Authorization']?.toString();
          if (currentToken != null && reqAuth != null && reqAuth != 'Bearer $currentToken') {
            final opts = Options(
              method: error.requestOptions.method,
              headers: {
                ...error.requestOptions.headers,
                'Authorization': 'Bearer $currentToken',
              },
            );
            try {
              final cloneReq = await _dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (retryErr) {
              if (retryErr is DioException) return handler.reject(retryErr);
              return handler.reject(error);
            }
          }
          final refreshed = await _handleTokenRefresh();
          if (refreshed) {
            final newToken = await SecuredStorage.instance.accessToken;
            final opts = Options(
              method: error.requestOptions.method,
              headers: {
                ...error.requestOptions.headers,
                'Authorization': 'Bearer $newToken',
              },
            );
            try {
              final cloneReq = await _dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (retryErr) {
              if (retryErr is DioException) return handler.reject(retryErr);
              return handler.reject(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
  Future<bool> _handleTokenRefresh() async {
    if (_isRefreshing) {
      debugPrint('[MUTEX QUEUE] Request waiting for token refresh...');
      return await (_refreshCompleter?.future ?? Future.value(false));
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    debugPrint('[MUTEX LOCK] Initiating single token refresh call...');
    try {
      final oldRefreshToken = await SecuredStorage.instance.refreshToken;
      if (oldRefreshToken == null) {
        _isRefreshing = false;
        _refreshCompleter?.complete(false);
        return false;
      }
      final response = await _refreshDio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': oldRefreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();
        await SecuredStorage.instance.saveAccessToken(newAccessToken);
        await SecuredStorage.instance.saveRefreshToken(newRefreshToken);
        debugPrint('[MUTEX UNLOCK] Token refresh succeeded. Unlocking queue.');
        _isRefreshing = false;
        _refreshCompleter?.complete(true);
        return true;
      }
      debugPrint('[MUTEX UNLOCK] Token refresh rejected by server.');
      await SecuredStorage.instance.clearAll();
      _isRefreshing = false;
      _refreshCompleter?.complete(false);
      return false;
    } catch (e) {
      debugPrint('[MUTEX UNLOCK] Token refresh exception: $e');
      await SecuredStorage.instance.clearAll();
      _isRefreshing = false;
      _refreshCompleter?.complete(false);
      return false;
    }
  }
  Future<BaseResponse> requestData(EndpointType endpoint) async {
    try {
      final response = await _dio.request(
        endpoint.path,
        data: endpoint.params,
        queryParameters: endpoint.queryParameters,
        options: Options(
          headers: endpoint.headers,
          method: endpoint.method.value,
          responseType: endpoint.responseType,
          validateStatus: (status) => status != null && status <= 500,
        ),
      );
      final json = response.data;
      if (json == null) return const BaseResponse();
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return BaseResponse.fromSuccessJson(json);
      }
      return BaseResponse.fromErrorJson(json is Map<String, dynamic> ? json : {'message': json.toString()});
    } catch (e) {
      return BaseResponse.fromErrorJson({'message': e.toString()});
    }
  }
}
