import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../realtime/socket_client.dart';

/// Non-blocking banner shown while live prices are reconnecting or refreshing.
class StaleBanner extends ConsumerWidget {
  const StaleBanner({
    super.key,
    this.message,
    this.visible,
  });

  /// Custom banner text. Defaults to [reconnectingText].
  final String? message;

  /// When set, overrides socket-based visibility.
  final bool? visible;

  static const reconnectingText = 'Live prices reconnecting…';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(socketConnectionStateProvider);
    final visible = this.visible ?? bannerState.isVisible;
    final text = message ?? reconnectingText;

    final background = bannerState.isRed
        ? AppColors.negative
        : AppColors.warning;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: visible ? 36 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: visible
          ? Material(
              color: background,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
