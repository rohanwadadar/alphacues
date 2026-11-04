import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/us_market_time.dart';
import '../../data/market_repository.dart';

const Map<String, int> _kRangeXTicks = {
  '1D': 6,
  '5D': 5,
  '1W': 7,
  '1M': 5,
  '3M': 6,
  'YTD': 6,
  '6M': 6,
  '1Y': 6,
  '5Y': 5,
  'MAX': 6,
};

const Map<String, double> _kRangeHours = {
  '1D': 6.5,
  '5D': 32.5,
  '1W': 56.0,
  '1M': 240.0,
  '3M': 720.0,
  'YTD': 1440.0,
  '6M': 1440.0,
  '1Y': 2920.0,
  '5Y': 14600.0,
  'MAX': 14600.0,
};

String _formatAxisLabel(DateTime dt, String range) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final et = toUsEastern(dt);
  final month = months[et.month - 1];
  final h24 = et.hour;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final ampm = h24 >= 12 ? 'PM' : 'AM';
  final mm = et.minute.toString().padLeft(2, '0');

  switch (range) {
    case '1D':
      return '$h12:$mm$ampm';
    case '5D':
    case '1W':
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[(et.weekday - 1) % 7];
    case '1M':
    case '3M':
    case '6M':
    case 'YTD':
      return '$month ${et.day}';
    case '1Y':
      return month;
    case '5Y':
    case 'MAX':
      return '${et.year}';
    default:
      return '$month ${et.day}';
  }
}

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
    if (!listEquals(widget.bars, oldWidget.bars) ||
        widget.selectedRange != oldWidget.selectedRange) {
      _scrubIndex = null;
    }
  }

  List<Candle> _toCandles(List<Bar> bars) {
    final sorted = [...bars]
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    final candles = sorted
        .map((bar) => Candle(
              date: DateTime.parse(bar.timeStamp).toUtc(),
              open: bar.openPrice,
              high: bar.highPrice,
              low: bar.lowPrice,
              close: bar.closePrice,
              volume: bar.volume.toDouble(),
            ))
        .toList(growable: true);
    if (candles.length == 1) candles.add(candles.first);
    return candles;
  }

  List<Bar> _buildDisplayBars() {
    if (widget.bars.isNotEmpty) {
      final sorted = [...widget.bars]
        ..sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
      if (sorted.length == 1) {
        final first = sorted.first;
        final ts = DateTime.tryParse(first.timeStamp) ?? DateTime.now();
        sorted.insert(
          0,
          Bar(
            timeStamp: ts.subtract(const Duration(minutes: 5)).toIso8601String(),
            openPrice: first.openPrice,
            highPrice: first.highPrice,
            lowPrice: first.lowPrice,
            closePrice: first.closePrice,
            volume: first.volume,
          ),
        );
      }
      return sorted;
    }
    final now = DateTime.now().toUtc();
    final hours = _kRangeHours[widget.selectedRange] ?? 24.0;
    final start = now.subtract(Duration(minutes: (hours * 60).round()));
    const n = 12;
    final stepMs =
        (now.difference(start).inMilliseconds / (n - 1)).round();
    return List.generate(n, (i) {
      final ts = start.add(Duration(milliseconds: stepMs * i));
      return Bar(
        timeStamp: ts.toIso8601String(),
        openPrice: 0,
        highPrice: 0,
        lowPrice: 0,
        closePrice: 0,
        volume: 0,
      );
    });
  }

  String _scrubLabel(String timeStamp) {
    final rawDt = DateTime.tryParse(timeStamp);
    if (rawDt == null) return timeStamp;
    final dt = toUsEastern(rawDt);
    final h24 = dt.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final mm = dt.minute.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final mon = months[dt.month - 1];
    final r = widget.selectedRange;
    if (r == '1D') return '$h12:$mm $ampm ET';
    if (r == '5D' || r == '1W') return '$mon ${dt.day}, $h12:$mm $ampm ET';
    if (r == '1M' || r == '3M') return '$mon ${dt.day}';
    return '$mon ${dt.day}, ${dt.year}';
  }

  void _updateScrub(double touchX, double width, List<Bar> bars) {
    if (bars.isEmpty || width <= 0) return;
    final ratio = touchX.clamp(0.0, width) / width;
    final idx =
        (ratio * (bars.length - 1)).round().clamp(0, bars.length - 1);
    setState(() => _scrubIndex = idx);
    widget.onScrub?.call(bars[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayBars = _buildDisplayBars();
    final hasReal = widget.bars.isNotEmpty;

    Color lineColor;
    if (hasReal) {
      final diff =
          displayBars.last.closePrice - displayBars.first.closePrice;
      lineColor =
          diff >= 0 ? AppColors.positive : AppColors.negative;
    } else {
      lineColor = cs.onSurfaceVariant.withValues(alpha: 0.38);
    }

    return Card(
      color: AppColors.surfaceAlt,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side:
            BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!hasReal)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'No chart data available',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.55),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.show_chart_rounded, size: 16),
                      label: Text('Line',
                          style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(
                          Icons.candlestick_chart_outlined,
                          size: 16),
                      label: Text('Candles',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_useCandleMode},
                  onSelectionChanged: (s) =>
                      setState(() => _useCandleMode = s.first),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: _useCandleMode && hasReal
                  ? Candlesticks(
                      candles: _toCandles(widget.bars),
                      style: theme.brightness == Brightness.dark
                          ? CandleSticksStyle.dark()
                          : CandleSticksStyle.light(),
                    )
                  : LayoutBuilder(builder: (ctx, box) {
                      final w = box.maxWidth;
                      final hasScrub = _scrubIndex != null &&
                          _scrubIndex! >= 0 &&
                          _scrubIndex! < displayBars.length;
                      final scrubX = hasScrub &&
                              displayBars.length > 1
                          ? (_scrubIndex! /
                                  (displayBars.length - 1)) *
                              w
                          : 0.0;
                      const bw = 130.0;
                      final bLeft =
                          (scrubX - bw / 2).clamp(6.0, w - bw - 6.0);

                      return GestureDetector(
                        onPanUpdate: hasReal
                            ? (d) => _updateScrub(
                                d.localPosition.dx, w, displayBars)
                            : null,
                        onPanDown: hasReal
                            ? (d) => _updateScrub(
                                d.localPosition.dx, w, displayBars)
                            : null,
                        onPanEnd: hasReal
                            ? (_) {
                                setState(() => _scrubIndex = null);
                                widget.onScrub?.call(null);
                              }
                            : null,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: Size(w, 220),
                              painter: _LinePainter(
                                bars: displayBars,
                                lineColor: lineColor,
                                scrubIndex: _scrubIndex,
                                theme: theme,
                                range: widget.selectedRange,
                                hasReal: hasReal,
                              ),
                            ),
                            if (hasScrub && hasReal)
                              Positioned(
                                left: bLeft,
                                top: 6,
                                child: IgnorePointer(
                                  child: Container(
                                    width: bw,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: lineColor.withValues(
                                          alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: lineColor.withValues(
                                              alpha: 0.45)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons.schedule_rounded,
                                            size: 12,
                                            color: lineColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _scrubLabel(
                                                displayBars[_scrubIndex!]
                                                    .timeStamp),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: lineColor,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.bars,
    required this.lineColor,
    required this.scrubIndex,
    required this.theme,
    required this.range,
    required this.hasReal,
  });

  final List<Bar> bars;
  final Color lineColor;
  final int? scrubIndex;
  final ThemeData theme;
  final String range;
  final bool hasReal;

  static const _axisH = 22.0;
  static const _padTop = 10.0;
  static const _padX = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.length < 2) return;

    final chartH = size.height - _axisH - _padTop;
    final chartW = size.width - _padX * 2;
    final chartTop = _padTop;
    final fillBottom = chartTop + chartH;

    final prices = bars.map((b) => b.closePrice).toList();
    final minP = hasReal ? prices.reduce(min) : 0.0;
    final maxP = hasReal ? prices.reduce(max) : 0.0;
    final range_ = (maxP - minP) == 0 ? 1.0 : (maxP - minP);

    final pts = <Offset>[];
    for (int i = 0; i < bars.length; i++) {
      final x = _padX + (i / (bars.length - 1)) * chartW;
      final ny = hasReal
          ? (bars[i].closePrice - minP) / range_
          : 0.5;
      final y =
          chartTop + chartH - (ny * chartH * 0.85) - chartH * 0.05;
      pts.add(Offset(x, y));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(
          cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }

    final fp = Path.from(path)
      ..lineTo(pts.last.dx, fillBottom)
      ..lineTo(pts.first.dx, fillBottom)
      ..close();
    canvas.drawPath(
      fp,
      Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withValues(alpha: hasReal ? 0.22 : 0.07),
            lineColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
            Rect.fromLTWH(0, chartTop, size.width, chartH)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = hasReal ? 2.5 : 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawLine(
      Offset(0, fillBottom),
      Offset(size.width, fillBottom),
      Paint()
        ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
        ..strokeWidth = 0.5,
    );

    _drawTickers(canvas, size, pts, fillBottom);

    if (hasReal &&
        scrubIndex != null &&
        scrubIndex! >= 0 &&
        scrubIndex! < pts.length) {
      final sp = pts[scrubIndex!];
      canvas.drawLine(
        Offset(sp.dx, chartTop),
        Offset(sp.dx, fillBottom),
        Paint()
          ..color =
              theme.colorScheme.onSurface.withValues(alpha: 0.3)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
          sp,
          6.5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          sp,
          3.2,
          Paint()
            ..color = theme.colorScheme.surface
            ..style = PaintingStyle.fill);
    }
  }

  void _drawTickers(
      Canvas canvas, Size size, List<Offset> pts, double axisTop) {
    final count = _kRangeXTicks[range] ?? 5;
    final style = TextStyle(
      color:
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
    );
    final tickPaint = Paint()
      ..color =
          theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;

    final ts = bars
        .map((b) => DateTime.tryParse(b.timeStamp)?.toLocal())
        .whereType<DateTime>()
        .toList();
    if (ts.isEmpty) return;

    List<int> idxs;
    if (range == '5D' || range == '1W') {
      final dayIndices = <int>[];
      int? lastDay;
      for (int i = 0; i < ts.length; i++) {
        final day = toUsEastern(ts[i]).day;
        if (day != lastDay) {
          dayIndices.add(i);
          lastDay = day;
        }
      }
      if (dayIndices.length >= 2 && dayIndices.length <= 7) {
        idxs = dayIndices;
      } else {
        idxs = _spread(bars.length, count);
      }
    } else {
      idxs = _spread(bars.length, count);
    }
    for (final i in idxs) {
      if (i >= ts.length || i >= pts.length) continue;
      final x = pts[i].dx;
      final label = _formatAxisLabel(ts[i], range);

      canvas.drawLine(
          Offset(x, axisTop), Offset(x, axisTop + 4), tickPaint);

      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 64);
      final lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(lx, axisTop + 5));
    }
  }

  List<int> _spread(int length, int count) {
    if (length <= 0) return [];
    if (count >= length) return List.generate(length, (i) => i);
    final s = <int>{0};
    for (int i = 1; i < count - 1; i++) {
      s.add(((i / (count - 1)) * (length - 1)).round());
    }
    s.add(length - 1);
    return s.toList()..sort();
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.bars != bars ||
      old.lineColor != lineColor ||
      old.scrubIndex != scrubIndex ||
      old.range != range ||
      old.hasReal != hasReal;
}