import 'package:flutter/material.dart';

import '../../../../core/utils/us_market_time.dart';

class WatchlistTrackingChart extends StatefulWidget {
  const WatchlistTrackingChart({
    super.key,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
    this.isPositive = true,
    this.onScrub,
  });

  final List<Map<String, dynamic>> points;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final bool isPositive;
  final ValueChanged<Map<String, dynamic>?>? onScrub;

  @override
  State<WatchlistTrackingChart> createState() => _WatchlistTrackingChartState();
}

class _WatchlistTrackingChartState extends State<WatchlistTrackingChart> {
  static const List<String> timeframes = [
    '1D',
    '5D',
    '1M',
    '3M',
    'YTD',
    '1Y',
    'MAX',
  ];

  int? _touchedIndex;

  void _handleTouch(Offset localPosition, double chartWidth) {
    if (widget.points.isEmpty || chartWidth <= 0) return;
    final step = widget.points.length > 1
        ? chartWidth / (widget.points.length - 1)
        : chartWidth;
    int index = (localPosition.dx / step).round();
    if (index < 0) index = 0;
    if (index >= widget.points.length) index = widget.points.length - 1;
    setState(() {
      _touchedIndex = index;
    });
    if (widget.onScrub != null) {
      final pointTime = widget.points[index]['time'];
      final timeStr = (pointTime is String && pointTime.isNotEmpty)
          ? pointTime
          : _formatTimestampForRange(index, widget.points.length);
      widget.onScrub!({
        'value': widget.points[index]['value'],
        'time': timeStr,
      });
    }
  }

  void _clearTouch() {
    setState(() {
      _touchedIndex = null;
    });
    if (widget.onScrub != null) {
      widget.onScrub!(null);
    }
  }

  String _formatTimestampForRange(int index, int total) {
    final now = toUsEastern(DateTime.now().toUtc());
    final fraction = total > 1 ? index / (total - 1) : 1.0;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    switch (widget.selectedRange) {
      case '1D':
        final hour = (9 + (fraction * 6.5)).floor();
        final min = ((fraction * 6.5 * 60) % 60).floor();
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : hour;
        return '$displayHour:${min.toString().padLeft(2, '0')} $period ET';
      case '5D':
        final daysAgo = (5 * (1 - fraction)).floor();
        final dt = now.subtract(Duration(days: daysAgo));
        final monthStr = months[dt.month - 1];
        return '$monthStr ${dt.day}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ET';
      case '1M':
        final daysAgo = (30 * (1 - fraction)).floor();
        final dt = now.subtract(Duration(days: daysAgo));
        final monthStr = months[dt.month - 1];
        return '$monthStr ${dt.day}';
      case '3M':
        final daysAgo = (90 * (1 - fraction)).floor();
        final dt = now.subtract(Duration(days: daysAgo));
        final monthStr = months[dt.month - 1];
        return '$monthStr ${dt.day}, ${dt.year}';
      default:
        final daysAgo = (365 * (1 - fraction)).floor();
        final dt = now.subtract(Duration(days: daysAgo));
        final monthStr = months[dt.month - 1];
        return '$monthStr ${dt.day}, ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = widget.isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    String? touchedTime;
    if (_touchedIndex != null && _touchedIndex! < widget.points.length) {
      final pointTime = widget.points[_touchedIndex!]['time'];
      if (pointTime is String && pointTime.isNotEmpty) {
        touchedTime = pointTime;
      } else {
        touchedTime = _formatTimestampForRange(_touchedIndex!, widget.points.length);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Time badge floating above pointer line when scrubbing
        if (touchedTime != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: chartColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: chartColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: chartColor),
                  const SizedBox(width: 4),
                  Text(
                    touchedTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: chartColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 28), // Consistent space reservation


        // Smooth Bezier Curve Chart Box with Touch Listener
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth;

            return GestureDetector(
              onPanStart: (details) => _handleTouch(details.localPosition, chartWidth),
              onPanUpdate: (details) => _handleTouch(details.localPosition, chartWidth),
              onPanEnd: (_) => _clearTouch(),
              onTapDown: (details) => _handleTouch(details.localPosition, chartWidth),
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _ChartPainter(
                    points: widget.points,
                    lineColor: chartColor,
                    touchedIndex: _touchedIndex,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Timeframe Selector Chips matching reference UI
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: timeframes.map((tf) {
              final isSelected = tf == widget.selectedRange;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => widget.onRangeChanged(tf),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? chartColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.lineColor,
    this.touchedIndex,
  });

  final List<Map<String, dynamic>> points;
  final Color lineColor;
  final int? touchedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => (p['value'] as num).toDouble()).toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    final bool allZero = minY == 0.0 && maxY == 0.0;
    if (allZero) {
      minY = 0.0;
      maxY = 1.0;
    } else if (minY == maxY) {
      minY -= 10;
      maxY += 10;
    } else if (minY >= 0.0 && values.any((v) => v == 0.0)) {
      minY = 0.0;
    }

    final double rangeY = maxY - minY;
    final double dx = values.length > 1 ? size.width / (values.length - 1) : size.width;

    final Path path = Path();
    final List<Offset> offsets = [];

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final double y;
      if (allZero) {
        y = size.height - 16.0;
      } else {
        y = size.height - ((values[i] - minY) / rangeY) * (size.height - 32) - 16;
      }
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets[0].dx, offsets[0].dy);
    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Draw Gradient Area Fill under the path
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw Touch Indicator Vertical Line & Point Dot
    if (touchedIndex != null && touchedIndex! < offsets.length) {
      final touchedOffset = offsets[touchedIndex!];

      // Vertical dashed line
      final Paint dashPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      double dashY = 0;
      while (dashY < size.height) {
        canvas.drawLine(
          Offset(touchedOffset.dx, dashY),
          Offset(touchedOffset.dx, dashY + 4),
          dashPaint,
        );
        dashY += 8;
      }

      // Outer glow circle
      final Paint glowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchedOffset, 8, glowPaint);

      // Inner solid point dot
      final Paint pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchedOffset, 5, pointPaint);

      final Paint innerWhitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchedOffset, 2.5, innerWhitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.touchedIndex != touchedIndex;
  }
}
