import 'package:flutter/material.dart';
import 'package:test_project/features/trending/treanding.dart';


class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  NewsDetailScreen({required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("News Details")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsItem["title"] ?? "No Title",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              newsItem["description"] ?? "No Description Available",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
