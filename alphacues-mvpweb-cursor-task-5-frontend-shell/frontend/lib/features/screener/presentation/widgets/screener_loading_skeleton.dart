import 'package:flutter/material.dart';

/// Skeleton placeholder shown during the Loading state.
/// Renders a muted filter bar + table rows to prevent blank-screen flash.
class ScreenerLoadingSkeleton extends StatelessWidget {
  const ScreenerLoadingSkeleton({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter placeholder bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _SkeletonBox(width: 120, height: 36, radius: 8),
              const SizedBox(width: 8),
              _SkeletonBox(width: 80, height: 36, radius: 8),
              const Spacer(),
              _SkeletonBox(width: 100, height: 36, radius: 8),
            ],
          ),
        ),
        const Divider(height: 1),
        // Table skeleton rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: rowCount,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => const _SkeletonResultRow(),
          ),
        ),
      ],
    );
  }
}

class _SkeletonResultRow extends StatelessWidget {
  const _SkeletonResultRow();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonBox(width: 60, height: 18),
                const Spacer(),
                _SkeletonBox(width: 70, height: 18),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SkeletonBox(width: 140, height: 14),
                const Spacer(),
                _SkeletonBox(width: 55, height: 14),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _SkeletonBox(width: 90, height: 12),
                const SizedBox(width: 16),
                _SkeletonBox(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 4});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
