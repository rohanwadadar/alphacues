import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../data/watchlist_providers.dart';

class AddToWatchlistDialog extends ConsumerStatefulWidget {
  const AddToWatchlistDialog({
    super.key,
    required this.symbol,
    this.parentContext,
  });

  final String symbol;
  final BuildContext? parentContext;

  static Future<void> show(BuildContext context, String symbol) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AddToWatchlistDialog(
        symbol: symbol,
        parentContext: context,
      ),
    );
  }

  @override
  ConsumerState<AddToWatchlistDialog> createState() => _AddToWatchlistDialogState();
}

class _AddToWatchlistDialogState extends ConsumerState<AddToWatchlistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedWatchlistId;

  @override
  void initState() {
    super.initState();
    // Pre-fill date with today's date
    _dateController.text = DateTime.now().toString().split(' ')[0];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final watchlists = ref.read(watchlistsProvider).valueOrNull;
      if (watchlists != null && watchlists.isNotEmpty) {
        setState(() {
          _selectedWatchlistId = watchlists.first.watchlistId;
        });
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedWatchlistId == null) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    final navContext = widget.parentContext ?? context;
    final scaffoldMessenger = ScaffoldMessenger.of(navContext);
    final navigator = Navigator.of(context);
    
    try {
      await ref.read(watchlistRepositoryProvider).addSymbol(
        _selectedWatchlistId!,
        widget.symbol,
        quantity: quantity,
      );
      
      ref.invalidate(watchlistDetailProvider(_selectedWatchlistId!));
      ref.invalidate(watchlistsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
      
      if (mounted) {
        final targetWatchlistId = _selectedWatchlistId!;
        final watchlists = ref.read(watchlistsProvider).valueOrNull ?? [];
        final targetWatchlist = watchlists
            .where((w) => w.watchlistId == targetWatchlistId)
            .firstOrNull;
        final targetName = targetWatchlist?.name ?? 'Watchlist';
        final symbol = widget.symbol;

        navigator.pop();

        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF673AB7),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$symbol added to $targetName!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Edit',
              textColor: Colors.amberAccent,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                if (navContext.mounted) {
                  navContext.push(
                    '${AppRoutes.watchlistDetail(targetWatchlistId)}?editSymbol=$symbol',
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add to watchlist: $e'),
            backgroundColor: Colors.purple.shade900,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistsState = ref.watch(watchlistsProvider);

    return AlertDialog(
      title: Text('Add ${widget.symbol} to Watchlist'),
      content: watchlistsState.when(
        data: (watchlists) {
          if (watchlists.isEmpty) {
            return const Text('No watchlists available. Please create one first.');
          }
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedWatchlistId,
                  decoration: const InputDecoration(
                    labelText: 'Select Watchlist',
                    border: OutlineInputBorder(),
                  ),
                  items: watchlists.map((w) {
                    return DropdownMenuItem(
                      value: w.watchlistId,
                      child: Text(w.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedWatchlistId = val;
                    });
                  },
                  validator: (val) => val == null ? 'Please select a watchlist' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'No. of Stocks',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter quantity';
                    if (double.tryParse(val) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date Captured',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
          width: 50, height: 50, child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Text('Error loading watchlists: $e'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: watchlistsState.hasValue && watchlistsState.value!.isNotEmpty ? _submit : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
