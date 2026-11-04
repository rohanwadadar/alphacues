import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/features/dashboard/data/dashboard_repository.dart';
import 'package:frontend/features/portfolio/data/portfolio_providers.dart';

///import 'package:frontend/features/portfolio/data/portfolio_repository.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _MockPortfolioRepository extends PortfolioRepository {
  _MockPortfolioRepository() : super(Dio());

  var summaryCalls = 0;
  var transactionsCalls = 0;
  var createCalls = 0;

  @override
  Future<PortfolioOverview> getPortfolioSummary() async {
    summaryCalls++;
    return PortfolioOverview(
      summary: PortfolioSummary(
        portfolioId: '1',
        totalValue: 1000,
        availableBalance: 0,
        totalProfit: 50,
        totalReturn: 5,
        dayChange: 1,
        asOf: '2026-05-13T14:30:00Z',
      ),
      positions: const [
        PortfolioPosition(
          symbol: 'AAPL',
          volume: 10,
          totalPrice: 1800,
          updatedAt: '2026-05-13T14:30:00Z',
        ),
      ],
    );
  }

  @override
  Future<({List<PortfolioEvent> items, String? nextCursor})>
  getPortfolioTransactions({String? cursor, int limit = 20}) async {
    transactionsCalls++;
    return (
      items: const [
        PortfolioEvent(
          eventId: 'evt-1',
          timeStamp: '2026-05-13T14:30:00Z',
          userId: '1',
          symbol: 'AAPL',
          action: 'BUY',
          price: 180,
          volume: 10,
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<String> createEvent({
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
    required String idempotencyKey,
  }) async {
    createCalls++;
    return 'evt-2';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createEvent invalidates summary and transactions providers', () async {
    final repository = _MockPortfolioRepository();
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(portfolioSummaryProvider.future);
    await container.read(portfolioTransactionsProvider.future);
    expect(repository.summaryCalls, 1);
    expect(repository.transactionsCalls, 1);

    await container
        .read(portfolioEventFormProvider.notifier)
        .submitCreate(
          symbol: 'TSLA',
          action: 'BUY',
          volume: 2,
          price: 250,
          timeStamp: formatPortfolioEventTimestamp(DateTime.now()),
          idempotencyKey: 'test-key',
        );

    await container.read(portfolioSummaryProvider.future);
    await container.read(portfolioTransactionsProvider.future);

    expect(repository.createCalls, 1);
    expect(repository.summaryCalls, 2);
    expect(repository.transactionsCalls, 2);
  });

  test('live quote patches portfolio without refetching summary', () async {
    final repository = _MockPortfolioRepository();
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(portfolioSummaryProvider.future);
    expect(repository.summaryCalls, 1);

    container.read(portfolioSummaryProvider.notifier).patchQuote(
          const QuoteUpdatePayload(
            symbol: 'AAPL',
            lastPrice: 190,
            changeAmount: 2,
            changePercent: 1.06,
            asOf: '2026-05-13T14:31:00Z',
          ),
        );

    final updated = container.read(portfolioSummaryProvider).requireValue;
    expect(repository.summaryCalls, 1);
    expect(updated.positions.single.lastPrice, 190);
    expect(updated.summary.totalValue, initial.summary.totalValue);
    expect(updated.summary.asOf, '2026-05-13T14:31:00Z');
  });
}
