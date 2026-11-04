import 'package:flutter/material.dart';

import '../data/news_repository.dart';
import '../../market/presentation/symbol_detail_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  String _formatTime(String raw) {
    if (raw.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().toUtc().difference(dt.toUtc());
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recent';
    }
  }

  void _launchUrl(BuildContext context, String url) {
    if (url.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Source URL: $url'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Market Article',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (article.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Read Original',
              onPressed: () => _launchUrl(context, article.url),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                article.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.newspaper_rounded, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Source & Date Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    article.source.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatTime(article.publishedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Headline
            Text(
              article.headline,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Mentioned Tickers Badges
            if (article.symbols.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: article.symbols.map((sym) {
                  return ActionChip(
                    avatar: const Icon(Icons.show_chart_rounded, size: 16),
                    label: Text(
                      '\$$sym',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymbolDetailScreen(symbol: sym),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // AI Insights / Key Takeaways Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Takeaways',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Article Content
            Text(
              article.content.isNotEmpty ? article.content : article.summary,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),

            // Read Full Source Button
            if (article.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  icon: const Icon(Icons.launch_rounded),
                  label: const Text('Read Full Article on Source'),
                  onPressed: () => _launchUrl(context, article.url),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
