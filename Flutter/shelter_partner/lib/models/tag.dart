import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id;
  final String title;
  final int count;
  final Timestamp timestamp;
  final List<Map<String, dynamic>> authors;

  Tag({
    required this.id,
    required this.title,
    required this.count,
    required this.timestamp,
    this.authors = const [],
  });

  factory Tag.fromMap(Map<String, dynamic> data) {
    return Tag(
      id: data['id'] ?? "Unknown",
      title: data['title'] ?? "Unknown",
      count: data['count'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      authors:
          (data['authors'] as List<dynamic>?)
              ?.map((author) => Map<String, dynamic>.from(author))
              .toList() ??
          [],
    );
  }

  factory Tag.fromFirestore(Map<String, dynamic> data) {
    return Tag.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'count': count,
      'timestamp': timestamp,
      'authors': authors,
    };
  }

  Tag copyWith({
    String? id,
    String? title,
    int? count,
    Timestamp? timestamp,
    List<Map<String, dynamic>>? authors,
  }) {
    return Tag(
      id: id ?? this.id,
      title: title ?? this.title,
      count: count ?? this.count,
      timestamp: timestamp ?? this.timestamp,
      authors: authors ?? this.authors,
    );
  }
}
