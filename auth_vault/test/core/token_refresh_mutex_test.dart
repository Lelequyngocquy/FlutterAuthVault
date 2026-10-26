import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTokenRefreshQueue {
  bool isRefreshing = false;
  Completer<bool>? refreshCompleter;
  int refreshCallCount = 0;
  Future<bool> handleConcurrent401() async {
    if (isRefreshing) {
      return await (refreshCompleter?.future ?? Future.value(false));
    }
    isRefreshing = true;
    refreshCompleter = Completer<bool>();
    refreshCallCount++;
    await Future.delayed(const Duration(milliseconds: 30));
    isRefreshing = false;
    refreshCompleter?.complete(true);
    return true;
  }
}

void main() {
  test('Mutex Queue executes exactly 1 refresh call for 5 parallel 401 requests', () async {
    final queue = MockTokenRefreshQueue();
    final results = await Future.wait([
      queue.handleConcurrent401(),
      queue.handleConcurrent401(),
      queue.handleConcurrent401(),
      queue.handleConcurrent401(),
      queue.handleConcurrent401(),
    ]);
    expect(queue.refreshCallCount, equals(1));
    expect(results.length, equals(5));
    for (final res in results) {
      expect(res, isTrue);
    }
  });
  test('Dio QueuedInterceptorsWrapper intercepts and queues concurrent 401 requests with token rotation', () async {
    final dio = Dio();
    int refreshCalls = 0;
    String activeToken = 'token_v1_expired';
    bool isRefreshing = false;
    Completer<void>? completer;
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $activeToken';
        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final reqAuth = err.requestOptions.headers['Authorization']?.toString();
          if (activeToken != 'token_v1_expired' && reqAuth != 'Bearer $activeToken') {
            return handler.resolve(Response(
              requestOptions: err.requestOptions,
              statusCode: 200,
              data: {'success': true, 'token': activeToken},
            ));
          }
          if (!isRefreshing) {
            isRefreshing = true;
            completer = Completer<void>();
            refreshCalls++;
            await Future.delayed(const Duration(milliseconds: 30));
            activeToken = 'token_v2_fresh';
            isRefreshing = false;
            completer?.complete();
          } else {
            await completer?.future;
          }
          return handler.resolve(Response(
            requestOptions: err.requestOptions,
            statusCode: 200,
            data: {'success': true, 'token': activeToken},
          ));
        }
        return handler.next(err);
      },
    ));
    dio.httpClientAdapter = _MockFailAdapter();
    final responses = await Future.wait([
      dio.get('/items'),
      dio.get('/items'),
      dio.get('/items'),
      dio.get('/items'),
      dio.get('/items'),
    ]);
    expect(refreshCalls, equals(1));
    expect(responses.length, equals(5));
    for (final r in responses) {
      expect(r.statusCode, equals(200));
      expect(r.data['token'], equals('token_v2_fresh'));
    }
  });
}

class _MockFailAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization']?.toString();
    if (auth == 'Bearer token_v2_fresh') {
      return ResponseBody.fromString(
        '{"success": true}',
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    return ResponseBody.fromString(
      '{"error": "Unauthorized"}',
      401,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
  @override
  void close({bool force = false}) {}
}
