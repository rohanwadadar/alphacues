import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_error.dart';
import '../../market/data/market_repository.dart';
import '../../watchlist/data/watchlist_providers.dart';
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
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _targetController.dispose();
    _cooldownController.dispose();
    super.dispose();
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
        SnackBar(content: Text(error.message)),
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
          SnackBar(content: Text('Something went wrong: $e')),
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
    final watchlistsAsync = ref.watch(watchlistsProvider);

    final Map<String, String> stockOptions = {
      'AAPL': 'Apple Inc.',
      'GOOGL': 'Alphabet Inc.',
      'MSFT': 'Microsoft Corp.',
      'TSLA': 'Tesla Inc.',
      'AMZN': 'Amazon.com Inc.',
      'NVDA': 'NVIDIA Corp.',
      'META': 'Meta Platforms',
    };

    if (watchlistsAsync.hasValue) {
      for (final w in watchlistsAsync.requireValue) {
        final detailAsync = ref.watch(watchlistDetailProvider(w.watchlistId));
        if (detailAsync case AsyncData(:final value)) {
          for (final item in value.items) {
            final sym = item.symbol.toUpperCase();
            if (!stockOptions.containsKey(sym)) {
              stockOptions[sym] = 'Tracked in ${w.name}';
            }
          }
        }
      }
    }

    final currentSymbol = _symbolController.text.trim().toUpperCase();

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
                // Automated Stock Selection Dropdown
                DropdownButtonFormField<String>(
                  value: stockOptions.containsKey(currentSymbol) ? currentSymbol : null,
                  decoration: InputDecoration(
                    labelText: 'Select Stock',
                    errorText: _symbolError,
                    prefixIcon: const Icon(Icons.show_chart),
                    helperText: 'Select a stock from your watchlist',
                  ),
                  items: stockOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              entry.key[0],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key} - ${entry.value}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (selectedSymbol) {
                          if (selectedSymbol != null) {
                            setState(() {
                              _symbolController.text = selectedSymbol;
                              _symbolError = null;
                            });
                            _fetchAndSetMarketPrice(selectedSymbol);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _condition,
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
