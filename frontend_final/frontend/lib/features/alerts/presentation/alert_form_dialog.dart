import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_error.dart';
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
                TextFormField(
                  controller: _symbolController,
                  enabled: !_isSubmitting,
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
                    errorText: _symbolError,
                  ),
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
                    labelText: 'Target',
                    errorText: _targetError,
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
