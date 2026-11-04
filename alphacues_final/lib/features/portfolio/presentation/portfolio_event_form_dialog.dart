import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/trade_animation_overlay.dart';
import '../../market/data/market_repository.dart';
import '../../market/data/symbol_search_provider.dart';
import '../data/portfolio_providers.dart';

class PortfolioEventFormDialog extends ConsumerStatefulWidget {
  const PortfolioEventFormDialog({super.key, this.event});

  final PortfolioEvent? event;

  bool get isEdit => event != null;

  static Future<void> show(BuildContext context, {PortfolioEvent? event}) {
    return showDialog<void>(
      context: context,
      builder: (context) => PortfolioEventFormDialog(event: event),
    );
  }

  @override
  ConsumerState<PortfolioEventFormDialog> createState() =>
      _PortfolioEventFormDialogState();
}

class _PortfolioEventFormDialogState
    extends ConsumerState<PortfolioEventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbolController;
  late final TextEditingController _volumeController;
  late final TextEditingController _priceController;
  late String _action;
  late DateTime _selectedDate;
  late final String _idempotencyKey;
  bool _isLoadingPrice = false;

  static const _actions = ['BUY', 'SELL'];

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _symbolController = TextEditingController(text: event?.symbol ?? '');
    _volumeController = TextEditingController(
      text: event?.volume.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: event?.price.toString() ?? '',
    );
    _action = event?.action ?? 'BUY';
    _selectedDate = DateTime.now();
    _idempotencyKey = generatePortfolioIdempotencyKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(portfolioEventFormProvider.notifier).reset();
        if (event == null && _symbolController.text.isNotEmpty) {
          _fetchAndSetMarketPrice(_symbolController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetMarketPrice(String symbol) async {
    final clean = symbol.trim().toUpperCase();
    if (clean.isEmpty) return;
    setState(() => _isLoadingPrice = true);
    try {
      final repository = ref.read(marketRepositoryProvider);
      final quote = await repository.getQuote(clean);
      if (mounted && quote.lastPrice > 0) {
        setState(() {
          _priceController.text = quote.lastPrice.toStringAsFixed(2);
          _isLoadingPrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  String _formatUtcTimestamp(DateTime local) {
    return formatPortfolioEventTimestamp(local);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
        _selectedDate.second,
        _selectedDate.millisecond,
        _selectedDate.microsecond,
      );
    });
  }

  Future<void> _submit() async {
    final formNotifier = ref.read(portfolioEventFormProvider.notifier);
    if (!formNotifier.validate(
      symbol: _symbolController.text,
      action: _action,
      volumeText: _volumeController.text,
      priceText: _priceController.text,
      date: _selectedDate,
    )) {
      return;
    }

    final symbol = _symbolController.text.trim().toUpperCase();
    final volume = int.parse(_volumeController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final timeStamp = _formatUtcTimestamp(_selectedDate);

    try {
      if (widget.isEdit) {
        await formNotifier.submitUpdate(
          eventId: widget.event!.eventId,
          symbol: symbol,
          action: _action,
          volume: volume,
          price: price,
          timeStamp: timeStamp,
        );
      } else {
        await formNotifier.submitCreate(
          symbol: symbol,
          action: _action,
          volume: volume,
          price: price,
          timeStamp: timeStamp,
          idempotencyKey: _idempotencyKey,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      TradeAnimationOverlay.show(
        context,
        type: _action == 'BUY' ? TradeType.add : TradeType.remove,
        symbol: symbol,
      );
    } on PortfolioValidationErrorException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF673AB7),
        content: Text(error.message),
      ));
    } on PortfolioRateLimitedException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF673AB7),
        content: Text(error.message),
      ));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF673AB7),
        content: Text(portfolioErrorMessage(error)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(portfolioEventFormProvider);
    final title = widget.isEdit ? 'Edit Watchlist Entry' : 'Add to Watchlist';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isEdit) ...[
                  Text(
                    'You can edit or remove watchlist activity entries.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Autocomplete<MarketSearchResult>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<MarketSearchResult>.empty();
                    }
                    final query = textEditingValue.text.trim();
                    try {
                      return await ref.read(symbolSearchProvider(query).future);
                    } catch (_) {
                      return const Iterable<MarketSearchResult>.empty();
                    }
                  },
                  displayStringForOption: (option) => option.symbol,
                  onSelected: (MarketSearchResult selection) {
                    _symbolController.text = selection.symbol;
                    _fetchAndSetMarketPrice(selection.symbol);
                  },
                  fieldViewBuilder:
                      (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                    if (fieldTextEditingController.text.isEmpty && _symbolController.text.isNotEmpty) {
                      fieldTextEditingController.text = _symbolController.text;
                    }
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: focusNode,
                      enabled: !formState.isSubmitting,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          ),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Symbol',
                        errorText: formState.symbolError,
                        hintText: 'e.g. AAPL',
                      ),
                      onChanged: (val) {
                        _symbolController.text = val;
                      },
                      onFieldSubmitted: (_) {
                        _symbolController.text = fieldTextEditingController.text;
                        _fetchAndSetMarketPrice(fieldTextEditingController.text);
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: 250,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(option.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Text(option.exchange, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Action'),
                  child: SegmentedButton<String>(
                    segments: _actions
                        .map(
                          (value) => ButtonSegment(
                            value: value,
                            label: Text(value == 'BUY' ? 'Add to Watchlist' : 'Remove from Watchlist'),
                          ),
                        )
                        .toList(),
                    selected: {_action},
                    onSelectionChanged: formState.isSubmitting
                        ? null
                        : (selection) {
                            setState(() => _action = selection.first);
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _volumeController,
                  enabled: !formState.isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    errorText: formState.volumeError,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _priceController,
                  enabled: !formState.isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Price per share',
                    errorText: formState.priceError,
                    suffixIcon: _isLoadingPrice
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    errorText: formState.dateError,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_selectedDate),
                        ),
                      ),
                      TextButton(
                        onPressed: formState.isSubmitting ? null : _pickDate,
                        child: const Text('Pick date'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: formState.isSubmitting ? null : _submit,
          child: formState.isSubmitting
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEdit ? 'Save' : 'Add Position'),
        ),
      ],
    );
  }
}
