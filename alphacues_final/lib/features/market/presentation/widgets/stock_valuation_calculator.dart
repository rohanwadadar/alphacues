import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class StockValuationCalculator extends StatefulWidget {
  const StockValuationCalculator({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  final String symbol;
  final double currentPrice;

  @override
  State<StockValuationCalculator> createState() => _StockValuationCalculatorState();
}

class _StockValuationCalculatorState extends State<StockValuationCalculator> {
  double _initialInvestment = 1000;
  double _monthlyContribution = 200;
  double _annualReturnPercent = 12.0;
  int _years = 10;
  final double _inflationPercent = 2.5;
  final bool _adjustInflation = true;
  bool _showTimeline = false;

  void _applyPreset({
    required double initial,
    required double monthly,
    required double rate,
    required int years,
  }) {
    setState(() {
      _initialInvestment = initial;
      _monthlyContribution = monthly;
      _annualReturnPercent = rate;
      _years = years;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ── MATH CALCULATIONS ───────────────────────────────────────────────────
    final t = _years.toDouble();
    final r = _annualReturnPercent / 100.0;
    final rMonthly = pow(1.0 + r, 1.0 / 12.0) - 1.0;
    final totalMonths = _years * 12;

    // Future Value of Initial Lump Sum
    final fvInitial = _initialInvestment * pow(1.0 + r, t);

    // Future Value of Monthly Contributions
    double fvMonthly = 0;
    if (rMonthly > 0 && totalMonths > 0) {
      fvMonthly = _monthlyContribution * ((pow(1.0 + rMonthly, totalMonths) - 1.0) / rMonthly);
    } else {
      fvMonthly = _monthlyContribution * totalMonths;
    }

    final totalFutureValue = fvInitial + fvMonthly;
    final totalPrincipal = _initialInvestment + (_monthlyContribution * totalMonths);
    final totalCompoundInterest = totalFutureValue - totalPrincipal;
    final totalReturnPercent = totalPrincipal > 0
        ? ((totalFutureValue - totalPrincipal) / totalPrincipal) * 100.0
        : 0.0;

    final estimatedShares = widget.currentPrice > 0
        ? totalFutureValue / widget.currentPrice
        : 0.0;

    final inflationRate = _inflationPercent / 100.0;
    final realPurchasingPower = _adjustInflation && inflationRate > 0
        ? totalFutureValue / pow(1.0 + inflationRate, t)
        : totalFutureValue;

    return Card(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ─────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calculate_outlined, color: colorScheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Compound Valuation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Simulate wealth growth for ${widget.symbol}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── QUICK PRESET CHIPS ──────────────────────────────────────────
            Text('Quick Presets', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('\$100/mo • 10 Yrs', () {
                    _applyPreset(initial: 500, monthly: 100, rate: 10.0, years: 10);
                  }),
                  _buildPresetChip('\$250/mo • 15 Yrs', () {
                    _applyPreset(initial: 1000, monthly: 250, rate: 12.0, years: 15);
                  }),
                  _buildPresetChip('\$500/mo • 20 Yrs', () {
                    _applyPreset(initial: 2500, monthly: 500, rate: 12.5, years: 20);
                  }),
                  _buildPresetChip('\$1,000/mo • 25 Yrs', () {
                    _applyPreset(initial: 5000, monthly: 1000, rate: 15.0, years: 25);
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── SLIDERS & INPUT CONTROLS ───────────────────────────────────
            // 1. Initial Investment
            _buildSliderControl(
              context,
              label: 'Initial Lump Sum Investment',
              valueDisplay: '\$${_initialInvestment.toStringAsFixed(0)}',
              value: _initialInvestment,
              min: 0,
              max: 25000,
              divisions: 250,
              onChanged: (val) => setState(() => _initialInvestment = val),
            ),
            const SizedBox(height: 12),

            // 2. Monthly Contribution
            _buildSliderControl(
              context,
              label: 'Monthly Recurring Investment',
              valueDisplay: '\$${_monthlyContribution.toStringAsFixed(0)}/mo',
              value: _monthlyContribution,
              min: 0,
              max: 5000,
              divisions: 100,
              onChanged: (val) => setState(() => _monthlyContribution = val),
            ),
            const SizedBox(height: 12),

            // 3. Expected Annual Return (% CAGR)
            _buildSliderControl(
              context,
              label: 'Expected Annual Return (CAGR %)',
              valueDisplay: '${_annualReturnPercent.toStringAsFixed(1)}%',
              value: _annualReturnPercent,
              min: 1.0,
              max: 30.0,
              divisions: 58,
              activeColor: Colors.teal,
              onChanged: (val) => setState(() => _annualReturnPercent = val),
            ),
            const SizedBox(height: 12),

            // 4. Time Horizon (Years)
            _buildSliderControl(
              context,
              label: 'Investment Time Horizon',
              valueDisplay: '$_years Years',
              value: _years.toDouble(),
              min: 1,
              max: 35,
              divisions: 34,
              activeColor: Colors.indigo,
              onChanged: (val) => setState(() => _years = val.toInt()),
            ),
            const SizedBox(height: 16),

            // ── RESULTS HIGHLIGHT CARD ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROJECTED FUTURE VALUE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${totalReturnPercent.toStringAsFixed(1)}% Return',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${_formatCurrency(totalFutureValue)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Visual Progress Bar Breakdown
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(
                            flex: max(1, totalPrincipal.toInt()),
                            child: Container(color: colorScheme.primary),
                          ),
                          Expanded(
                            flex: max(1, totalCompoundInterest.toInt()),
                            child: Container(color: Colors.teal.shade400),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Legend Metrics
                  Row(
                    children: [
                      _buildLegendItem(
                        context,
                        color: colorScheme.primary,
                        label: 'Invested Capital',
                        value: '\$${_formatCurrency(totalPrincipal)}',
                      ),
                      const SizedBox(width: 16),
                      _buildLegendItem(
                        context,
                        color: Colors.teal.shade400,
                        label: 'Compound Returns',
                        value: '\$${_formatCurrency(totalCompoundInterest)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── EXTRA METRICS: SHARES & INFLATION ADJUSTMENT ──────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Est. Shares of ${widget.symbol}:', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      Text(
                        '~${estimatedShares.toStringAsFixed(1)} shares',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_outlined, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text('Inflation-Adjusted Value:', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      Text(
                        '\$${_formatCurrency(realPurchasingPower)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── TOGGLE TIMELINE EXPANSION ──────────────────────────────────
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colorScheme.primary,
              ),
              onPressed: () => setState(() => _showTimeline = !_showTimeline),
              icon: Icon(_showTimeline ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              label: Text(_showTimeline ? 'Hide Year-by-Year Growth Table' : 'View Year-by-Year Growth Projection'),
            ),

            if (_showTimeline) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Invested', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Interest Earned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('End Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    ...List.generate(min(_years, 10), (index) {
                      final yearNum = ((index + 1) * (_years / min(_years, 10))).round();
                      final yVal = yearNum.toDouble();
                      final yMonths = yearNum * 12;

                      final yInitial = _initialInvestment * pow(1.0 + r, yVal);
                      final yMonthly = rMonthly > 0
                          ? _monthlyContribution * ((pow(1.0 + rMonthly, yMonths) - 1.0) / rMonthly)
                          : _monthlyContribution * yMonths;

                      final yTotal = yInitial + yMonthly;
                      final yInvested = _initialInvestment + (_monthlyContribution * yMonths);
                      final yInterest = yTotal - yInvested;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Year $yearNum', style: const TextStyle(fontSize: 12)),
                            Text('\$${_formatCurrency(yInvested)}', style: const TextStyle(fontSize: 12)),
                            Text('\$${_formatCurrency(yInterest)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                            Text('\$${_formatCurrency(yTotal)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSliderControl(
    BuildContext context, {
    required String label,
    required String valueDisplay,
    required double value,
    required double min,
    required double max,
    required int divisions,
    Color? activeColor,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(
              valueDisplay,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: activeColor ?? colorScheme.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: activeColor ?? colorScheme.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(2)}B';
    }
    if (amount >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(2)}M';
    }
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }
}
