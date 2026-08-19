import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../settings/data/settings_provider.dart';

class OnboardingGuideModal extends ConsumerStatefulWidget {
  const OnboardingGuideModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OnboardingGuideModal(),
    );
  }

  @override
  ConsumerState<OnboardingGuideModal> createState() => _OnboardingGuideModalState();
}

class _OnboardingGuideModalState extends ConsumerState<OnboardingGuideModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = const [
    {
      'title': 'Welcome to AlphaCues',
      'subtitle': 'Your modern trading and market intelligence hub',
      'description': 'Track real-time stock prices, monitor your portfolio value, and discover market-moving cues instantly.',
      'icon': Icons.trending_up_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA855F7)],
    },
    {
      'title': '20+ Year Graph History',
      'subtitle': 'Split-normalized historical charting',
      'description': 'Scrub through historical price data from 2004 to today. Seamlessly toggle between smooth Line curves and Candlesticks.',
      'icon': Icons.show_chart_rounded,
      'gradient': [Color(0xFF2563EB), Color(0xFF60A5FA)],
    },
    {
      'title': 'Market Sector Treemap',
      'subtitle': 'Visual S&P 500 Heatmap',
      'description': 'See how Tech, Healthcare, Financials, and Energy perform at a glance. Tap any sector to inspect its top constituent stocks.',
      'icon': Icons.grid_view_rounded,
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
    },
    {
      'title': 'Social Copy Trading',
      'subtitle': 'Follow verified top traders',
      'description': 'Explore community leaderboards, view win-rate metrics, and replicate successful portfolio strategies with virtual funds.',
      'icon': Icons.workspace_premium_rounded,
      'gradient': [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    },
    {
      'title': 'Real-Time Price Alerts',
      'subtitle': 'Never miss a breakout or dip',
      'description': 'Set custom target price triggers on any stock. Receive push notifications when target conditions break above or below.',
      'icon': Icons.add_alert_rounded,
      'gradient': [Color(0xFFEC4899), Color(0xFFF472B6)],
    },
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(settingsProvider.notifier).completeOnboarding();
      Navigator.pop(context);
    }
  }

  void _skip() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Header handle & Skip button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${_currentPage + 1} of ${_steps.length}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: _skip,
                child: const Text('Skip Manual'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // PageView Slides
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final List<Color> gradient = step['gradient'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large Icon Badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      Text(
                        step['title'] as String,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        step['subtitle'] as String,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      Text(
                        step['description'] as String,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentPage == _steps.length - 1 ? 'Get Started' : 'Next Feature',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
