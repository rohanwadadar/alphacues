import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // ── Warning Confirmation Dialog ──────────────────────────────────────
    final warningConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Warning: Confirm Action'),
          ],
        ),
        content: Text(
          widget.mode == WatchlistFormMode.create
              ? 'Warning: Are you sure you want to create a new watchlist named "$name"?'
              : 'Warning: Are you sure you want to rename this watchlist to "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (warningConfirmed != true || !mounted) return;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Watchlist Name',
              hintText: 'e.g. High Growth Tech',
              errorText: inlineError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.mode == WatchlistFormMode.create ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
