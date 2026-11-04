import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

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
  double _numberOfShares = 10;
  late double _stockPrice;
  double _annualReturnPercent = 12.0;
  int _years = 10;

  @override
  void initState() {
    super.initState();
    _stockPrice = widget.currentPrice > 0 ? widget.currentPrice : 150.0;
  }

  @override
  void didUpdateWidget(covariant StockValuationCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPrice != oldWidget.currentPrice && widget.currentPrice > 0) {
      _stockPrice = widget.currentPrice;
    }
  }

  void _applyPreset({
    required double shares,
    required double price,
    required double rate,
    required int years,
  }) {
    setState(() {
      _numberOfShares = shares;
      _stockPrice = price;
      _annualReturnPercent = rate;
      _years = years;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final initialCapital = _numberOfShares * _stockPrice;
    final r = _annualReturnPercent / 100.0;
    final t = _years.toDouble();
    final projectedFutureValue = initialCapital * pow(1.0 + r, t);
    final totalProfit = projectedFutureValue - initialCapital;
    final totalReturnPercent = initialCapital > 0
        ? ((projectedFutureValue - initialCapital) / initialCapital) * 100.0
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
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
                      'Simulate investment growth for ${widget.symbol}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── QUICK PRESET CHIPS ──────────────────────────────────────────
          Text('Quick Presets', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('10 Shares • 5 Yrs', () {
                  _applyPreset(shares: 10, price: widget.currentPrice > 0 ? widget.currentPrice : 150.0, rate: 10.0, years: 5);
                }),
                _buildPresetChip('25 Shares • 10 Yrs', () {
                  _applyPreset(shares: 25, price: widget.currentPrice > 0 ? widget.currentPrice : 150.0, rate: 12.0, years: 10);
                }),
                _buildPresetChip('50 Shares • 15 Yrs', () {
                  _applyPreset(shares: 50, price: widget.currentPrice > 0 ? widget.currentPrice : 150.0, rate: 14.0, years: 15);
                }),
                _buildPresetChip('100 Shares • 20 Yrs', () {
                  _applyPreset(shares: 100, price: widget.currentPrice > 0 ? widget.currentPrice : 150.0, rate: 15.0, years: 20);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SLIDERS & INPUT CONTROLS ───────────────────────────────────
          // 1. Number of Shares
          _buildSliderControl(
            context,
            label: 'Number of Shares',
            valueDisplay: '${_numberOfShares.toInt()} Shares',
            value: _numberOfShares,
            min: 1,
            max: 500,
            divisions: 499,
            activeColor: colorScheme.primary,
            onChanged: (val) => setState(() => _numberOfShares = val),
          ),
          const SizedBox(height: 14),

          // 2. Current Stock Amount / Price
          _buildSliderControl(
            context,
            label: 'Current Stock Amount / Price',
            valueDisplay: '\$${_stockPrice.toStringAsFixed(2)}',
            value: _stockPrice.clamp(1.0, 2000.0),
            min: 1.0,
            max: 2000.0,
            divisions: 1999,
            activeColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _stockPrice = val),
          ),
          const SizedBox(height: 14),

          // 3. Expected Annual Return (%)
          _buildSliderControl(
            context,
            label: 'Expected Annual Return (%)',
            valueDisplay: '${_annualReturnPercent.toStringAsFixed(1)}%',
            value: _annualReturnPercent,
            min: 1.0,
            max: 30.0,
            divisions: 58,
            activeColor: Colors.teal,
            onChanged: (val) => setState(() => _annualReturnPercent = val),
          ),
          const SizedBox(height: 14),

          // 4. Time Horizon (How many years)
          _buildSliderControl(
            context,
            label: 'Investment Time Horizon (Years)',
            valueDisplay: '$_years Years',
            value: _years.toDouble(),
            min: 1,
            max: 35,
            divisions: 34,
            activeColor: Colors.indigo,
            onChanged: (val) => setState(() => _years = val.toInt()),
          ),
          const SizedBox(height: 20),

          // ── RESULTS HIGHLIGHT CARD ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.6),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                  '\$${_formatCurrency(projectedFutureValue)}',
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
                          flex: max(1, initialCapital.toInt()),
                          child: Container(color: colorScheme.primary),
                        ),
                        Expanded(
                          flex: max(1, totalProfit.toInt()),
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
                      label: 'Initial Investment',
                      value: '\$${_formatCurrency(initialCapital)}',
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      context,
                      color: Colors.teal.shade400,
                      label: 'Compound Gains',
                      value: '\$${_formatCurrency(totalProfit)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
