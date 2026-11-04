import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/market_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ROBINHOOD-STYLE FINANCIALS SECTION
/// (Quarterly / Annual Clustered Bars for Revenue, Gross Profit, Net Income + Overlaid Net Margin Line)
/// ─────────────────────────────────────────────────────────────────────────────
class RobinhoodFinancialsSection extends StatefulWidget {
  const RobinhoodFinancialsSection({
    super.key,
    required this.symbol,
    required this.fundamentals,
    required this.currentPrice,
  });

  final String symbol;
  final MarketFundamentals fundamentals;
  final double currentPrice;

  @override
  State<RobinhoodFinancialsSection> createState() =>
      _RobinhoodFinancialsSectionState();
}

class _RobinhoodFinancialsSectionState
    extends State<RobinhoodFinancialsSection> {
  bool _isQuarterly = true;
  int? _selectedPeriodIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final periods = _isQuarterly
      ? _generateQuarterlyData(widget.fundamentals)
      : _generateAnnualData(widget.fundamentals);

    if (periods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financials',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Audited financial statement data is currently unavailable for ${widget.symbol}.',
              style: TextStyle(
                color: isDark ? Colors.white60 : colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = _selectedPeriodIndex != null &&
            _selectedPeriodIndex! < periods.length
        ? _selectedPeriodIndex!
        : periods.length - 1;
    final activeData = periods[activeIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: "Financials" + Info (i) Icon ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Financials',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Financial Statement Info',
                    onPressed: () => _showFinancialsInfoModal(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Segmented Toggle: Quarterly | Annual ───────────────────────────
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isQuarterly = true;
                      _selectedPeriodIndex = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isQuarterly
                            ? (isDark ? const Color(0xFF323238) : colorScheme.surface)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: _isQuarterly
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Quarterly',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _isQuarterly ? FontWeight.bold : FontWeight.w500,
                          color: _isQuarterly
                              ? (isDark ? Colors.white : colorScheme.onSurface)
                              : (isDark ? Colors.white54 : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isQuarterly = false;
                      _selectedPeriodIndex = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isQuarterly
                            ? (isDark ? const Color(0xFF323238) : colorScheme.surface)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: !_isQuarterly
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Annual',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: !_isQuarterly ? FontWeight.bold : FontWeight.w500,
                          color: !_isQuarterly
                              ? (isDark ? Colors.white : colorScheme.onSurface)
                              : (isDark ? Colors.white54 : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Legend Row with colored indicators ─────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem(
                  color: const Color(0xFF00C805),
                  label: 'Revenue',
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                _buildLegendItem(
                  color: const Color(0xFF00E676),
                  label: 'Gross profit',
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                _buildLegendItem(
                  color: const Color(0xFFC6FF00),
                  label: 'Net income',
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                _buildLineLegendItem(
                  color: Colors.white,
                  label: 'Net margin',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Active Period Stats Banner (Interactive Scrubber Result) ────────
          Builder(
            builder: (context) {
              final isProfitable = activeData.netIncome >= 0;
              final accentColor = isProfitable ? const Color(0xFF00C805) : const Color(0xFFFF3B30);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${activeData.periodLabel}:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rev ${_formatDollar(activeData.revenue)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF00C805),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isProfitable
                              ? '• Net +${_formatDollar(activeData.netIncome)} (Profit)'
                              : '• Net -${_formatDollar(activeData.netIncome.abs())} (Loss)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Margin ${activeData.netMargin.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Custom Bar & Line Chart Canvas ─────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 220,
                width: constraints.maxWidth,
                child: GestureDetector(
                  onPanDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, periods.length),
                  onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, periods.length),
                  child: CustomPaint(
                    painter: _RobinhoodFinancialsPainter(
                      periods: periods,
                      selectedIndex: activeIndex,
                      isDark: isDark,
                      isQuarterly: _isQuarterly,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, double width, int count) {
    if (count <= 0 || width <= 0) return;
    final step = width / count;
    int index = (localPosition.dx / step).floor().clamp(0, count - 1);
    if (index != _selectedPeriodIndex) {
      setState(() {
        _selectedPeriodIndex = index;
      });
    }
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLineLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: isDark ? Colors.white : Colors.black87, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showFinancialsInfoModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'About Financials',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Revenue', 'Total amount of income generated by the sale of goods or services related to the company\'s primary operations.', const Color(0xFF00C805)),
              const SizedBox(height: 12),
              _buildInfoRow('Gross profit', 'The profit a company makes after deducting the costs associated with making and selling its products.', const Color(0xFF00E676)),
              const SizedBox(height: 12),
              _buildInfoRow('Net income', 'The total earnings or profit after deducting all expenses, taxes, and interest costs.', const Color(0xFFC6FF00)),
              const SizedBox(height: 12),
              _buildInfoRow('Net margin', 'The percentage of revenue remaining after all operating expenses, interest, and taxes have been deducted.', Colors.white70),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String title, String desc, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDollar(double val) {
    if (val >= 1e12) return '\$${(val / 1e12).toStringAsFixed(1)}T';
    if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(1)}B';
    if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(1)}M';
    return '\$${val.toStringAsFixed(0)}';
  }

  // ── High Accuracy Multi-Year Financial Series Generator ──────────────────
  static double? _readNumber(Map item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<_FinancialPeriod> _generateAnnualData(
    MarketFundamentals fundamentals,
  ) {
    final fs = fundamentals.fields['financialStatements'];
    if (fs is Map && fs['annual'] is List && (fs['annual'] as List).isNotEmpty) {
      final list = fs['annual'] as List;
      final periods = <_FinancialPeriod>[];
      for (final item in list) {
        if (item is Map) {
          final top = item['topLabel']?.toString() ?? 'FY';
          final bottom = item['bottomLabel']?.toString() ?? '25';
          final pLabel = item['periodLabel']?.toString() ?? '$top $bottom';
            final rev = _readNumber(item, 'revenue');
            final gp = _readNumber(item, 'grossProfit');
            final ni = _readNumber(item, 'netIncome');
            if (rev == null || gp == null || ni == null) continue;
            final margin = _readNumber(item, 'netMargin') ??
              (rev > 0 ? (ni / rev * 100) : 0.0);

          periods.add(
            _FinancialPeriod(
              topLabel: top,
              bottomLabel: bottom,
              periodLabel: pLabel,
              revenue: rev,
              grossProfit: gp,
              netIncome: ni,
              netMargin: margin,
            ),
          );
        }
      }
      if (periods.isNotEmpty) return periods;
    }

    return const <_FinancialPeriod>[];
  }

  static List<_FinancialPeriod> _generateQuarterlyData(
    MarketFundamentals fundamentals,
  ) {
    final fs = fundamentals.fields['financialStatements'];
    if (fs is Map && fs['quarterly'] is List && (fs['quarterly'] as List).isNotEmpty) {
      final list = fs['quarterly'] as List;
      final periods = <_FinancialPeriod>[];
      for (final item in list) {
        if (item is Map) {
          final top = item['topLabel']?.toString() ?? 'Q1';
          final bottom = item['bottomLabel']?.toString() ?? 'FY25';
          final pLabel = item['periodLabel']?.toString() ?? '$top $bottom';
            final rev = _readNumber(item, 'revenue');
            final gp = _readNumber(item, 'grossProfit');
            final ni = _readNumber(item, 'netIncome');
            if (rev == null || gp == null || ni == null) continue;
            final margin = _readNumber(item, 'netMargin') ??
              (rev > 0 ? (ni / rev * 100) : 0.0);

          periods.add(
            _FinancialPeriod(
              topLabel: top,
              bottomLabel: bottom,
              periodLabel: pLabel,
              revenue: rev,
              grossProfit: gp,
              netIncome: ni,
              netMargin: margin,
            ),
          );
        }
      }
      if (periods.isNotEmpty) return periods;
    }

    return const <_FinancialPeriod>[];
  }
}

class _FinancialPeriod {
  const _FinancialPeriod({
    required this.topLabel,
    required this.bottomLabel,
    required this.periodLabel,
    required this.revenue,
    required this.grossProfit,
    required this.netIncome,
    required this.netMargin,
  });

  final String topLabel;
  final String bottomLabel;
  final String periodLabel;
  final double revenue;
  final double grossProfit;
  final double netIncome;
  final double netMargin;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FINANCIALS CUSTOM PAINTER (Clustered Grouped Bars + White Net Margin Line)
/// ─────────────────────────────────────────────────────────────────────────────
class _RobinhoodFinancialsPainter extends CustomPainter {
  _RobinhoodFinancialsPainter({
    required this.periods,
    required this.selectedIndex,
    required this.isDark,
    required this.isQuarterly,
  });

  final List<_FinancialPeriod> periods;
  final int selectedIndex;
  final bool isDark;
  final bool isQuarterly;

  @override
  void paint(Canvas canvas, Size size) {
    if (periods.isEmpty) return;

    const leftPadding = 42.0;
    const bottomPadding = 38.0;
    const topPadding = 24.0;

    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Find max revenue for scaling Y-axis
    final maxRevenue = periods.map((p) => p.revenue).reduce(math.max);
    final yMax = _roundUpYAxis(maxRevenue * 1.15);

    // ── 1. Draw Horizontal Grid Lines & Left Y-Axis Labels ───────────────────
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    const gridDivisions = 3;
    for (int i = 0; i <= gridDivisions; i++) {
      final fraction = i / gridDivisions;
      final y = topPadding + chartHeight * (1 - fraction);
      final value = yMax * fraction;

      // Dashed grid line
      _drawDashedLine(canvas, Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      // Y-axis label on left
      final labelText = _formatYAxisLabel(value);
      textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // ── 2. Draw Clustered Grouped Bars per Period ───────────────────────────
    final periodStep = chartWidth / periods.length;
    final clusterWidth = periodStep * 0.65;
    final barWidth = clusterWidth / 3.0;

    final revPaint = Paint()..color = const Color(0xFF00C805);
    final gpPaint = Paint()..color = const Color(0xFF00E676);

    final List<Offset> marginLinePoints = [];

    for (int i = 0; i < periods.length; i++) {
      final p = periods[i];
      final isSelected = i == selectedIndex;
      final groupCenterX = leftPadding + (i * periodStep) + (periodStep / 2);
      final groupLeftX = groupCenterX - (clusterWidth / 2);

      final isProfit = p.netIncome >= 0;
      final niColor = isProfit ? const Color(0xFF00C805) : const Color(0xFFFF3B30);
      final dynamicNiPaint = Paint()..color = niColor;

      // Draw Selected Column Highlight Background
      if (isSelected) {
        final highlightRect = Rect.fromLTWH(
          leftPadding + (i * periodStep) + 2,
          topPadding - 8,
          periodStep - 4,
          chartHeight + 12,
        );
        final highlightPaint = Paint()
          ..color = (isProfit ? const Color(0xFF00C805) : const Color(0xFFFF3B30)).withValues(alpha: 0.06)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)), highlightPaint);
      }

      final revHeight = (p.revenue / yMax) * chartHeight;
      final gpHeight = (p.grossProfit / yMax) * chartHeight;
      final niHeight = (p.netIncome.abs() / yMax) * chartHeight;

      final baseY = topPadding + chartHeight;

      // Bar 1: Revenue
      final r1 = RRect.fromRectAndCorners(
        Rect.fromLTWH(groupLeftX, baseY - revHeight, barWidth - 1, revHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(r1, revPaint);

      // Bar 2: Gross Profit
      final r2 = RRect.fromRectAndCorners(
        Rect.fromLTWH(groupLeftX + barWidth, baseY - gpHeight, barWidth - 1, gpHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(r2, gpPaint);

      // Bar 3: Net Income (Dynamic GREEN when profiting, RED when having loss)
      final r3 = RRect.fromRectAndCorners(
        Rect.fromLTWH(groupLeftX + (barWidth * 2), baseY - niHeight, barWidth - 1, niHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(r3, dynamicNiPaint);

      // Net Margin Line Anchor Point (normalized around top third)
      final marginFraction = (p.netMargin / 40.0).clamp(0.1, 0.95);
      final marginY = topPadding + (chartHeight * 0.45) - (marginFraction * (chartHeight * 0.35));
      marginLinePoints.add(Offset(groupCenterX, marginY));

      // ── Draw 2-Line X-Axis Period Label ────────────────────────────────────
      final labelColor = isSelected
          ? (isDark ? Colors.white : Colors.black)
          : (isDark ? Colors.white54 : Colors.black54);
      final labelWeight = isSelected ? FontWeight.bold : FontWeight.w500;

      // Top label (e.g. FY or Q1)
      textPainter.text = TextSpan(
        text: p.topLabel,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: labelWeight,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - (textPainter.width / 2), baseY + 6),
      );

      // Bottom label (e.g. 25 or FY26)
      textPainter.text = TextSpan(
        text: p.bottomLabel,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: labelWeight,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - (textPainter.width / 2), baseY + 20),
      );
    }

    // ── 3. Draw Overlaid White Net Margin Line & Circular Dots ───────────────
    if (marginLinePoints.length > 1) {
      final linePaint = Paint()
        ..color = isDark ? Colors.white : Colors.black87
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final Path linePath = Path()..moveTo(marginLinePoints[0].dx, marginLinePoints[0].dy);
      for (int i = 1; i < marginLinePoints.length; i++) {
        linePath.lineTo(marginLinePoints[i].dx, marginLinePoints[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Draw Net Margin Circular Dots (Dynamic GREEN for profit, RED for loss)
      for (int i = 0; i < marginLinePoints.length; i++) {
        final pt = marginLinePoints[i];
        final isSelected = i == selectedIndex;
        final isProfit = periods[i].netIncome >= 0;
        final dotColor = isProfit ? const Color(0xFF00C805) : const Color(0xFFFF3B30);
        final radius = isSelected ? 5.5 : 4.0;

        if (isSelected) {
          canvas.drawCircle(pt, radius + 3.0, Paint()..color = dotColor.withValues(alpha: 0.35));
        }
        canvas.drawCircle(pt, radius, Paint()..color = dotColor);
        canvas.drawCircle(
          pt,
          radius - 1.5,
          Paint()..color = isDark ? const Color(0xFF141416) : Colors.white,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = p1.dx;
    while (currentX < p2.dx) {
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(math.min(currentX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  double _roundUpYAxis(double val) {
    if (val <= 0) return 100;
    final magnitude = math.pow(10, (math.log(val) / math.ln10).floor()).toDouble();
    return (val / magnitude).ceil() * magnitude;
  }

  String _formatYAxisLabel(double val) {
    if (val >= 1e12) return '${(val / 1e12).toStringAsFixed(0)}T';
    if (val >= 1e9) return '${(val / 1e9).toStringAsFixed(0)}B';
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(0)}M';
    if (val <= 0) return '0';
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _RobinhoodFinancialsPainter oldDelegate) {
    return oldDelegate.periods != periods ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isQuarterly != isQuarterly;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ROBINHOOD-STYLE EARNINGS SECTION
/// (Estimated EPS vs Actual EPS Dot Plot with Expected Date & Beat Analysis)
/// ─────────────────────────────────────────────────────────────────────────────
class RobinhoodEarningsSection extends StatefulWidget {
  const RobinhoodEarningsSection({
    super.key,
    required this.symbol,
    required this.fundamentals,
    required this.currentPrice,
  });

  final String symbol;
  final MarketFundamentals fundamentals;
  final double currentPrice;

  @override
  State<RobinhoodEarningsSection> createState() =>
      _RobinhoodEarningsSectionState();
}

class _RobinhoodEarningsSectionState extends State<RobinhoodEarningsSection> {
  int? _selectedQuarterIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final quarters = _generateEarningsData(
      widget.symbol,
      widget.fundamentals,
      widget.currentPrice,
    );

    if (quarters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quarterly earnings data is currently unavailable for ${widget.symbol}.',
              style: TextStyle(
                color: isDark ? Colors.white60 : colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = _selectedQuarterIndex != null &&
            _selectedQuarterIndex! < quarters.length
        ? _selectedQuarterIndex!
        : quarters.length - 1;
    final activeQuarter = quarters[activeIndex];

    final bool isActiveUp = activeQuarter.isUpcoming
        ? (activeQuarter.estimatedEps >= 0)
        : (activeQuarter.actualEps != null &&
            activeQuarter.actualEps! >= activeQuarter.estimatedEps);
    final activeColor = isActiveUp ? const Color(0xFF00C805) : const Color(0xFFFF3B30);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: "Earnings" ───────────────────────────────────────────
          Text(
            'Earnings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // ── EPS Dot Plot Canvas ───────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 180,
                width: constraints.maxWidth,
                child: GestureDetector(
                  onTapDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, quarters.length),
                  onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, quarters.length),
                  child: CustomPaint(
                    painter: _RobinhoodEarningsPainter(
                      quarters: quarters,
                      selectedIndex: activeIndex,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Selected Quarter EPS Detail Row (Exact Robinhood Design) ───────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B1F) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Column 1: Estimated EPS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Estimated EPS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor.withValues(alpha: 0.40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${activeQuarter.estimatedEps.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Column 2: Actual EPS / Expected Announcement
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Actual EPS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeQuarter.isUpcoming
                            ? (activeQuarter.upcomingDate.isNotEmpty && activeQuarter.upcomingDate != 'TBD' && activeQuarter.upcomingDate != 'Next Release'
                                ? 'Expected on ${activeQuarter.upcomingDate}, ${activeQuarter.reportTime}'
                                : 'Expected ${activeQuarter.reportTime}')
                            : '\$${activeQuarter.actualEps?.toStringAsFixed(2)} (${_formatBeatMiss(activeQuarter)})',
                        style: TextStyle(
                          fontSize: activeQuarter.isUpcoming ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: activeQuarter.isUpcoming
                              ? (isDark ? Colors.white70 : colorScheme.onSurfaceVariant)
                              : activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, double width, int count) {
    if (count <= 0 || width <= 0) return;
    final step = width / count;
    int index = (localPosition.dx / step).floor().clamp(0, count - 1);
    if (index != _selectedQuarterIndex) {
      setState(() {
        _selectedQuarterIndex = index;
      });
    }
  }

  static String _formatBeatMiss(_EarningsQuarter q) {
    if (q.actualEps == null) return '';
    final diff = q.actualEps! - q.estimatedEps;
    if (diff >= 0) {
      return 'Beat by +\$${diff.toStringAsFixed(2)}';
    } else {
      return 'Missed by -\$${diff.abs().toStringAsFixed(2)}';
    }
  }

  static List<_EarningsQuarter> _generateEarningsData(
    String symbol,
    MarketFundamentals fundamentals,
    double currentPrice,
  ) {
    final rawList = fundamentals.fields['earningsPrices'];
    if (rawList is List && rawList.isNotEmpty) {
      final List<_EarningsQuarter> quarters = [];
      for (final rawItem in rawList) {
        if (rawItem is Map) {
          final top = rawItem['topLabel']?.toString() ?? 'Q1';
          final bottom = rawItem['bottomLabel']?.toString() ?? 'FY25';
            final est = rawItem['estimatedEps'] is num
              ? (rawItem['estimatedEps'] as num).toDouble()
              : double.tryParse(rawItem['estimatedEps']?.toString() ?? '');
            if (est == null) continue;
          final act = (rawItem['actualEps'] as num?)?.toDouble();
          final isUp = rawItem['isUpcoming'] == true || act == null;
          final upDate = rawItem['upcomingDate']?.toString() ?? 'Next Release';
          final rTime = rawItem['reportTime']?.toString() ?? 'After-hours';

          quarters.add(
            _EarningsQuarter(
              topLabel: top,
              bottomLabel: bottom,
              estimatedEps: est,
              actualEps: act,
              isUpcoming: isUp,
              upcomingDate: upDate,
              reportTime: rTime,
            ),
          );
        }
      }
      if (quarters.isNotEmpty) {
        return quarters;
      }
    }

    return const <_EarningsQuarter>[];
  }
}

class _EarningsQuarter {
  const _EarningsQuarter({
    required this.topLabel,
    required this.bottomLabel,
    required this.estimatedEps,
    required this.actualEps,
    required this.isUpcoming,
    this.upcomingDate = 'Next Release',
    this.reportTime = 'After-hours',
  });

  final String topLabel;
  final String bottomLabel;
  final double estimatedEps;
  final double? actualEps;
  final bool isUpcoming;
  final String upcomingDate;
  final String reportTime;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EARNINGS CUSTOM PAINTER (Dot Plot Lollipop Style)
/// ─────────────────────────────────────────────────────────────────────────────
class _RobinhoodEarningsPainter extends CustomPainter {
  _RobinhoodEarningsPainter({
    required this.quarters,
    required this.selectedIndex,
    required this.isDark,
  });

  final List<_EarningsQuarter> quarters;
  final int selectedIndex;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (quarters.isEmpty) return;

    const leftPadding = 38.0;
    const bottomPadding = 38.0;
    const topPadding = 18.0;

    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Collect all EPS values for Y-axis scaling
    final List<double> allValues = [];
    for (final q in quarters) {
      allValues.add(q.estimatedEps);
      if (q.actualEps != null) allValues.add(q.actualEps!);
    }

    final rawMin = allValues.reduce(math.min);
    final rawMax = allValues.reduce(math.max);
    final spread = rawMax - rawMin;
    final pad = spread > 0.05 ? spread * 0.22 : 0.15;
    final minVal = rawMin - pad;
    final maxVal = rawMax + pad;
    final valRange = (maxVal - minVal) > 0.001 ? (maxVal - minVal) : 1.0;

    // ── 1. Draw Grid Lines & Y-Axis Labels ──────────────────────────────────
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    const gridDivisions = 3;
    for (int i = 0; i <= gridDivisions; i++) {
      final fraction = i / gridDivisions;
      final y = topPadding + chartHeight * (1 - fraction);
      final value = minVal + (valRange * fraction);

      // Grid line
      _drawDashedLine(canvas, Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      // Y-axis label on left
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(2),
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // ── 2. Draw EPS Dots per Quarter ─────────────────────────────────────────
    final periodStep = chartWidth / quarters.length;
    final baseY = topPadding + chartHeight;

    for (int i = 0; i < quarters.length; i++) {
      final q = quarters[i];
      final isSelected = i == selectedIndex;
      final groupCenterX = leftPadding + (i * periodStep) + (periodStep / 2);

      // Dynamic Green and Red functionality for Up / Down
      final bool isUp;
      if (q.isUpcoming || q.actualEps == null) {
        isUp = q.estimatedEps >= 0;
      } else {
        isUp = q.actualEps! >= q.estimatedEps;
      }
      final Color quarterColor = isUp ? const Color(0xFF00C805) : const Color(0xFFFF3B30);

      // Highlight background on selected quarter
      if (isSelected) {
        final highlightRect = Rect.fromLTWH(
          leftPadding + (i * periodStep) + 2,
          topPadding - 6,
          periodStep - 4,
          chartHeight + 10,
        );
        final highlightPaint = Paint()
          ..color = quarterColor.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)), highlightPaint);
      }

      final estY = topPadding + chartHeight - ((q.estimatedEps - minVal) / valRange * chartHeight);

      if (q.isUpcoming || q.actualEps == null) {
        // Upcoming Quarter: draw estimated dot with subtle outline in dynamic green/red
        final upcomingPaint = Paint()
          ..color = quarterColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(groupCenterX, estY), isSelected ? 8.5 : 7.5, upcomingPaint);
        // Subtle outline ring
        canvas.drawCircle(
          Offset(groupCenterX, estY),
          isSelected ? 8.5 : 7.5,
          Paint()
            ..color = quarterColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        final actY = topPadding + chartHeight - ((q.actualEps! - minVal) / valRange * chartHeight);

        // Subtle connector between estimated and actual
        canvas.drawLine(
          Offset(groupCenterX, estY),
          Offset(groupCenterX, actY),
          Paint()
            ..color = quarterColor.withValues(alpha: 0.28)
            ..strokeWidth = 1.5,
        );

        // Draw Estimated Dot (below/behind - muted shade of green/red)
        final estimatedDotPaint = Paint()
          ..color = quarterColor.withValues(alpha: 0.40)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(groupCenterX, estY), isSelected ? 8.0 : 7.0, estimatedDotPaint);

        // Draw Actual Dot (top/bright - vivid green for up, red for down)
        final actualDotPaint = Paint()
          ..color = quarterColor
          ..style = PaintingStyle.fill;

        if (isSelected) {
          // Glow halo on selected actual dot
          canvas.drawCircle(
            Offset(groupCenterX, actY),
            11.0,
            Paint()..color = quarterColor.withValues(alpha: 0.25),
          );
        }
        canvas.drawCircle(Offset(groupCenterX, actY), isSelected ? 8.5 : 7.5, actualDotPaint);
      }

      // ── X-Axis Period Label ───────────────────────────────────────────────
      final labelColor = isSelected
          ? (isDark ? Colors.white : Colors.black)
          : (isDark ? Colors.white54 : Colors.black54);
      final labelWeight = isSelected ? FontWeight.bold : FontWeight.w500;

      // Top label (e.g. Q4)
      textPainter.text = TextSpan(
        text: q.topLabel,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: labelWeight,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - (textPainter.width / 2), baseY + 6),
      );

      // Bottom label (e.g. FY25)
      textPainter.text = TextSpan(
        text: q.bottomLabel,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: labelWeight,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - (textPainter.width / 2), baseY + 20),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = p1.dx;
    while (currentX < p2.dx) {
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(math.min(currentX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _RobinhoodEarningsPainter oldDelegate) {
    return oldDelegate.quarters != quarters ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
