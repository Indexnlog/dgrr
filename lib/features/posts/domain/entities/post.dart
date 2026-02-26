/// 게시글 엔티티
class Post {
  const Post({
    required this.postId,
    required this.title,
    this.content,
    this.category,
    this.authorId,
    this.pollId,
    this.isPinned,
    this.publishAt,
    this.createdAt,
  });

  final String postId;
  final String title;
  final String? content;
  final String? category;
  final String? authorId;
  final String? pollId;
  final bool? isPinned;
  final DateTime? publishAt;
  final DateTime? createdAt;

  Post copyWith({
    String? postId,
    String? title,
    String? content,
    String? category,
    String? authorId,
    String? pollId,
    bool? isPinned,
    DateTime? publishAt,
    DateTime? createdAt,
  }) {
    return Post(
      postId: postId ?? this.postId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      pollId: pollId ?? this.pollId,
      isPinned: isPinned ?? this.isPinned,
      publishAt: publishAt ?? this.publishAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.postId == postId;
  }

  @override
  int get hashCode => postId.hashCode;
}
