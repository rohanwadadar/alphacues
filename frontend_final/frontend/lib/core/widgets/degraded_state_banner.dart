import 'package:flutter/material.dart';

enum DegradedScreen {
  dashboard,
  watchlists,
  watchlistDetail,
  symbolDetail,
  alerts,
  portfolio,
  screener,
}

class DegradedStateBanner extends StatelessWidget {
  final DegradedScreen screen;
  final String? lastUpdatedTimestamp;
  final VoidCallback? onRetry;

  const DegradedStateBanner({
    super.key,
    required this.screen,
    this.lastUpdatedTimestamp,
    this.onRetry,
  });

  String _getDegradedMessage() {
    final timestampText = lastUpdatedTimestamp != null && lastUpdatedTimestamp!.isNotEmpty
        ? ' from $lastUpdatedTimestamp'
        : '';

    switch (screen) {
      case DegradedScreen.dashboard:
        return 'Showing cached market snapshot$timestampText. Reconnecting to live data stream...';
      case DegradedScreen.watchlists:
        return 'Viewing saved watchlists in offline mode. Item modifications are temporarily disabled.';
      case DegradedScreen.watchlistDetail:
        return 'Prices updated$timestampText (Stale Data). Live price streaming reconnecting...';
      case DegradedScreen.symbolDetail:
        return 'Last known quote$timestampText. Live chart updates paused until reconnected.';
      case DegradedScreen.alerts:
        return 'Alert engine connection paused. Push notifications will trigger when reconnected.';
      case DegradedScreen.portfolio:
        return 'Holdings evaluated using last known closing prices as of $lastUpdatedTimestamp.';
      case DegradedScreen.screener:
        return 'Showing saved preset filters. Fresh market scans require an active connection.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _getDegradedMessage();

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Offline and degraded state alert: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.amber.shade300, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 20.0,
              color: Colors.amber.shade900,
              semanticLabel: 'Offline indicator',
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8.0),
              Semantics(
                button: true,
                label: 'Retry connection button',
                hint: 'Tap to attempt reconnecting to live network data',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  child: InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(4.0),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          'Retry',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ],
        ),
      ),
    );
  }
}

class StaleDataBadge extends StatelessWidget {
  final String timestamp;

  const StaleDataBadge({
    super.key,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Stale price badge, last updated at $timestamp',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 14.0, color: Colors.orange.shade900),
            const SizedBox(width: 4.0),
            Text(
              'Stale Data ($timestamp)',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
