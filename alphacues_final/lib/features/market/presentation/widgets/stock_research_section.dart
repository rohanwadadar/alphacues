// ignore_for_file: unused_element, unused_local_variable, prefer_final_fields
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../news/data/news_repository.dart';
import '../../../news/presentation/news_detail_screen.dart';
import '../../../news/presentation/news_feed_screen.dart';
import '../../data/market_repository.dart';

enum FinancialMetric {
  revenue('Revenue'),
  grossProfit('Gross Profit'),
  netIncome('Net Income'),
  netMargin('Net Margin');

  const FinancialMetric(this.label);
  final String label;
}

class FinancialBarData {
  const FinancialBarData({
    required this.period,
    required this.value,
    required this.displayLabel,
    this.isNegative = false,
  });

  final String period;
  final double value;
  final String displayLabel;
  final bool isNegative;
}

class EarningsQuarterData {
  const EarningsQuarterData({
    required this.quarter,
    required this.estimated,
    required this.actual,
  });

  final String quarter;
  final double estimated;
  final double actual;

  bool get isBeat => actual >= estimated;
  double get surprisePercent => estimated != 0
      ? ((actual - estimated) / estimated.abs()) * 100
      : 0.0;
}

class StockResearchSection extends ConsumerStatefulWidget {
  const StockResearchSection({
    super.key,
    required this.symbol,
    required this.fundamentals,
  });

  final String symbol;
  final MarketFundamentals fundamentals;

  @override
  ConsumerState<StockResearchSection> createState() => _StockResearchSectionState();
}

class _StockResearchSectionState extends ConsumerState<StockResearchSection> {
  bool _isQuarterly = true;
  FinancialMetric _selectedMetric = FinancialMetric.revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final f = widget.fundamentals.fields;

    final barData = _computeFinancialData(f, _selectedMetric, _isQuarterly);
    final earningsData = _computeEarningsData(f);

    // Financial Statements & Earnings Performance commented out per user request
    // to only keep the real-time RobinhoodFinancialsSection and RobinhoodEarningsSection
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*
        // ── Section 1: Fundamental Financials ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Statements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isQuarterly ? 'Last 5 quarters' : 'Last 5 annual fiscal years',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Quarterly / Annual Switcher
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _PeriodToggleBtn(
                    label: 'Quarterly',
                    isSelected: _isQuarterly,
                    onTap: () => setState(() => _isQuarterly = true),
                  ),
                  _PeriodToggleBtn(
                    label: 'Annual',
                    isSelected: !_isQuarterly,
                    onTap: () => setState(() => _isQuarterly = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Metric Selectors (Revenue, Gross Profit, Net Income, Net Margin)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: FinancialMetric.values.map((metric) {
              final isSelected = metric == _selectedMetric;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    metric.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedMetric = metric);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Financial Bar Chart Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedMetric.label} Trend',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Latest: ${barData.isNotEmpty ? barData.last.displayLabel : "-"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedMetric == FinancialMetric.netMargin
                          ? (barData.isNotEmpty && barData.last.isNegative
                              ? AppColors.negative
                              : AppColors.positive)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: _FinancialBarChart(
                  data: barData,
                  metric: _selectedMetric,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Section 2: Earnings Report Dotted Chart ────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Estimated vs. Actual EPS across recent reporting quarters',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quarterly EPS Comparison',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (earningsData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (earningsData.last.isBeat
                                ? AppColors.positive
                                : AppColors.negative)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${earningsData.last.surprisePercent >= 0 ? "+" : ""}${earningsData.last.surprisePercent.toStringAsFixed(1)}% ${earningsData.last.isBeat ? "Beat" : "Miss"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: earningsData.last.isBeat
                              ? AppColors.positive
                              : AppColors.negative,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                child: _EarningsDottedChart(quarters: earningsData),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                    isDotted: true,
                    color: Colors.grey.shade400,
                    label: 'Est. EPS',
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    isDotted: false,
                    color: AppColors.positive,
                    label: 'Actual EPS (Beat)',
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    isDotted: false,
                    color: AppColors.negative,
                    label: 'Actual EPS (Miss)',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        */

        // ── Stock News Section ──────────────────────────────────
        _StockNewsList(symbol: widget.symbol),
      ],
    );
  }

  List<FinancialBarData> _computeFinancialData(
    Map f,
    FinancialMetric metric,
    bool isQuarterly,
  ) {
    final cap = (f['marketCap'] as num?)?.toDouble() ?? 5e10;
    final pe = (f['peRatio'] as num?)?.toDouble() ?? 24.0;
    final baseAnnualRev = math.max(cap / (pe * 0.35), 2e9);

    final periods = isQuarterly
        ? ['Q1\'23', 'Q2\'23', 'Q3\'23', 'Q4\'23', 'Q1\'24']
        : ['2020', '2021', '2022', '2023', '2024'];

    final growthMultipliers = isQuarterly
        ? [0.91, 0.94, 0.97, 1.03, 1.08]
        : [0.72, 0.81, 0.89, 0.96, 1.05];

    final divFactor = isQuarterly ? 4.0 : 1.0;
    final rev = baseAnnualRev / divFactor;

    return List.generate(periods.length, (i) {
      final period = periods[i];
      final m = growthMultipliers[i];
      final pRevenue = rev * m;

      switch (metric) {
        case FinancialMetric.revenue:
          return FinancialBarData(
            period: period,
            value: pRevenue,
            displayLabel: _formatCurrency(pRevenue),
          );
        case FinancialMetric.grossProfit:
          final gp = pRevenue * 0.44;
          return FinancialBarData(
            period: period,
            value: gp,
            displayLabel: _formatCurrency(gp),
          );
        case FinancialMetric.netIncome:
          final ni = pRevenue * (pe > 40 ? 0.14 : (pe < 15 ? 0.26 : 0.20));
          return FinancialBarData(
            period: period,
            value: ni,
            displayLabel: _formatCurrency(ni),
          );
        case FinancialMetric.netMargin:
          final marginPct = (pe > 40 ? 14.5 : (pe < 15 ? 26.0 : 20.5)) + (i * 0.4);
          return FinancialBarData(
            period: period,
            value: marginPct,
            displayLabel: '${marginPct.toStringAsFixed(1)}%',
          );
      }
    });
  }

  List<EarningsQuarterData> _computeEarningsData(Map f) {
    final eps = (f['eps'] as num?)?.toDouble() ?? 3.40;
    final qBase = eps > 0 ? (eps / 4.0) : 0.85;

    return [
      EarningsQuarterData(
        quarter: 'Q2\'23',
        estimated: qBase * 0.92,
        actual: qBase * 0.96,
      ),
      EarningsQuarterData(
        quarter: 'Q3\'23',
        estimated: qBase * 0.95,
        actual: qBase * 1.02,
      ),
      EarningsQuarterData(
        quarter: 'Q4\'23',
        estimated: qBase * 1.00,
        actual: qBase * 0.98, // miss
      ),
      EarningsQuarterData(
        quarter: 'Q1\'24',
        estimated: qBase * 1.05,
        actual: qBase * 1.12, // beat
      ),
    ];
  }

  String _formatCurrency(double val) {
    if (val >= 1e12) return '\$${(val / 1e12).toStringAsFixed(1)}T';
    if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(1)}B';
    if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(1)}M';
    return '\$${val.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period Toggle Button
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodToggleBtn extends StatelessWidget {
  const _PeriodToggleBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Bar Chart Custom Painter
// ─────────────────────────────────────────────────────────────────────────────
class _FinancialBarChart extends StatelessWidget {
  const _FinancialBarChart({
    required this.data,
    required this.metric,
  });

  final List<FinancialBarData> data;
  final FinancialMetric metric;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxVal = data.map((e) => e.value).reduce(math.max);
        final effectiveMax = maxVal == 0 ? 1.0 : maxVal * 1.25;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((bar) {
            final barHeightPercent = (bar.value / effectiveMax).clamp(0.08, 1.0);
            final barHeight = (constraints.maxHeight - 44) * barHeightPercent;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label on top
                Text(
                  bar.displayLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                // Bar itself
                Container(
                  width: 38,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: metric == FinancialMetric.netMargin
                          ? [
                              bar.isNegative ? AppColors.negative : AppColors.positive,
                              (bar.isNegative ? AppColors.negative : AppColors.positive)
                                  .withValues(alpha: 0.6),
                            ]
                          : [
                              const Color(0xFF7C4DFF),
                              const Color(0xFF651FFF).withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 8),
                // Period label on bottom
                Text(
                  bar.period,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings Dotted Chart
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsDottedChart extends StatelessWidget {
  const _EarningsDottedChart({required this.quarters});

  final List<EarningsQuarterData> quarters;

  @override
  Widget build(BuildContext context) {
    if (quarters.isEmpty) return const SizedBox();

    return CustomPaint(
      size: Size.infinite,
      painter: _EarningsChartPainter(quarters: quarters),
    );
  }
}

class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter({required this.quarters});

  final List<EarningsQuarterData> quarters;

  @override
  void paint(Canvas canvas, Size size) {
    if (quarters.isEmpty) return;

    final n = quarters.length;
    final allValues = <double>[];
    for (final q in quarters) {
      allValues.add(q.estimated);
      allValues.add(q.actual);
    }

    final maxVal = allValues.reduce(math.max);
    final minVal = allValues.reduce(math.min);
    final valueRange = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    const topPad = 24.0;
    const bottomPad = 28.0;
    final usableHeight = size.height - topPad - bottomPad;

    double getY(double val) {
      final norm = (val - minVal) / valueRange;
      return size.height - bottomPad - (norm * usableHeight);
    }

    final estPoints = <Offset>[];
    final actPoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = (size.width / (n + 1)) * (i + 1);
      estPoints.add(Offset(x, getY(quarters[i].estimated)));
      actPoints.add(Offset(x, getY(quarters[i].actual)));
    }

    // 1. Draw horizontal dotted gridlines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final gy = topPad + (usableHeight / 4) * i;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // 2. Draw Dotted line connecting estimated points
    final estLinePaint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < n - 1; i++) {
      _drawDottedLine(canvas, estPoints[i], estPoints[i + 1], estLinePaint);
    }

    // 3. Draw Solid line connecting actual points
    final actLinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final actPath = Path()..moveTo(actPoints[0].dx, actPoints[0].dy);
    for (int i = 1; i < n; i++) {
      actPath.lineTo(actPoints[i].dx, actPoints[i].dy);
    }
    canvas.drawPath(actPath, actLinePaint);

    // 4. Draw markers and values
    for (int i = 0; i < n; i++) {
      final ep = estPoints[i];
      final ap = actPoints[i];
      final q = quarters[i];

      // Quarter text at bottom
      final textSpan = TextSpan(
        text: q.quarter,
        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(ap.dx - (textPainter.width / 2), size.height - bottomPad + 8),
      );

      // Estimated point: hollow circle
      final estRingPaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final estInnerPaint = Paint()
        ..color = const Color(0xFF1E1E2C)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ep, 5.0, estInnerPaint);
      canvas.drawCircle(ep, 5.0, estRingPaint);

      // Actual point: filled circle (green if beat, red if miss)
      final actColor = q.isBeat ? AppColors.positive : AppColors.negative;
      final actCirclePaint = Paint()
        ..color = actColor
        ..style = PaintingStyle.fill;
      final actBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(ap, 6.0, actCirclePaint);
      canvas.drawCircle(ap, 6.0, actBorderPaint);

      // Actual value text
      final valSpan = TextSpan(
        text: '\$${q.actual.toStringAsFixed(2)}',
        style: TextStyle(
          color: actColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final valPainter = TextPainter(
        text: valSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final valY = (ap.dy < ep.dy) ? ap.dy - 16 : ap.dy + 8;
      valPainter.paint(canvas, Offset(ap.dx - (valPainter.width / 2), valY));
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLength = 4.0;
    const dashSpace = 4.0;
    final totalDist = (p2 - p1).distance;
    final norm = (p2 - p1) / totalDist;
    double curDist = 0.0;

    while (curDist < totalDist) {
      final start = p1 + norm * curDist;
      final endDist = math.min(curDist + dashLength, totalDist);
      final end = p1 + norm * endDist;
      canvas.drawLine(start, end, paint);
      curDist += dashLength + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.isDotted,
    required this.color,
    required this.label,
  });

  final bool isDotted;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isDotted ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isDotted ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock News List
// ─────────────────────────────────────────────────────────────────────────────
class _StockNewsList extends ConsumerWidget {
  const _StockNewsList({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final newsAsync = ref.watch(marketNewsProvider(symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest News',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Recent headlines & coverage for $symbol',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewsFeedScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        newsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No news available for $symbol at this moment.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          data: (articles) {
            final stockArticles = articles.take(4).toList();
            if (stockArticles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No recent headlines for $symbol.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              );
            }

            return Column(
              children: stockArticles.map((article) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsDetailScreen(article: article),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              article.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.newspaper_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      article.source,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${_formatRelativeTime(article.publishedAt)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  article.headline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatRelativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recent';
    }
  }
}
