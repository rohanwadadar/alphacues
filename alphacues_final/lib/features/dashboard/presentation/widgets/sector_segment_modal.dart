import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../watchlist/presentation/add_to_watchlist_dialog.dart';
import 'market_treemap_widget.dart';

class SectorSegmentModal extends StatefulWidget {
  const SectorSegmentModal({
    super.key,
    required this.sector,
  });

  final MarketSector sector;

  static void show(BuildContext context, MarketSector sector) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SectorSegmentModal(sector: sector),
    );
  }

  @override
  State<SectorSegmentModal> createState() => _SectorSegmentModalState();
}

class _SectorSegmentModalState extends State<SectorSegmentModal> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSegmentFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IndustrySegment> get _filteredSegments {
    final query = _searchQuery;
    final filter = _selectedSegmentFilter;

    return widget.sector.segments.map((segment) {
      if (filter != 'ALL' && segment.name != filter) {
        return null;
      }

      final filteredStocks = segment.stocks.where((stock) {
        if (query.isEmpty) return true;
        return stock.symbol.toLowerCase().contains(query) ||
            stock.name.toLowerCase().contains(query);
      }).toList();

      if (filteredStocks.isEmpty) return null;
      return IndustrySegment(name: segment.name, stocks: filteredStocks);
    }).whereType<IndustrySegment>().toList();
  }

  int get _totalStockCount {
    int count = 0;
    for (final seg in widget.sector.segments) {
      count += seg.stocks.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = widget.sector.changePercent >= 0;
    final sectorColor = isPositive ? AppColors.positive : AppColors.negative;

    final filteredSegments = _filteredSegments;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── 1. DRAG HANDLE & HEADER ─────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sectorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sectorColor.withValues(alpha: 0.4)),
                      ),
                      child: Icon(widget.sector.icon, color: sectorColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${widget.sector.name} Sector',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sectorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${isPositive ? '+' : ''}${widget.sector.changePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: sectorColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S&P 500 Industry Segments (${widget.sector.segments.length} Segments • $_totalStockCount Stocks)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 2. SEARCH BAR ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stocks in ${widget.sector.name}...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── 3. SEGMENT FILTER CHIPS (HORIZONTAL SCROLL) ───────────────
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    _buildFilterChip(
                      label: 'All Segments ($_totalStockCount)',
                      isSelected: _selectedSegmentFilter == 'ALL',
                      onSelected: () => setState(() => _selectedSegmentFilter = 'ALL'),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    ...widget.sector.segments.map((segment) {
                      final isSelected = _selectedSegmentFilter == segment.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: '${segment.name} (${segment.stocks.length})',
                          isSelected: isSelected,
                          onSelected: () => setState(() => _selectedSegmentFilter = segment.name),
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 24),

              // ── 4. SEGREGATED STOCKS BY INDUSTRY SEGMENTS ───────────────
              Expanded(
                child: filteredSegments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'No stocks found matching "$_searchQuery"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: filteredSegments.length,
                        itemBuilder: (context, segmentIndex) {
                          final segment = filteredSegments[segmentIndex];

                          // Calculate average change for this segment
                          final double avgChange = segment.stocks.isEmpty
                              ? 0.0
                              : segment.stocks.fold<double>(
                                      0.0, (sum, item) => sum + item.changePercent) /
                                  segment.stocks.length;
                          final bool segPositive = avgChange >= 0;
                          final Color segColor =
                              segPositive ? AppColors.positive : AppColors.negative;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── SEGMENT HEADER CARD ──────────────────────
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 12),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.widgets_rounded,
                                            size: 16, color: colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          segment.name,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: segColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Segment Avg ${segPositive ? '+' : ''}${avgChange.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: segColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── SEGREGATED STOCK ITEMS ──────────────────
                              ...segment.stocks.map((stock) {
                                final stockPositive = stock.changePercent >= 0;
                                final stockColor =
                                    stockPositive ? AppColors.positive : AppColors.negative;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      context.push(AppRoutes.symbolDetail(stock.symbol));
                                    },
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          colorScheme.primary.withValues(alpha: 0.15),
                                      child: Text(
                                        stock.symbol[0],
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          stock.symbol,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'P/E ${stock.peRatio}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${stock.name} • Vol ${stock.volume}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$${stock.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: stockColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${stockPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                                style: TextStyle(
                                                  color: stockColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.bookmark_add_outlined,
                                            size: 20,
                                          ),
                                          tooltip: 'Add to Wishlist',
                                          onPressed: () =>
                                              AddToWatchlistDialog.show(
                                            context,
                                            stock.symbol,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            color: colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primary,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      showCheckmark: false,
    );
  }
}
