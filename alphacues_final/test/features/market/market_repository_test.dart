import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/market/data/market_repository.dart';

import '../auth/mock_http_adapter.dart';

Map<String, dynamic> _barsEnvelope() {
  return {
    'success': true,
    'data': {
      'symbol': 'AAPL',
      'bars': [
        {
          'timeStamp': '2026-05-13T14:30:00Z',
          'openPrice': 188.12,
          'highPrice': 189.02,
          'lowPrice': 187.98,
          'closePrice': 188.90,
          'volume': 1823400,
        },
      ],
    },
    'error': null,
    'meta': {
      'requestId': 'e5f22e08-a2a4-4d82-b8cd-1f7c3e7d1c5f',
      'apiVersion': '1',
    },
  };
}

void main() {
  for (final entry in kRangeToTimeframe.entries) {
    test('fetchBars sends timeframe ${entry.value} for range ${entry.key}', () async {
      final adapter = MockHttpAdapter(
        responses: [MockResponse(body: _barsEnvelope())],
      );
      final dio = createTestDio(adapter);
      final repository = MarketRepository(dio);

      final bars = await repository.fetchBars('AAPL', entry.key);

      expect(bars, hasLength(1));
      expect(adapter.requests, hasLength(1));

      final request = adapter.requests.single;
      expect(request.path, '/api/v1/market/bars');
      expect(request.queryParameters['symbol'], 'AAPL');
      expect(request.queryParameters['range'], entry.key);
      expect(request.queryParameters['timeframe'], entry.value);
    });
  }
  
  test('searchSymbols sends correct query and parses response', () async {
    final adapter = MockHttpAdapter(
      responses: [
        MockResponse(body: {
          'success': true,
          'data': [
            {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'exchange': 'NASDAQ'},
            {'symbol': 'AAPL', 'name': 'Apple Inc.', 'exchange': 'NASDAQ'},
          ],
          'error': null,
          'meta': {'requestId': 'req-1', 'apiVersion': '1'}
        }),
      ],
    );
    final dio = createTestDio(adapter);
    final repository = MarketRepository(dio);

    final results = await repository.searchSymbols('ms', limit: 2);

    expect(results, hasLength(2));
    expect(results[0].symbol, 'MSFT');
    expect(results[1].symbol, 'AAPL');

    final request = adapter.requests.single;
    expect(request.path, '/api/v1/market/search');
    expect(request.queryParameters['q'], 'ms');
    expect(request.queryParameters['limit'], 2);
  });
}
