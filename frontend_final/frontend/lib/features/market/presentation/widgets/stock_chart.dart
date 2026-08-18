import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../dashboard/presentation/widgets/dashboard_formatters.dart';
import '../../data/market_repository.dart';

const _priceBarWidth = 60.0;

/// Candlestick chart for symbol OHLCV bars.
class StockChart extends StatefulWidget {
  const StockChart({
    super.key,
    required this.bars,
    required this.selectedRange,
    required this.isStale,
  });

  final List<Bar> bars;
  final String selectedRange;
  final bool isStale;

  @override
  State<StockChart> createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  final CandlesticksController _controller = CandlesticksController();
  Bar? _selectedBar;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.bars, oldWidget.bars)) {
      _selectedBar = null;
    }
  }

  List<Candle> _toCandles(List<Bar> bars) {
    final sorted = [...bars]
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    final candles = sorted
        .map(
          (bar) => Candle(
            date: DateTime.parse(bar.timeStamp).toUtc(),
            open: bar.openPrice,
            high: bar.highPrice,
            low: bar.lowPrice,
            close: bar.closePrice,
            volume: bar.volume.toDouble(),
          ),
        )
        .toList(growable: true);

    if (candles.length == 1) {
      candles.add(candles.first);
    }

    return candles;
  }

  Bar? _barAtTapPosition({
    required Offset localPosition,
    required double chartWidth,
    required List<Bar> sortedBars,
  }) {
    if (sortedBars.isEmpty || chartWidth <= 0) {
      return null;
    }

    final tapX = localPosition.dx;
    if (tapX < 0 || tapX > chartWidth) {
      return null;
    }

    final viewport = _controller.value;
    final distanceFromRight = chartWidth - tapX;
    final candleIndex =
        (viewport.scrollIndex + distanceFromRight / viewport.candleWidth)
            .round();

    if (candleIndex < 0 || candleIndex >= sortedBars.length) {
      return null;
    }

    return sortedBars[candleIndex];
  }

  void _onChartTapUp(TapUpDetails details, BoxConstraints constraints) {
    final chartWidth = constraints.maxWidth - _priceBarWidth;
    final sortedBars = [...widget.bars]
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    final bar = _barAtTapPosition(
      localPosition: details.localPosition,
      chartWidth: chartWidth,
      sortedBars: sortedBars,
    );

    if (bar == null) {
      return;
    }

    setState(() => _selectedBar = bar);
  }

  String? _lastUpdatedLabel() {
    if (widget.bars.isEmpty) {
      return null;
    }

    final latest = widget.bars
        .map((bar) => bar.timeStamp)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return formatUtcTimestamp(latest);
  }

  @override
  Widget build(BuildContext context) {
     
    final theme = Theme.of(context);

    if (widget.bars.isEmpty) {
      return Card(
        color: AppColors.surfaceAlt,
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'No chart data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final candles = _toCandles(widget.bars);
    final chartStyle = theme.brightness == Brightness.dark
        ? CandleSticksStyle.dark()
        : CandleSticksStyle.light();

    return Card(
      color: AppColors.surfaceAlt,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isStale)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'Last updated ${_lastUpdatedLabel() ?? ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedBar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: _CandleTooltip(bar: _selectedBar!),
            ),
          SizedBox(
            height: 280,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerUp: (event) {
                    if (event.kind == PointerDeviceKind.mouse) {
                      return;
                    }
                    _onChartTapUp(
                      TapUpDetails(
                        kind: event.kind,
                        globalPosition: event.position,
                        localPosition: event.localPosition,
                      ),
                      constraints,
                    );
                  },
                  child: Candlesticks(
                    candles: candles,
                    controller: _controller,
                    style: chartStyle,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CandleTooltip extends StatelessWidget {
  const _CandleTooltip({required this.bar});

  final Bar bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          '${formatUtcTimestamp(bar.timeStamp)}  '
          'O ${formatPrice(bar.openPrice)}  '
          'H ${formatPrice(bar.highPrice)}  '
          'L ${formatPrice(bar.lowPrice)}  '
          'C ${formatPrice(bar.closePrice)}  '
          'V ${bar.volume}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String formatUtcTimestamp(String isoTimestamp) {
  final parsed = DateTime.tryParse(isoTimestamp)?.toUtc();
  if (parsed == null) {
    return isoTimestamp;
  }
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute UTC';
}
