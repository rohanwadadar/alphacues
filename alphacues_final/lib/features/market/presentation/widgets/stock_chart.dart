import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/market_repository.dart';

class StockChart extends StatefulWidget {
  const StockChart({
    super.key,
    required this.bars,
    required this.selectedRange,
    required this.isStale,
    this.onScrub,
  });

  final List<Bar> bars;
  final String selectedRange;
  final bool isStale;
  final ValueChanged<Bar?>? onScrub;

  @override
  State<StockChart> createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  bool _useCandleMode = false;
  int? _scrubIndex;

  @override
  void didUpdateWidget(covariant StockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.bars, oldWidget.bars)) {
      _scrubIndex = null;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    final sortedBars = [...widget.bars]
      ..sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

    final firstPrice = sortedBars.first.closePrice;
    final lastPrice = sortedBars.last.closePrice;
    final isPositive = (lastPrice - firstPrice) >= 0;
    final chartColor = isPositive ? AppColors.positive : AppColors.negative;

    return Card(
      color: AppColors.surfaceAlt,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP CONTROL BAR (ONLY TOGGLE, NO DUPLICATE PRICE TEXT) ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.show_chart_rounded, size: 16),
                      label: Text('Line', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.candlestick_chart_outlined, size: 16),
                      label: Text('Candles', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_useCandleMode},
                  onSelectionChanged: (set) {
                    setState(() => _useCandleMode = set.first);
                  },
                ),
              ],
            ),

            // ── CHART CANVAS ──────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: _useCandleMode
                  ? Candlesticks(
                      candles: _toCandles(widget.bars),
                      style: theme.brightness == Brightness.dark
                          ? CandleSticksStyle.dark()
                          : CandleSticksStyle.light(),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanUpdate: (details) {
                            _updateScrub(details.localPosition.dx, constraints.maxWidth, sortedBars);
                          },
                          onPanDown: (details) {
                            _updateScrub(details.localPosition.dx, constraints.maxWidth, sortedBars);
                          },
                          onPanEnd: (_) {
                            setState(() => _scrubIndex = null);
                            widget.onScrub?.call(null);
                          },
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, 220),
                            painter: _MinimalistLinePainter(
                              bars: sortedBars,
                              lineColor: chartColor,
                              scrubIndex: _scrubIndex,
                              theme: theme,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateScrub(double touchX, double width, List<Bar> sortedBars) {
    if (sortedBars.isEmpty || width <= 0) return;
    final clampedX = touchX.clamp(0.0, width);
    final ratio = clampedX / width;
    final index = (ratio * (sortedBars.length - 1)).round().clamp(0, sortedBars.length - 1);

    setState(() => _scrubIndex = index);
    widget.onScrub?.call(sortedBars[index]);
  }
}

class _MinimalistLinePainter extends CustomPainter {
  _MinimalistLinePainter({
    required this.bars,
    required this.lineColor,
    required this.scrubIndex,
    required this.theme,
  });

  final List<Bar> bars;
  final Color lineColor;
  final int? scrubIndex;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.length < 2) return;

    final prices = bars.map((b) => b.closePrice).toList();
    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final priceRange = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);

    final points = <Offset>[];
    for (int i = 0; i < bars.length; i++) {
      final x = (i / (bars.length - 1)) * size.width;
      final normalizedY = (bars[i].closePrice - minPrice) / priceRange;
      final y = size.height - (normalizedY * (size.height - 20)) - 10;
      points.add(Offset(x, y));
    }

    // Draw Smooth Bezier Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final controlX = (pPrev.dx + pCurr.dx) / 2;
      path.cubicTo(controlX, pPrev.dy, controlX, pCurr.dy, pCurr.dx, pCurr.dy);
    }

    // Smooth Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.22),
          lineColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw Touch Scrubbing Crosshair Line & Indicator Circle
    if (scrubIndex != null && scrubIndex! >= 0 && scrubIndex! < points.length) {
      final scrubPt = points[scrubIndex!];

      // Vertical Guideline
      final guidePaint = Paint()
        ..color = theme.colorScheme.onSurface.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(scrubPt.dx, 0),
        Offset(scrubPt.dx, size.height),
        guidePaint,
      );

      // Outer Ring
      final ringPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scrubPt, 6.5, ringPaint);

      // Inner Core
      final innerPaint = Paint()
        ..color = theme.colorScheme.surface
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scrubPt, 3.2, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalistLinePainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.scrubIndex != scrubIndex;
  }
}
