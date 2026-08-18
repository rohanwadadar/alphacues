import 'package:flutter/material.dart';

import '../data/screener_models.dart';

class ScreenerFilterDialog extends StatefulWidget {
  const ScreenerFilterDialog({super.key, required this.initialFilter});

  final ScreenerFilter initialFilter;

  static Future<ScreenerFilter?> show(
    BuildContext context,
    ScreenerFilter initialFilter,
  ) {
    return showModalBottomSheet<ScreenerFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ScreenerFilterDialog(initialFilter: initialFilter),
    );
  }

  @override
  State<ScreenerFilterDialog> createState() => _ScreenerFilterDialogState();
}

class _ScreenerFilterDialogState extends State<ScreenerFilterDialog> {
  late TextEditingController _marketCapMinController;
  late TextEditingController _marketCapMaxController;
  late TextEditingController _peMinController;
  late TextEditingController _peMaxController;
  late TextEditingController _priceMinController;
  late TextEditingController _priceMaxController;
  late TextEditingController _changeMinController;
  late TextEditingController _changeMaxController;
  late TextEditingController _divMinController;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    _marketCapMinController = TextEditingController(
      text: f.marketCapMin != null ? (f.marketCapMin! / 1e9).toStringAsFixed(1) : '',
    );
    _marketCapMaxController = TextEditingController(
      text: f.marketCapMax != null ? (f.marketCapMax! / 1e9).toStringAsFixed(1) : '',
    );
    _peMinController = TextEditingController(text: f.peRatioMin?.toString() ?? '');
    _peMaxController = TextEditingController(text: f.peRatioMax?.toString() ?? '');
    _priceMinController = TextEditingController(text: f.priceMin?.toString() ?? '');
    _priceMaxController = TextEditingController(text: f.priceMax?.toString() ?? '');
    _changeMinController = TextEditingController(text: f.changePercentMin?.toString() ?? '');
    _changeMaxController = TextEditingController(text: f.changePercentMax?.toString() ?? '');
    _divMinController = TextEditingController(text: f.dividendYieldMin?.toString() ?? '');
  }

  @override
  void dispose() {
    _marketCapMinController.dispose();
    _marketCapMaxController.dispose();
    _peMinController.dispose();
    _peMaxController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _changeMinController.dispose();
    _changeMaxController.dispose();
    _divMinController.dispose();
    super.dispose();
  }

  double? _parseDouble(TextEditingController controller, {double multiplier = 1.0}) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final val = double.tryParse(text);
    return val != null ? val * multiplier : null;
  }

  void _apply() {
    final filter = ScreenerFilter(
      marketCapMin: _parseDouble(_marketCapMinController, multiplier: 1e9),
      marketCapMax: _parseDouble(_marketCapMaxController, multiplier: 1e9),
      peRatioMin: _parseDouble(_peMinController),
      peRatioMax: _parseDouble(_peMaxController),
      priceMin: _parseDouble(_priceMinController),
      priceMax: _parseDouble(_priceMaxController),
      changePercentMin: _parseDouble(_changeMinController),
      changePercentMax: _parseDouble(_changeMaxController),
      dividendYieldMin: _parseDouble(_divMinController),
    );
    Navigator.of(context).pop(filter);
  }

  void _reset() {
    Navigator.of(context).pop(const ScreenerFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Stocks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset All')),
              ],
            ),
            const SizedBox(height: 16),
            _buildRangeRow(
              title: 'Market Cap (\$B)',
              minController: _marketCapMinController,
              maxController: _marketCapMaxController,
              minHint: 'Min (e.g. 100)',
              maxHint: 'Max (e.g. 3000)',
            ),
            const SizedBox(height: 12),
            _buildRangeRow(
              title: 'P/E Ratio',
              minController: _peMinController,
              maxController: _peMaxController,
              minHint: 'Min P/E',
              maxHint: 'Max P/E',
            ),
            const SizedBox(height: 12),
            _buildRangeRow(
              title: 'Stock Price (\$) ',
              minController: _priceMinController,
              maxController: _priceMaxController,
              minHint: 'Min \$',
              maxHint: 'Max \$',
            ),
            const SizedBox(height: 12),
            _buildRangeRow(
              title: 'Daily Change (%)',
              minController: _changeMinController,
              maxController: _changeMaxController,
              minHint: 'Min %',
              maxHint: 'Max %',
            ),
            const SizedBox(height: 12),
            Text(
              'Min Dividend Yield (%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _divMinController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 0.5',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeRow({
    required String title,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String minHint,
    required String maxHint,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: minHint,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('–'),
            ),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: maxHint,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
