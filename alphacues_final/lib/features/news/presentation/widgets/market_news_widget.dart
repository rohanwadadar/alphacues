import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/news_repository.dart';
import '../news_detail_screen.dart';
import '../news_feed_screen.dart';

class MarketNewsWidget extends ConsumerWidget {
  const MarketNewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(marketNewsProvider(null));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.newspaper_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Market & Stock News',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewsFeedScreen()),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content State
            newsAsync.when(
              data: (articles) {
                final displayArticles = articles.isNotEmpty
                    ? articles
                    : ref.read(newsRepositoryProvider).generateUrgentMarketNews();

                // Display top 4 articles on Home Page
                final previewArticles = displayArticles.take(4).toList();

                return Column(
                  children: previewArticles.map((article) {
                    final timeLabel = _formatTimeAgo(article.publishedAt);
                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewsDetailScreen(article: article),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    article.imageUrl,
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 70,
                                      width: 70,
                                      color: colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.newspaper_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            article.source,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '• $timeLabel',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (article.symbols.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.secondaryContainer,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '\$${article.symbols.first}',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        article.headline,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (article != previewArticles.last)
                          Divider(
                            height: 12,
                            thickness: 0.5,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) {
                final fallbackArticles = ref.read(newsRepositoryProvider).generateUrgentMarketNews().take(4).toList();
                return Column(
                  children: fallbackArticles.map((article) {
                    final timeLabel = _formatTimeAgo(article.publishedAt);
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailScreen(article: article),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                article.headline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Text(timeLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimeAgo(String raw) {
  if (raw.isEmpty) return 'Recent';
  try {
    final dt = DateTime.parse(raw);
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) {
    return 'Recent';
  }
}

