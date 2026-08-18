import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_session.dart';

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.headline,
    required this.summary,
    required this.content,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.symbols,
    required this.sentiment,
  });

  final String id;
  final String headline;
  final String summary;
  final String content;
  final String source;
  final String url;
  final String imageUrl;
  final String publishedAt;
  final List<String> symbols;
  final String sentiment;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    List<String> parsedSymbols = [];
    if (rawSymbols is List) {
      parsedSymbols = rawSymbols.map((e) => e.toString()).toList();
    }

    return NewsArticle(
      id: json['id'] as String? ?? '',
      headline: json['headline'] as String? ?? 'Market News',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      source: json['source'] as String? ?? 'Market Watch',
      url: json['url'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ??
          'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=600&q=80',
      publishedAt: json['publishedAt'] as String? ?? '',
      symbols: parsedSymbols,
      sentiment: json['sentiment'] as String? ?? 'neutral',
    );
  }
}

class NewsRepository {
  NewsRepository(this._dio);

  final Dio _dio;

  Future<List<NewsArticle>> getMarketNews({String? symbol, int limit = 15}) async {
    try {
      final query = <String, dynamic>{'limit': limit};
      if (symbol != null && symbol.isNotEmpty) {
        query['symbol'] = symbol;
      }

      final response = await _dio.get<dynamic>('/api/v1/news', queryParameters: query);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list.map((item) => NewsArticle.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<NewsArticle?> getNewsDetail(String newsId) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/news/$newsId');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        return NewsArticle.fromJson(Map<String, dynamic>.from(data['data'] as Map));
      }
    } catch (_) {}
    return null;
  }
}

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(ref.watch(dioProvider));
});

final marketNewsProvider = FutureProvider.family<List<NewsArticle>, String?>((ref, symbol) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.getMarketNews(symbol: symbol);
});
