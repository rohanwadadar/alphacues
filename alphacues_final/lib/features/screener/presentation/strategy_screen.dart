import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/safe_screen.dart';
import '../data/screener_providers.dart';
import 'widgets/screener_result_card.dart';

/// Strategy Builder Screen — Redesigned v2
class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key, this.openCreateOnLaunch = false});

  final bool openCreateOnLaunch;

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  final _strategyNameController = TextEditingController();

  ScreenerFilter _currentFilter = const ScreenerFilter();
  String _selectedStrategyType = '';
  String _sortBy = 'marketCap';
  String _sortOrder = 'desc';

  // Technical & MA Filter state toggles
  String _techVolume = 'Any'; // Any, >500K, >1M, >5M
  String _rsiFilter = 'Any'; // Any, Oversold (<30), Normal (30-70), Overbought (>70)
  bool _above50MA = false;
  bool _above200MA = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runScan();
      if (widget.openCreateOnLaunch) {
        _openAddStrategyModal();
      }
    });
  }

  @override
  void dispose() {
    _strategyNameController.dispose();
    super.dispose();
  }

  void _runScan() {
    final notifier = ref.read(screenerNotifierProvider.notifier);
    notifier.setFilters(_currentFilter);
    notifier.setSorting(_sortBy, _sortOrder);
  }

  Future<void> _saveStrategy(String name) async {
    if (name.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a strategy name.')),
      );
      return;
    }
    final ok = await ref.read(savedStrategiesProvider.notifier).saveStrategy(
          name: name.trim(),
          filters: _currentFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          description: _selectedStrategyType.isNotEmpty
              ? '$_selectedStrategyType strategy'
              : 'Custom market scan strategy',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Strategy "$name" saved!' : 'Failed to save strategy.'),
        backgroundColor: ok ? const Color(0xFF673AB7) : Colors.purple.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyPreset(ScreenerStrategy strategy) {
    setState(() {
      _currentFilter = strategy.filters;
      _sortBy = strategy.sortBy;
      _sortOrder = strategy.sortOrder;
      _strategyNameController.text = strategy.name;
    });
    ref.read(screenerNotifierProvider.notifier).applySavedStrategy(strategy);
    _runScan();
  }

  Future<void> _deleteStrategy(int strategyId) async {
    final ok =
        await ref.read(savedStrategiesProvider.notifier).deleteStrategy(strategyId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Strategy deleted.' : 'Failed to delete strategy.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteStrategy(ScreenerStrategy strategy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Warning: Delete Strategy'),
          ],
        ),
        content: Text(
          'Warning: Are you sure you want to delete strategy "${strategy.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteStrategy(strategy.strategyId);
    }
  }

  // ── "Add New Strategy" Popup Modal ───────────────────────────────────────
  void _openAddStrategyModal() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController(text: _strategyNameController.text);
    
    // Temp local filter state for modal
    var tempFilter = _currentFilter;
    var tempType = _selectedStrategyType;
    var tempTechVolume = _techVolume;
    var tempRsi = _rsiFilter;
    var temp50MA = _above50MA;
    var temp200MA = _above200MA;

    final mktCapMinController = TextEditingController(
      text: tempFilter.marketCapMin != null
          ? (tempFilter.marketCapMin! / 1e9).toStringAsFixed(0)
          : '',
    );
    final peMinController = TextEditingController(
      text: tempFilter.peRatioMin?.toString() ?? '',
    );
    final priceMinController = TextEditingController(
      text: tempFilter.priceMin?.toString() ?? '',
    );
    final changeMinController = TextEditingController(
      text: tempFilter.changePercentMin?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void applyStrategyTypePreset(String type) {
              setModalState(() {
                tempType = type;
                if (nameController.text.trim().isEmpty) {
                  nameController.text = '$type Strategy';
                }
                if (type == 'Breakout') {
                  changeMinController.text = '3';
                  tempTechVolume = '>1M';
                } else if (type == 'Growth') {
                  mktCapMinController.text = '10';
                  peMinController.text = '15';
                } else if (type == 'Value') {
                  peMinController.text = '5';
                } else if (type == 'Momentum') {
                  changeMinController.text = '2';
                  temp50MA = true;
                } else if (type == 'Dividend') {
                  mktCapMinController.text = '5';
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.add_chart_rounded, color: colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Create New Strategy',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Strategy Name Field ───────────────────────────
                          Text(
                            'Strategy Name',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Breakout Momentum Strategy',
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Strategy Type Selector ────────────────────────
                          Text(
                            '1. Strategy Type',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Breakout',
                              'Growth',
                              'Value',
                              'Momentum',
                              'Dividend'
                            ].map((type) {
                              final isSelected = tempType == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                selectedColor: colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                ),
                                onSelected: (_) => applyStrategyTypePreset(type),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // ── Fundamentals Filter Section ───────────────────
                          Text(
                            '2. Fundamental Filters',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: mktCapMinController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Min Mkt Cap (\$B)',
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: peMinController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Min P/E Ratio',
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: priceMinController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Min Stock Price (\$)',
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: changeMinController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Min Day Change (%)',
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Technical Indicators Section ─────────────────
                          Text(
                            '3. Technical Filters',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Avg Volume', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: ['Any', '>500K', '>1M', '>5M'].map((v) {
                              final sel = tempTechVolume == v;
                              return ChoiceChip(
                                label: Text(v, style: const TextStyle(fontSize: 12)),
                                selected: sel,
                                onSelected: (_) => setModalState(() => tempTechVolume = v),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Text('RSI (14)', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: ['Any', 'Oversold (<30)', 'Normal (30-70)', 'Overbought (>70)'].map((rsi) {
                              final sel = tempRsi == rsi;
                              return ChoiceChip(
                                label: Text(rsi, style: const TextStyle(fontSize: 12)),
                                selected: sel,
                                onSelected: (_) => setModalState(() => tempRsi = rsi),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // ── Moving Averages Section ───────────────────────
                          Text(
                            '4. Moving Averages',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Price Above 50-Day Moving Average', style: TextStyle(fontSize: 14)),
                            value: temp50MA,
                            onChanged: (val) => setModalState(() => temp50MA = val ?? false),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Price Above 200-Day Moving Average', style: TextStyle(fontSize: 14)),
                            value: temp200MA,
                            onChanged: (val) => setModalState(() => temp200MA = val ?? false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Modal Actions ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final minCap = double.tryParse(mktCapMinController.text) != null
                                  ? double.parse(mktCapMinController.text) * 1e9
                                  : null;
                              final minPe = double.tryParse(peMinController.text);
                              final minPrice = double.tryParse(priceMinController.text);
                              final minChg = double.tryParse(changeMinController.text);

                              setState(() {
                                _currentFilter = ScreenerFilter(
                                  marketCapMin: minCap,
                                  peRatioMin: minPe,
                                  priceMin: minPrice,
                                  changePercentMin: minChg,
                                );
                                _selectedStrategyType = tempType;
                                _techVolume = tempTechVolume;
                                _rsiFilter = tempRsi;
                                _above50MA = temp50MA;
                                _above200MA = temp200MA;
                                _strategyNameController.text = nameController.text;
                              });
                              _runScan();
                              Navigator.of(modalContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Run Screener', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final minCap = double.tryParse(mktCapMinController.text) != null
                                  ? double.parse(mktCapMinController.text) * 1e9
                                  : null;
                              final minPe = double.tryParse(peMinController.text);
                              final minPrice = double.tryParse(priceMinController.text);
                              final minChg = double.tryParse(changeMinController.text);

                              final updatedFilter = ScreenerFilter(
                                marketCapMin: minCap,
                                peRatioMin: minPe,
                                priceMin: minPrice,
                                changePercentMin: minChg,
                              );

                              setState(() {
                                _currentFilter = updatedFilter;
                                _selectedStrategyType = tempType;
                                _techVolume = tempTechVolume;
                                _rsiFilter = tempRsi;
                                _above50MA = temp50MA;
                                _above200MA = temp200MA;
                                _strategyNameController.text = nameController.text;
                              });
                              _runScan();
                              Navigator.of(modalContext).pop();
                              await _saveStrategy(nameController.text);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Save Strategy', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Sort Options Modal (Detailed Low to High / High to Low) ───────────────
  String _getSortLabel(String sortBy, String sortOrder) {
    final isAsc = sortOrder == 'asc';
    switch (sortBy) {
      case 'marketCap':
        return isAsc ? 'Mkt Cap (Low → High)' : 'Mkt Cap (High → Low)';
      case 'price':
        return isAsc ? 'Price (Low → High)' : 'Price (High → Low)';
      case 'changePercent':
        return isAsc ? 'Change% (Low → High)' : 'Change% (High → Low)';
      case 'peRatio':
        return isAsc ? 'P/E (Low → High)' : 'P/E (High → Low)';
      case 'symbol':
        return isAsc ? 'Symbol (A → Z)' : 'Symbol (Z → A)';
      default:
        return 'Default';
    }
  }

  void _openSortModal() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String tempSortBy = _sortBy;
    String tempSortOrder = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final options = [
              {
                'title': 'Market Capitalization: High to Low',
                'subtitle': 'Largest & mega-cap companies first',
                'sortBy': 'marketCap',
                'sortOrder': 'desc',
                'icon': Icons.pie_chart_outline_rounded,
              },
              {
                'title': 'Market Capitalization: Low to High',
                'subtitle': 'Small-cap & mid-cap companies first',
                'sortBy': 'marketCap',
                'sortOrder': 'asc',
                'icon': Icons.pie_chart_outline_rounded,
              },
              {
                'title': 'Stock Price: High to Low',
                'subtitle': 'Highest priced stocks first',
                'sortBy': 'price',
                'sortOrder': 'desc',
                'icon': Icons.attach_money_rounded,
              },
              {
                'title': 'Stock Price: Low to High',
                'subtitle': 'Lowest priced stocks first',
                'sortBy': 'price',
                'sortOrder': 'asc',
                'icon': Icons.attach_money_rounded,
              },
              {
                'title': 'Day Change %: High to Low',
                'subtitle': 'Top gainers first (+ %)',
                'sortBy': 'changePercent',
                'sortOrder': 'desc',
                'icon': Icons.trending_up_rounded,
              },
              {
                'title': 'Day Change %: Low to High',
                'subtitle': 'Top losers first (- %)',
                'sortBy': 'changePercent',
                'sortOrder': 'asc',
                'icon': Icons.trending_down_rounded,
              },
              {
                'title': 'P/E Ratio: Low to High',
                'subtitle': 'Lowest valuation / Value stocks first',
                'sortBy': 'peRatio',
                'sortOrder': 'asc',
                'icon': Icons.bar_chart_rounded,
              },
              {
                'title': 'P/E Ratio: High to Low',
                'subtitle': 'Highest valuation / Growth stocks first',
                'sortBy': 'peRatio',
                'sortOrder': 'desc',
                'icon': Icons.bar_chart_rounded,
              },
              {
                'title': 'Symbol: A to Z',
                'subtitle': 'Alphabetical order ascending',
                'sortBy': 'symbol',
                'sortOrder': 'asc',
                'icon': Icons.sort_by_alpha_rounded,
              },
              {
                'title': 'Symbol: Z to A',
                'subtitle': 'Alphabetical order descending',
                'sortBy': 'symbol',
                'sortOrder': 'desc',
                'icon': Icons.sort_by_alpha_rounded,
              },
            ];

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sort Options',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Select ordering criteria (Low to High / High to Low)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _sortBy = '';
                              _sortOrder = 'desc';
                            });
                            _runScan();
                            Navigator.of(modalContext).pop();
                          },
                          child: const Text('Deselect Sort', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        final isSelected = tempSortBy == opt['sortBy'] &&
                            tempSortOrder == opt['sortOrder'];

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSortBy = '';
                                tempSortOrder = 'desc';
                              } else {
                                tempSortBy = opt['sortBy'] as String;
                                tempSortOrder = opt['sortOrder'] as String;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt['title'] as String,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _sortBy = tempSortBy;
                            _sortOrder = tempSortOrder;
                          });
                          _runScan();
                          Navigator.of(modalContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Apply Sorting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── "See All" Saved Strategies Modal ────────────────────────────────────
  void _showAllStrategiesModal(List<ScreenerStrategy> strategies) {
    final theme = Theme.of(context);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? strategies
                : strategies
                    .where((s) => s.name.toLowerCase().contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'All Saved Strategies',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            Navigator.of(modalContext).pop();
                            _openAddStrategyModal();
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Add Strategy',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search saved strategies...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No strategies found', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected = _strategyNameController.text == item.name;
                              return _SavedStrategyItemTile(
                                strategy: item,
                                isSelected: isSelected,
                                onTap: () {
                                  Navigator.of(modalContext).pop();
                                  _applyPreset(item);
                                },
                                onEdit: () {
                                  Navigator.of(modalContext).pop();
                                  _applyPreset(item);
                                  _openAddStrategyModal();
                                },
                                onDelete: () {
                                  _confirmDeleteStrategy(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Filters Popup Modal (With Green Active Color Highlighting) ───────────
  void _openFiltersModal() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final f = _currentFilter;
            final isMktCapActive = f.marketCapMin != null || f.marketCapMax != null;
            final isPeActive = f.peRatioMin != null || f.peRatioMax != null;
            final isPriceActive = f.priceMin != null || f.priceMax != null;
            final isChangeActive = f.changePercentMin != null || f.changePercentMax != null;
            final isTypeActive = _selectedStrategyType.isNotEmpty;
            final isTechActive = _techVolume != 'Any' || _rsiFilter != 'Any';
            final isMAActive = _above50MA || _above200MA;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: Colors.green.shade600, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Applied Criteria & Filters',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentFilter = const ScreenerFilter();
                              _selectedStrategyType = '';
                              _techVolume = 'Any';
                              _rsiFilter = 'Any';
                              _above50MA = false;
                              _above200MA = false;
                            });
                            _runScan();
                            Navigator.of(modalContext).pop();
                          },
                          child: const Text('Reset All', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildFilterStateTile(
                          context,
                          title: 'Strategy Type',
                          subtitle: _selectedStrategyType.isNotEmpty ? _selectedStrategyType : 'Not Selected',
                          isActive: isTypeActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'Market Cap (\$B)',
                          subtitle: f.marketCapMin != null
                              ? 'Min \$${(f.marketCapMin! / 1e9).toStringAsFixed(0)}B'
                              : 'Any Cap',
                          isActive: isMktCapActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'P/E Ratio',
                          subtitle: f.peRatioMin != null ? 'Min ${f.peRatioMin}' : 'Any P/E',
                          isActive: isPeActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'Stock Price (\$) ',
                          subtitle: f.priceMin != null ? 'Min \$${f.priceMin}' : 'Any Price',
                          isActive: isPriceActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'Day Change (%)',
                          subtitle: f.changePercentMin != null ? 'Min ${f.changePercentMin}%' : 'Any Change',
                          isActive: isChangeActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'Technical Indicators',
                          subtitle: 'Volume: $_techVolume • RSI: $_rsiFilter',
                          isActive: isTechActive,
                        ),
                        _buildFilterStateTile(
                          context,
                          title: 'Moving Averages',
                          subtitle: '50MA: ${_above50MA ? "Active" : "Off"} • 200MA: ${_above200MA ? "Active" : "Off"}',
                          isActive: isMAActive,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                        _openAddStrategyModal();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Edit Filter Criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterStateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeColor = Colors.green.shade600;
    final inactiveColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeColor : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isActive ? activeColor : inactiveColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isActive ? activeColor : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.green.shade800 : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'ON' : 'OFF',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenerState = ref.watch(screenerNotifierProvider);
    final savedStrategiesAsync = ref.watch(savedStrategiesProvider);
    final results = screenerState.result?.items ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          // New Strategy — filled circle + button (top-right)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Create New Strategy',
              onPressed: _openAddStrategyModal,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _strategyNameController.clear();
          });
        },
        child: SafeScreen(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Strategy Builder Header (Below Back Button) ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strategy Builder',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan live market data with custom criteria & saved presets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Saved Strategies Section (Max 3 direct items) ───────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Saved Strategies',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // ── (+) Add Strategy Button (Beside Saved Strategies Text) ───
                          IconButton(
                            onPressed: _openAddStrategyModal,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            tooltip: 'Add Strategy',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          const Spacer(),

                          // ── See All Button with Strategy Count Pill ────────
                          savedStrategiesAsync.when(
                            data: (strategies) {
                              if (strategies.isEmpty) return const SizedBox.shrink();
                              return TextButton(
                                onPressed: () => _showAllStrategiesModal(strategies),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${strategies.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Max 3 On-Page Saved Strategy Cards ──────────────────
                      savedStrategiesAsync.when(
                        loading: () => const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (strategies) {
                          if (strategies.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.bookmark_border_rounded, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No saved strategies yet. Tap "+" above to create your first strategy.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              itemCount: strategies.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: theme.dividerColor.withValues(alpha: 0.15),
                              ),
                              itemBuilder: (context, i) {
                                return _SavedStrategyItemTile(
                                  strategy: strategies[i],
                                  isSelected: _strategyNameController.text == strategies[i].name,
                                  onTap: () {
                                    if (_strategyNameController.text == strategies[i].name) {
                                      setState(() => _strategyNameController.clear());
                                    } else {
                                      _applyPreset(strategies[i]);
                                    }
                                  },
                                  onEdit: () {
                                    _applyPreset(strategies[i]);
                                    _openAddStrategyModal();
                                  },
                                  onDelete: () => _confirmDeleteStrategy(strategies[i]),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Control Bar: Selected Strategy (Left) | Sort Dropdown (Middle) | Fixed Filter (Right) ──────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Sort button only (strategy name pill removed per UX request)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // ── Sort Dropdown Button ──────────────────────────────────────────
                              InkWell(
                                onTap: _openSortModal,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _sortBy.isNotEmpty
                                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _sortBy.isNotEmpty ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_vert_rounded,
                                        size: 15,
                                        color: _sortBy.isNotEmpty ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _sortBy.isEmpty
                                            ? 'Sort'
                                            : _getSortLabel(_sortBy, _sortOrder),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _sortBy.isNotEmpty ? colorScheme.primary : colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: _sortBy.isNotEmpty ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ── 3. FIXED Filter Button (Never moves, pinned right) ─────────────────────
                      OutlinedButton.icon(
                        onPressed: _openFiltersModal,
                        icon: Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: _currentFilter.isEmpty ? colorScheme.onSurfaceVariant : Colors.green.shade700,
                        ),
                        label: Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentFilter.isEmpty ? colorScheme.onSurfaceVariant : Colors.green.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: _currentFilter.isEmpty
                                ? colorScheme.outlineVariant
                                : Colors.green.shade600,
                            width: _currentFilter.isEmpty ? 1.0 : 1.5,
                          ),
                          backgroundColor: _currentFilter.isEmpty
                              ? Colors.transparent
                              : Colors.green.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Screener Stock Results Count Header ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Scan Results',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (screenerState.result != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${results.length} stocks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Live Scan Results List ──────────────────────────────────────
            if (screenerState.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (screenerState.isOffline)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'You are offline.\nConnect to run a new scan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (screenerState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Scan failed: ${screenerState.error}\nAdjust filters and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
              )
            else if (results.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No stocks match your conditions.\nAdjust filters to see results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = results[i];
                      return ScreenerResultCard(
                        item: item,
                        onTap: () => context.push(AppRoutes.symbolDetail(item.symbol)),
                      );
                    },
                    childCount: results.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    ),
  );
}
}

class _SavedStrategyItemTile extends StatelessWidget {
  const _SavedStrategyItemTile({
    required this.strategy,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ScreenerStrategy strategy;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String filterSummary = 'All stocks';
    if (!strategy.filters.isEmpty) {
      final parts = <String>[];
      if (strategy.filters.marketCapMin != null ||
          strategy.filters.marketCapMax != null) {
        parts.add('Market Cap');
      }
      if (strategy.filters.peRatioMin != null ||
          strategy.filters.peRatioMax != null) {
        parts.add('P/E');
      }
      if (strategy.filters.priceMin != null ||
          strategy.filters.priceMax != null) {
        parts.add('Price');
      }
      if (strategy.filters.changePercentMin != null ||
          strategy.filters.changePercentMax != null) {
        parts.add('Change %');
      }
      if (strategy.filters.exchange != null &&
          strategy.filters.exchange!.isNotEmpty) {
        parts.add(strategy.filters.exchange!);
      }
      filterSummary = parts.isEmpty ? 'Custom Criteria' : parts.join(' • ');
    }

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.auto_graph_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strategy.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filterSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                tooltip: 'Edit Strategy',
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: colorScheme.error.withValues(alpha: 0.85),
                ),
                tooltip: 'Delete Strategy',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}