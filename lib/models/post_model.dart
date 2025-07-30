// 📄 post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String teamId;
  final String title;
  final String content;
  final String category; // 공지, 후기, 자유 등
  final String authorId;
  final Timestamp createdAt;
  final Timestamp publishAt;
  final bool isPinned;
  final String? pollId;

  PostModel({
    required this.id,
    required this.teamId,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.createdAt,
    required this.publishAt,
    required this.isPinned,
    this.pollId,
  });

  factory PostModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      publishAt: data['publishAt'] ?? Timestamp.now(),
      isPinned: data['isPinned'] ?? false,
      pollId: data['pollId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'title': title,
      'content': content,
      'category': category,
      'authorId': authorId,
      'createdAt': createdAt,
      'publishAt': publishAt,
      'isPinned': isPinned,
      'pollId': pollId,
    };
  }
}
