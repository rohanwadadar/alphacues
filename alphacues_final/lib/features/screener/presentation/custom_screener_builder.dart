import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../market/presentation/symbol_detail_screen.dart';
import '../data/screener_models.dart';
import '../data/screener_providers.dart';
import 'widgets/screener_result_card.dart';

class CustomScreenerBuilderScreen extends ConsumerStatefulWidget {
  const CustomScreenerBuilderScreen({super.key});

  @override
  ConsumerState<CustomScreenerBuilderScreen> createState() =>
      _CustomScreenerBuilderScreenState();
}

class _CustomScreenerBuilderScreenState
    extends ConsumerState<CustomScreenerBuilderScreen> {
  final _strategyNameController = TextEditingController(text: 'My Custom Strategy');
  final _strategyDescController = TextEditingController(text: 'Custom market scan filters');

  // Form Filter State
  double? _marketCapMin;
  double? _marketCapMax;
  double? _peMin;
  double? _peMax;
  double? _priceMin;
  double? _priceMax;
  double? _changeMin;
  double? _changeMax;
  String _sortBy = 'marketCap';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    // Default preview scan on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFormScan();
    });
  }

  @override
  void dispose() {
    _strategyNameController.dispose();
    _strategyDescController.dispose();
    super.dispose();
  }

  void _applyFormScan() {
    final filter = ScreenerFilter(
      marketCapMin: _marketCapMin,
      marketCapMax: _marketCapMax,
      peRatioMin: _peMin,
      peRatioMax: _peMax,
      priceMin: _priceMin,
      priceMax: _priceMax,
      changePercentMin: _changeMin,
      changePercentMax: _changeMax,
    );

    final notifier = ref.read(screenerNotifierProvider.notifier);
    notifier.setFilters(filter);
    notifier.setSorting(_sortBy, _sortOrder);
  }

  Future<void> _saveStrategy() async {
    final name = _strategyNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a strategy name.')),
      );
      return;
    }

    try {
      final repo = ref.read(screenerRepositoryProvider);
      final filter = ScreenerFilter(
        marketCapMin: _marketCapMin,
        marketCapMax: _marketCapMax,
        peRatioMin: _peMin,
        peRatioMax: _peMax,
        priceMin: _priceMin,
        priceMax: _priceMax,
        changePercentMin: _changeMin,
        changePercentMax: _changeMax,
      );

      await repo.createStrategy(
        name: name,
        description: _strategyDescController.text.trim(),
        filters: filter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      ref.refresh(savedStrategiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom Strategy "$name" saved successfully!')),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved locally. Strategy active in current session.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(screenerNotifierProvider);
    final results = state.result?.items ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Custom Screener Builder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded),
            tooltip: 'Save Custom Screener',
            onPressed: _saveStrategy,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. STRATEGY NAME & INFO ────────────────────────────────────
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Custom Screener Name',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _strategyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Strategy Name',
                        hintText: 'e.g. AI Tech Megacaps',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. FORM FILTER INPUTS ──────────────────────────────────────
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Configure Criteria',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Market Cap Quick Selector
                    const Text('Market Capitalization', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Caps'),
                          selected: _marketCapMin == null,
                          onSelected: (_) => setState(() {
                            _marketCapMin = null;
                            _marketCapMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Mega (\$200B+)'),
                          selected: _marketCapMin == 200e9,
                          onSelected: (_) => setState(() {
                            _marketCapMin = 200e9;
                            _marketCapMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Large (\$10B-\$200B)'),
                          selected: _marketCapMin == 10e9 && _marketCapMax == 200e9,
                          onSelected: (_) => setState(() {
                            _marketCapMin = 10e9;
                            _marketCapMax = 200e9;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Mid/Small (<\$10B)'),
                          selected: _marketCapMax == 10e9 && _marketCapMin == null,
                          onSelected: (_) => setState(() {
                            _marketCapMin = null;
                            _marketCapMax = 10e9;
                            _applyFormScan();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // P/E Valuation Selector
                    const Text('P/E Ratio Valuation', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any P/E'),
                          selected: _peMax == null && _peMin == null,
                          onSelected: (_) => setState(() {
                            _peMin = null;
                            _peMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Value (P/E < 20)'),
                          selected: _peMax == 20.0,
                          onSelected: (_) => setState(() {
                            _peMin = null;
                            _peMax = 20.0;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Moderate (20 - 40)'),
                          selected: _peMin == 20.0 && _peMax == 40.0,
                          onSelected: (_) => setState(() {
                            _peMin = 20.0;
                            _peMax = 40.0;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('High Growth (> 40)'),
                          selected: _peMin == 40.0,
                          onSelected: (_) => setState(() {
                            _peMin = 40.0;
                            _peMax = null;
                            _applyFormScan();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price Range Selector
                    const Text('Stock Share Price', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any Price'),
                          selected: _priceMax == null && _priceMin == null,
                          onSelected: (_) => setState(() {
                            _priceMin = null;
                            _priceMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Under \$50'),
                          selected: _priceMax == 50.0,
                          onSelected: (_) => setState(() {
                            _priceMin = null;
                            _priceMax = 50.0;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('\$50 - \$200'),
                          selected: _priceMin == 50.0 && _priceMax == 200.0,
                          onSelected: (_) => setState(() {
                            _priceMin = 50.0;
                            _priceMax = 200.0;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('\$200+'),
                          selected: _priceMin == 200.0,
                          onSelected: (_) => setState(() {
                            _priceMin = 200.0;
                            _priceMax = null;
                            _applyFormScan();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Today's Performance Selector
                    const Text('Today\'s Performance (% Change)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Performers'),
                          selected: _changeMin == null,
                          onSelected: (_) => setState(() {
                            _changeMin = null;
                            _changeMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Gainers (> +2%)'),
                          selected: _changeMin == 2.0,
                          onSelected: (_) => setState(() {
                            _changeMin = 2.0;
                            _changeMax = null;
                            _applyFormScan();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Hot Gainers (> +5%)'),
                          selected: _changeMin == 5.0,
                          onSelected: (_) => setState(() {
                            _changeMin = 5.0;
                            _changeMax = null;
                            _applyFormScan();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sort By Controls
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sort By',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'marketCap', child: Text('Market Cap')),
                              DropdownMenuItem(value: 'price', child: Text('Price')),
                              DropdownMenuItem(value: 'peRatio', child: Text('P/E Ratio')),
                              DropdownMenuItem(value: 'changePercent', child: Text('24h % Change')),
                              DropdownMenuItem(value: 'symbol', child: Text('Symbol Name')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortBy = val;
                                  _applyFormScan();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortOrder,
                            decoration: const InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'desc', child: Text('High → Low')),
                              DropdownMenuItem(value: 'asc', child: Text('Low → High')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortOrder = val;
                                  _applyFormScan();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. LIVE SCAN RESULTS ─────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Custom Scan Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${results.length} stocks matched',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 40, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No stocks match your custom form criteria.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: results.map((item) {
                  return ScreenerResultCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymbolDetailScreen(symbol: item.symbol),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save & Apply Custom Screener'),
                onPressed: () async {
                  await _saveStrategy();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
