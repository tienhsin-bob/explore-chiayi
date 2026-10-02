import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String category;
  final String source;
  final DateTime publishedAt;
  final DateTime updatedAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.source,
    required this.publishedAt,
    required this.updatedAt,
  });

  factory News.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return News(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      source: data['source'] ?? '',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'source': source,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
