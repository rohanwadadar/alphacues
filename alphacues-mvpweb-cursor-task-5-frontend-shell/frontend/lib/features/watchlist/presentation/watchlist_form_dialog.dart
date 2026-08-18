import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/watchlist_providers.dart';

enum WatchlistFormMode { create, rename }

class WatchlistFormDialog extends ConsumerStatefulWidget {
  const WatchlistFormDialog({
    super.key,
    required this.mode,
    this.watchlistId,
    this.initialName = '',
  });

  final WatchlistFormMode mode;
  final String? watchlistId;
  final String initialName;

  static Future<void> show(
    BuildContext context, {
    required WatchlistFormMode mode,
    String? watchlistId,
    String initialName = '',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => WatchlistFormDialog(
        mode: mode,
        watchlistId: watchlistId,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<WatchlistFormDialog> createState() =>
      _WatchlistFormDialogState();
}

class _WatchlistFormDialogState extends ConsumerState<WatchlistFormDialog> {
  late final TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    ref.read(watchlistFormProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _validationError = 'Name is required.');
      return;
    }
    setState(() => _validationError = null);

    final notifier = ref.read(watchlistFormProvider.notifier);
    if (widget.mode == WatchlistFormMode.create) {
      await notifier.create(name);
    } else {
      await notifier.rename(
        watchlistId: widget.watchlistId!,
        name: name,
      );
    }

    if (!mounted) {
      return;
    }

    final formState = ref.read(watchlistFormProvider);
    if (formState.hasError) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(watchlistFormProvider);
    final notifier = ref.read(watchlistFormProvider.notifier);
    final inlineError = _validationError ?? notifier.inlineError;
    final isLoading = formState.isLoading;
    final title = widget.mode == WatchlistFormMode.create
        ? 'Create watchlist'
        : 'Rename watchlist';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: inlineError,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.mode == WatchlistFormMode.create ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
