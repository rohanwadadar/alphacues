import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_error.dart';
import '../../market/data/market_repository.dart';
import '../../market/data/symbol_search_provider.dart';
import '../data/alerts_providers.dart';

class AlertFormDialog extends ConsumerStatefulWidget {
  const AlertFormDialog({
    super.key,
    this.alertId,
    this.initialSymbol = '',
    this.initialCondition = 'ABOVE',
    this.initialTarget = '',
    this.initialIsActive = true,
    this.initialCooldownSeconds = '0',
    this.initialNotificationChannels = const {'IN_APP'},
  });

  final String? alertId;
  final String initialSymbol;
  final String initialCondition;
  final String initialTarget;
  final bool initialIsActive;
  final String initialCooldownSeconds;
  final Set<String> initialNotificationChannels;

  bool get isEdit => alertId != null;

  static Future<void> show(
    BuildContext context, {
    String? alertId,
    String initialSymbol = '',
    String initialCondition = 'ABOVE',
    String initialTarget = '',
    bool initialIsActive = true,
    int initialCooldownSeconds = 0,
    Set<String> initialNotificationChannels = const {'IN_APP'},
    AlertModel? alert,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertFormDialog(
        alertId: alert?.alertId ?? alertId,
        initialSymbol: alert?.symbol ?? initialSymbol,
        initialCondition: alert?.condition ?? initialCondition,
        initialTarget: alert != null ? alert.target.toString() : initialTarget,
        initialIsActive: alert?.isActive ?? initialIsActive,
        initialCooldownSeconds: alert != null
            ? alert.cooldownSeconds.toString()
            : initialCooldownSeconds.toString(),
        initialNotificationChannels: initialNotificationChannels,
      ),
    );
  }

  @override
  ConsumerState<AlertFormDialog> createState() => _AlertFormDialogState();
}

class _AlertFormDialogState extends ConsumerState<AlertFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbolController;
  late final TextEditingController _targetController;
  late final TextEditingController _cooldownController;
  final _symbolFocusNode = FocusNode();
  Timer? _debounceTimer;
  Timer? _focusHideTimer;
  List<MarketSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _selectedStockName = '';
  late String _condition;
  late bool _isActive;
  late Set<String> _notificationChannels;
  bool _isSubmitting = false;
  bool _isLoadingPrice = false;
  String? _symbolError;
  String? _targetError;
  Map<String, String> _fieldErrors = const {};

  static const _conditions = ['ABOVE', 'BELOW', 'PERCENT_CHANGE'];
  static const _channels = ['IN_APP', 'EMAIL', 'PUSH'];

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: widget.initialSymbol);
    _targetController = TextEditingController(text: widget.initialTarget);
    _cooldownController = TextEditingController(
      text: widget.initialCooldownSeconds,
    );
    _condition = widget.initialCondition;
    _isActive = widget.initialIsActive;
    _notificationChannels = {...widget.initialNotificationChannels};

    if (widget.initialSymbol.isNotEmpty) {
      _fetchAndSetMarketPrice(widget.initialSymbol);
    }

    _symbolFocusNode.addListener(() {
      if (_symbolFocusNode.hasFocus) {
        setState(() => _showSuggestions = true);
        if (_searchResults.isEmpty) {
          _onSymbolChanged(_symbolController.text);
        }
      } else {
        _focusHideTimer?.cancel();
        _focusHideTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _symbolFocusNode.dispose();
    _debounceTimer?.cancel();
    _focusHideTimer?.cancel();
    _symbolController.dispose();
    _targetController.dispose();
    _cooldownController.dispose();
    super.dispose();
  }

  void _onSymbolChanged(String value) {
    setState(() {
      _symbolError = null;
      _selectedStockName = '';
    });
    _debounceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _loadDefaultSuggestions();
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final repository = ref.read(marketRepositoryProvider);
        final results = await repository.searchSymbols(query, limit: 20);
        if (mounted) {
          setState(() {
            _searchResults = rankSearchResults(results, query);
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _loadDefaultSuggestions() async {
    try {
      setState(() => _isSearching = true);
      final repository = ref.read(marketRepositoryProvider);
      final results = await repository.searchSymbols('A', limit: 8);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectStock(MarketSearchResult stock) {
    setState(() {
      _symbolController.text = stock.symbol;
      _selectedStockName = stock.name;
      _symbolError = null;
      _showSuggestions = false;
    });
    _symbolFocusNode.unfocus();
    _fetchAndSetMarketPrice(stock.symbol);
  }

  Future<void> _fetchAndSetMarketPrice(String symbol) async {
    if (symbol.isEmpty) return;
    setState(() => _isLoadingPrice = true);
    try {
      final repository = ref.read(marketRepositoryProvider);
      final quote = await repository.getQuote(symbol);
      if (mounted) {
        setState(() {
          _targetController.text = quote.lastPrice.toStringAsFixed(2);
          _isLoadingPrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  bool _validate() {
    final symbol = _symbolController.text.trim().toUpperCase();
    final targetText = _targetController.text.trim();
    String? symbolError;
    String? targetError;

    if (symbol.isEmpty) {
      symbolError = 'Symbol is required';
    } else if (!alertSymbolPattern.hasMatch(symbol)) {
      symbolError = 'Enter a valid ticker (e.g. AAPL)';
    }

    final target = double.tryParse(targetText);
    if (targetText.isEmpty || target == null || target <= 0) {
      targetError = 'Enter a positive price target';
    }

    setState(() {
      _symbolError = symbolError;
      _targetError = targetError;
      _fieldErrors = const {};
    });

    return symbolError == null && targetError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final symbol = _symbolController.text.trim().toUpperCase();
    final target = double.parse(_targetController.text.trim());
    final cooldown = int.tryParse(_cooldownController.text.trim()) ?? 0;
    final channels = _notificationChannels.isEmpty
        ? const ['IN_APP']
        : _notificationChannels.toList();

    try {
      final repository = ref.read(alertsRepositoryProvider);
      if (widget.isEdit) {
        await repository.updateAlert(
          widget.alertId!,
          symbol: symbol,
          condition: _condition,
          target: target,
          isActive: _isActive,
          cooldownSeconds: cooldown,
          notificationChannel: channels,
        );
      } else {
        await repository.createAlert(
          symbol: symbol,
          condition: _condition,
          target: target,
          isActive: _isActive,
          cooldownSeconds: cooldown,
          notificationChannel: channels,
        );
      }

      if (!mounted) {
        return;
      }
      ref.invalidate(alertsProvider);
      ref.invalidate(alertHistoryProvider);
      Navigator.of(context).pop();
    } on AlertValidationErrorException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _fieldErrors = _mapDetailsToFieldErrors(error.details);
        _symbolError = _fieldErrors['symbol'] ?? _symbolError;
        _targetError = _fieldErrors['target'] ?? _targetError;
      });
    } on AlertRateLimitedException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF673AB7),
          content: Text(error.message),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        if (error.details != null) {
          _fieldErrors = _mapDetailsToFieldErrors(error.details!);
          _symbolError = _fieldErrors['symbol'] ?? _symbolError;
          _targetError = _fieldErrors['target'] ?? _targetError;
        }
      });
    } catch (e, st) {
        // ignore: avoid_print
        print('CREATE ALERT ERROR: $e');
        // ignore: avoid_print
        print('STACK: $st');
        if (!mounted) {
          return;
        }
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF673AB7),
            content: Text('Something went wrong: $e'),
          ),
        );
      }
  }

  Map<String, String> _mapDetailsToFieldErrors(Map<String, dynamic> details) {
    final mapped = <String, String>{};
    details.forEach((key, value) {
      if (value is String) {
        mapped[key] = value;
      } else if (value is List && value.isNotEmpty) {
        mapped[key] = value.first.toString();
      } else if (value != null) {
        mapped[key] = value.toString();
      }
    });
    return mapped;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit alert' : 'Create alert';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                // Searchable Stock Selection with Live API Search
                TextFormField(
                  controller: _symbolController,
                  focusNode: _symbolFocusNode,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: _onSymbolChanged,
                  decoration: InputDecoration(
                    labelText: 'Select Stock',
                    hintText: 'Search all stocks (e.g. AAPL, NVDA)...',
                    errorText: _symbolError,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_symbolController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _symbolController.clear();
                                  _onSymbolChanged('');
                                },
                              )
                            : null),
                    helperText: _selectedStockName.isNotEmpty
                        ? _selectedStockName
                        : 'Search any stock in the market',
                  ),
                ),
                if (_showSuggestions && (_searchResults.isNotEmpty || _isSearching)) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final isSelected = item.symbol.toUpperCase() ==
                              _symbolController.text.trim().toUpperCase();
                          return InkWell(
                            onTap: () => _selectStock(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.primaryContainer,
                                    child: Text(
                                      item.symbol.isNotEmpty ? item.symbol[0] : '?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.symbol,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (item.name.isNotEmpty)
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (item.exchange.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        item.exchange,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: _conditions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _condition = value);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _targetController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Target Price (\$) ',
                    errorText: _targetError,
                    suffixIcon: _isLoadingPrice
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    helperText: 'Auto-filled with current market price',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _cooldownController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cooldown (seconds)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Notification channels',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _channels.map((channel) {
                    final selected = _notificationChannels.contains(channel);
                    return FilterChip(
                      label: Text(channel),
                      selected: selected,
                      onSelected: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  _notificationChannels.add(channel);
                                } else {
                                  _notificationChannels.remove(channel);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                if (_fieldErrors.isNotEmpty &&
                    _fieldErrors.keys.any(
                      (key) => key != 'symbol' && key != 'target',
                    )) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _fieldErrors.values.first,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
