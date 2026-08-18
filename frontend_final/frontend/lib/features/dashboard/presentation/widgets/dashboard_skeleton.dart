import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/loading_skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        _SectionSkeleton(titleWidth: 120, rowCount: 5),
        SizedBox(height: AppSpacing.lg),
        _SectionSkeleton(titleWidth: 160, rowCount: 3),
        SizedBox(height: AppSpacing.lg),
        _ChartPlaceholderSkeleton(),
        SizedBox(height: AppSpacing.lg),
        _SectionSkeleton(titleWidth: 140, rowCount: 4),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({
    required this.titleWidth,
    required this.rowCount,
  });

  final double titleWidth;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(width: titleWidth, height: 20),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          rowCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: const Row(
              children: [
                LoadingSkeleton(width: 72, height: 18),
                Spacer(),
                LoadingSkeleton(width: 64, height: 18),
                SizedBox(width: AppSpacing.sm),
                LoadingSkeleton(width: 56, height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPlaceholderSkeleton extends StatelessWidget {
  const _ChartPlaceholderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(width: 96, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 160),
      ],
    );
  }
}
