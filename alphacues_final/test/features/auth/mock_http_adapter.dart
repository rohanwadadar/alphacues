import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// Records requests and returns queued mock responses for Dio tests.
class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter({this.responses = const []});

  final List<MockResponse> responses;
  final List<RequestOptions> requests = [];

  int _index = 0;
  Future<void> _serial = Future<void>.value();

  void enqueue(MockResponse response) {
    responses.add(response);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final previous = _serial;
    final gate = Completer<void>();
    _serial = gate.future;
    await previous;

    try {
      requests.add(options);
      if (_index >= responses.length) {
        throw DioException(
          requestOptions: options,
          message: 'No mock response queued',
        );
      }
      final mock = responses[_index++];
      if (mock.beforeRespond != null) {
        await mock.beforeRespond;
      }
      return ResponseBody.fromString(
        jsonEncode(mock.body),
        mock.statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          ...mock.headers,
        },
      );
    } finally {
      gate.complete();
    }
  }

  @override
  void close({bool force = false}) {}
}

class MockResponse {
  const MockResponse({
    required this.body,
    this.statusCode = 200,
    this.headers = const <String, List<String>>{},
    this.beforeRespond,
  });

  final Map<String, dynamic> body;
  final int statusCode;
  final Map<String, List<String>> headers;
  final Future<void>? beforeRespond;
}

Dio createTestDio(MockHttpAdapter adapter, {String baseUrl = 'http://test'}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.httpClientAdapter = adapter;
  return dio;
}
