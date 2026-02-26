import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/post.dart';

/// 게시글 모델 (Firestore 변환 포함)
class PostModel extends Post {
  const PostModel({
    required super.postId,
    required super.title,
    super.content,
    super.category,
    super.authorId,
    super.pollId,
    super.isPinned,
    super.publishAt,
    super.createdAt,
  });

  factory PostModel.fromFirestore(String id, Map<String, dynamic> json) {
    return PostModel(
      postId: id,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      category: json['category'] as String?,
      authorId: json['authorId'] as String?,
      pollId: json['pollId'] as String?,
      isPinned: json['isPinned'] as bool?,
      publishAt: (json['publishAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (authorId != null) 'authorId': authorId,
      if (pollId != null) 'pollId': pollId,
      if (isPinned != null) 'isPinned': isPinned,
      if (publishAt != null) 'publishAt': Timestamp.fromDate(publishAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
