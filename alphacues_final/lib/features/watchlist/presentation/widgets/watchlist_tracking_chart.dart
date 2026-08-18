import 'package:flutter/material.dart';

class WatchlistTrackingChart extends StatefulWidget {
  const WatchlistTrackingChart({
    super.key,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
    this.isPositive = true,
  });

  final List<Map<String, dynamic>> points;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final bool isPositive;

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

  @override
  Widget build(BuildContext context) {
    final chartColor = widget.isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Smooth Bezier Curve Chart Box
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _ChartPainter(
              points: widget.points,
              lineColor: chartColor,
            ),
          ),
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
                        color: isSelected ? Colors.white : Colors.grey[700],
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
  });

  final List<Map<String, dynamic>> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => (p['value'] as num).toDouble()).toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      minY -= 10;
      maxY += 10;
    }

    final double rangeY = maxY - minY;
    final double dx = size.width / (values.length - 1);

    final Path path = Path();
    final List<Offset> offsets = [];

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - ((values[i] - minY) / rangeY) * (size.height - 20) - 10;
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
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.0),
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
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
