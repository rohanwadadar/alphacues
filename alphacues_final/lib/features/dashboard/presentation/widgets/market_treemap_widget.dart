import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import 'sector_segment_modal.dart';

class SegmentStock {
  const SegmentStock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.peRatio,
  });

  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final String volume;
  final double peRatio;
}

class IndustrySegment {
  const IndustrySegment({
    required this.name,
    required this.stocks,
  });

  final String name;
  final List<SegmentStock> stocks;
}

class MarketSector {
  const MarketSector({
    required this.name,
    required this.changePercent,
    required this.weight,
    required this.topSymbols,
    required this.icon,
    required this.segments,
  });

  final String name;
  final double changePercent;
  final double weight;
  final List<String> topSymbols;
  final IconData icon;
  final List<IndustrySegment> segments;
}

const kMarketSectors = [
  // 1. TECHNOLOGY
  MarketSector(
    name: 'Technology',
    changePercent: 2.45,
    weight: 0.30,
    topSymbols: ['AAPL', 'NVDA', 'MSFT', 'AVGO'],
    icon: Icons.memory_rounded,
    segments: [
      IndustrySegment(
        name: 'Semiconductors',
        stocks: [
          SegmentStock(symbol: 'NVDA', name: 'NVIDIA Corporation', price: 124.50, changePercent: 4.85, volume: '48.2M', peRatio: 42.1),
          SegmentStock(symbol: 'AVGO', name: 'Broadcom Inc', price: 162.10, changePercent: 3.12, volume: '12.4M', peRatio: 31.5),
          SegmentStock(symbol: 'AMD', name: 'Advanced Micro Devices', price: 148.20, changePercent: 2.90, volume: '28.6M', peRatio: 38.4),
          SegmentStock(symbol: 'TSM', name: 'Taiwan Semiconductor', price: 172.40, changePercent: 3.52, volume: '18.1M', peRatio: 26.2),
          SegmentStock(symbol: 'QCOM', name: 'Qualcomm Inc', price: 168.90, changePercent: 1.80, volume: '9.4M', peRatio: 21.8),
        ],
      ),
      IndustrySegment(
        name: 'Software & Cloud',
        stocks: [
          SegmentStock(symbol: 'MSFT', name: 'Microsoft Corporation', price: 418.50, changePercent: 1.65, volume: '22.4M', peRatio: 34.8),
          SegmentStock(symbol: 'ORCL', name: 'Oracle Corporation', price: 138.20, changePercent: 2.40, volume: '14.8M', peRatio: 32.1),
          SegmentStock(symbol: 'CRM', name: 'Salesforce Inc', price: 252.00, changePercent: 1.15, volume: '8.2M', peRatio: 41.2),
          SegmentStock(symbol: 'ADBE', name: 'Adobe Inc', price: 512.40, changePercent: 0.95, volume: '4.5M', peRatio: 44.6),
          SegmentStock(symbol: 'PANW', name: 'Palo Alto Networks', price: 342.10, changePercent: 3.25, volume: '6.1M', peRatio: 52.8),
        ],
      ),
      IndustrySegment(
        name: 'Consumer Electronics & Hardware',
        stocks: [
          SegmentStock(symbol: 'AAPL', name: 'Apple Inc', price: 226.30, changePercent: 1.42, volume: '52.1M', peRatio: 32.4),
          SegmentStock(symbol: 'CSCO', name: 'Cisco Systems', price: 48.20, changePercent: 0.55, volume: '16.8M', peRatio: 15.2),
          SegmentStock(symbol: 'DELL', name: 'Dell Technologies', price: 115.80, changePercent: 2.10, volume: '11.3M', peRatio: 18.6),
          SegmentStock(symbol: 'HPQ', name: 'HP Inc', price: 35.40, changePercent: 0.82, volume: '7.4M', peRatio: 12.1),
        ],
      ),
    ],
  ),

  // 2. COMMUNICATION
  MarketSector(
    name: 'Communication',
    changePercent: 1.82,
    weight: 0.16,
    topSymbols: ['GOOGL', 'META', 'NFLX'],
    icon: Icons.cell_tower_rounded,
    segments: [
      IndustrySegment(
        name: 'Search & Ad Tech',
        stocks: [
          SegmentStock(symbol: 'GOOGL', name: 'Alphabet Inc', price: 176.40, changePercent: 2.15, volume: '26.4M', peRatio: 24.5),
        ],
      ),
      IndustrySegment(
        name: 'Social Media & Platforms',
        stocks: [
          SegmentStock(symbol: 'META', name: 'Meta Platforms Inc', price: 514.20, changePercent: 3.20, volume: '19.8M', peRatio: 26.8),
          SegmentStock(symbol: 'SNAP', name: 'Snap Inc', price: 11.40, changePercent: -1.25, volume: '14.2M', peRatio: 18.4),
          SegmentStock(symbol: 'PINS', name: 'Pinterest Inc', price: 32.80, changePercent: 0.85, volume: '6.8M', peRatio: 22.1),
        ],
      ),
      IndustrySegment(
        name: 'Streaming & Entertainment',
        stocks: [
          SegmentStock(symbol: 'NFLX', name: 'Netflix Inc', price: 682.50, changePercent: 2.80, volume: '7.6M', peRatio: 42.5),
          SegmentStock(symbol: 'DIS', name: 'The Walt Disney Co', price: 96.40, changePercent: 0.65, volume: '11.2M', peRatio: 38.2),
          SegmentStock(symbol: 'CMCSA', name: 'Comcast Corp', price: 39.80, changePercent: -0.45, volume: '18.5M', peRatio: 11.4),
        ],
      ),
      IndustrySegment(
        name: 'Telecom Networks',
        stocks: [
          SegmentStock(symbol: 'TMUS', name: 'T-Mobile US Inc', price: 178.50, changePercent: 1.10, volume: '5.2M', peRatio: 23.4),
          SegmentStock(symbol: 'VZ', name: 'Verizon Communications', price: 41.20, changePercent: 0.35, volume: '24.1M', peRatio: 9.8),
          SegmentStock(symbol: 'T', name: 'AT&T Inc', price: 19.40, changePercent: 0.52, volume: '31.8M', peRatio: 8.4),
        ],
      ),
    ],
  ),

  // 3. CONSUMER
  MarketSector(
    name: 'Consumer',
    changePercent: 1.15,
    weight: 0.18,
    topSymbols: ['AMZN', 'TSLA', 'HD'],
    icon: Icons.shopping_bag_outlined,
    segments: [
      IndustrySegment(
        name: 'E-Commerce & Digital Retail',
        stocks: [
          SegmentStock(symbol: 'AMZN', name: 'Amazon.com Inc', price: 186.20, changePercent: 2.42, volume: '41.5M', peRatio: 42.1),
          SegmentStock(symbol: 'EBAY', name: 'eBay Inc', price: 54.10, changePercent: 0.75, volume: '6.2M', peRatio: 14.8),
          SegmentStock(symbol: 'BABA', name: 'Alibaba Group', price: 82.50, changePercent: 1.92, volume: '18.4M', peRatio: 16.2),
        ],
      ),
      IndustrySegment(
        name: 'Automotive & EV',
        stocks: [
          SegmentStock(symbol: 'TSLA', name: 'Tesla Inc', price: 214.80, changePercent: 3.85, volume: '68.2M', peRatio: 58.4),
          SegmentStock(symbol: 'F', name: 'Ford Motor Co', price: 10.80, changePercent: -0.82, volume: '42.1M', peRatio: 7.2),
          SegmentStock(symbol: 'GM', name: 'General Motors Co', price: 46.20, changePercent: 1.25, volume: '15.6M', peRatio: 5.8),
        ],
      ),
      IndustrySegment(
        name: 'Retail & Home',
        stocks: [
          SegmentStock(symbol: 'HD', name: 'Home Depot Inc', price: 368.50, changePercent: 0.92, volume: '6.4M', peRatio: 24.1),
          SegmentStock(symbol: 'LOW', name: "Lowe's Companies", price: 242.10, changePercent: 0.68, volume: '4.2M', peRatio: 19.8),
          SegmentStock(symbol: 'NKE', name: 'NIKE Inc', price: 82.40, changePercent: -1.45, volume: '14.5M', peRatio: 28.2),
          SegmentStock(symbol: 'SBUX', name: 'Starbucks Corp', price: 94.80, changePercent: 1.52, volume: '11.8M', peRatio: 25.6),
        ],
      ),
    ],
  ),

  // 4. FINANCIALS
  MarketSector(
    name: 'Financials',
    changePercent: -0.45,
    weight: 0.14,
    topSymbols: ['JPM', 'BAC', 'V', 'MA'],
    icon: Icons.account_balance_rounded,
    segments: [
      IndustrySegment(
        name: 'Investment & Commercial Banking',
        stocks: [
          SegmentStock(symbol: 'JPM', name: 'JPMorgan Chase & Co', price: 218.40, changePercent: -0.35, volume: '14.2M', peRatio: 12.1),
          SegmentStock(symbol: 'BAC', name: 'Bank of America Corp', price: 39.20, changePercent: -0.85, volume: '38.5M', peRatio: 11.2),
          SegmentStock(symbol: 'GS', name: 'Goldman Sachs Group', price: 482.10, changePercent: 0.42, volume: '3.8M', peRatio: 14.6),
          SegmentStock(symbol: 'MS', name: 'Morgan Stanley', price: 102.50, changePercent: -0.22, volume: '7.4M', peRatio: 15.8),
          SegmentStock(symbol: 'C', name: 'Citigroup Inc', price: 61.40, changePercent: -0.65, volume: '16.8M', peRatio: 10.4),
        ],
      ),
      IndustrySegment(
        name: 'Payments & Financial Tech',
        stocks: [
          SegmentStock(symbol: 'V', name: 'Visa Inc', price: 268.40, changePercent: 0.25, volume: '8.4M', peRatio: 28.5),
          SegmentStock(symbol: 'MA', name: 'Mastercard Inc', price: 458.20, changePercent: -0.15, volume: '4.6M', peRatio: 32.1),
          SegmentStock(symbol: 'PYPL', name: 'PayPal Holdings', price: 68.50, changePercent: 1.45, volume: '12.8M', peRatio: 16.5),
          SegmentStock(symbol: 'SQ', name: 'Block Inc', price: 64.20, changePercent: 2.12, volume: '9.6M', peRatio: 48.2),
        ],
      ),
    ],
  ),

  // 5. HEALTHCARE
  MarketSector(
    name: 'Healthcare',
    changePercent: -0.85,
    weight: 0.12,
    topSymbols: ['LLY', 'UNH', 'JNJ'],
    icon: Icons.health_and_safety_rounded,
    segments: [
      IndustrySegment(
        name: 'Pharma & Biotech',
        stocks: [
          SegmentStock(symbol: 'LLY', name: 'Eli Lilly & Co', price: 948.20, changePercent: -1.25, volume: '4.8M', peRatio: 58.2),
          SegmentStock(symbol: 'JNJ', name: 'Johnson & Johnson', price: 162.40, changePercent: -0.42, volume: '8.9M', peRatio: 16.4),
          SegmentStock(symbol: 'PFE', name: 'Pfizer Inc', price: 28.90, changePercent: -0.65, volume: '32.4M', peRatio: 14.2),
          SegmentStock(symbol: 'ABBV', name: 'AbbVie Inc', price: 192.50, changePercent: 0.82, volume: '6.5M', peRatio: 18.6),
          SegmentStock(symbol: 'MRK', name: 'Merck & Co', price: 118.20, changePercent: -0.92, volume: '10.2M', peRatio: 15.1),
        ],
      ),
      IndustrySegment(
        name: 'Healthcare Plans & Insurance',
        stocks: [
          SegmentStock(symbol: 'UNH', name: 'UnitedHealth Group', price: 582.40, changePercent: -1.15, volume: '5.4M', peRatio: 22.8),
          SegmentStock(symbol: 'CVS', name: 'CVS Health Corp', price: 58.90, changePercent: -0.52, volume: '11.6M', peRatio: 11.8),
          SegmentStock(symbol: 'CI', name: 'The Cigna Group', price: 358.10, changePercent: 0.32, volume: '3.2M', peRatio: 14.5),
        ],
      ),
    ],
  ),

  // 6. ENERGY
  MarketSector(
    name: 'Energy',
    changePercent: 3.12,
    weight: 0.10,
    topSymbols: ['XOM', 'CVX'],
    icon: Icons.bolt_rounded,
    segments: [
      IndustrySegment(
        name: 'Integrated Oil & Gas',
        stocks: [
          SegmentStock(symbol: 'XOM', name: 'Exxon Mobil Corp', price: 118.50, changePercent: 3.42, volume: '22.4M', peRatio: 14.1),
          SegmentStock(symbol: 'CVX', name: 'Chevron Corp', price: 152.40, changePercent: 2.85, volume: '12.6M', peRatio: 13.8),
          SegmentStock(symbol: 'COP', name: 'ConocoPhillips', price: 112.80, changePercent: 3.12, volume: '8.5M', peRatio: 12.4),
        ],
      ),
      IndustrySegment(
        name: 'Refining & Energy Services',
        stocks: [
          SegmentStock(symbol: 'SLB', name: 'Schlumberger Ltd', price: 48.20, changePercent: 4.15, volume: '16.8M', peRatio: 15.2),
          SegmentStock(symbol: 'EOG', name: 'EOG Resources', price: 124.60, changePercent: 2.62, volume: '5.1M', peRatio: 11.6),
          SegmentStock(symbol: 'MPC', name: 'Marathon Petroleum', price: 168.40, changePercent: 1.95, volume: '4.8M', peRatio: 10.2),
        ],
      ),
    ],
  ),
];

class MarketTreemapWidget extends StatelessWidget {
  const MarketTreemapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Market Sector Treemap',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'S&P 500 Heatmap',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sector Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.25,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: kMarketSectors.length,
              itemBuilder: (context, index) {
                final sector = kMarketSectors[index];
                final isPositive = sector.changePercent >= 0;
                final tileColor = isPositive ? AppColors.positive : AppColors.negative;

                return InkWell(
                  onTap: () {
                    SectorSegmentModal.show(context, sector);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tileColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: tileColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(sector.icon, size: 16, color: tileColor),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: tileColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}${sector.changePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: tileColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sector.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              sector.topSymbols.join(', '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
