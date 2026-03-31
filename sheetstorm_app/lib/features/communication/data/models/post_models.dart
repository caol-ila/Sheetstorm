/// Domain models for Communication — Posts, Comments, Reactions
import 'package:sheetstorm/shared/models/author_model.dart';

export 'package:sheetstorm/shared/models/author_model.dart' show Author;

// ─── Reaction Type ────────────────────────────────────────────────────────────

enum ReactionType {
  thumbsUp('👍'),
  clap('👏'),
  heart('❤️'),
  smile('😊'),
  trumpet('🎺');

  const ReactionType(this.emoji);
  final String emoji;

  static ReactionType fromJson(String value) => switch (value) {
        'thumbsUp' => ReactionType.thumbsUp,
        'clap' => ReactionType.clap,
        'heart' => ReactionType.heart,
        'smile' => ReactionType.smile,
        'trumpet' => ReactionType.trumpet,
        _ => ReactionType.thumbsUp,
      };

  String toJson() => name;
}

// ─── Reaction ─────────────────────────────────────────────────────────────────

class Reaction {
  final ReactionType type;
  final int count;
  final bool hasReacted;

  const Reaction({
    required this.type,
    required this.count,
    required this.hasReacted,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        type: ReactionType.fromJson(json['type'] as String),
        count: json['count'] as int,
        hasReacted: json['hasReacted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'count': count,
        'hasReacted': hasReacted,
      };

  Reaction copyWith({
    ReactionType? type,
    int? count,
    bool? hasReacted,
  }) =>
      Reaction(
        type: type ?? this.type,
        count: count ?? this.count,
        hasReacted: hasReacted ?? this.hasReacted,
      );
}

// ─── Post ─────────────────────────────────────────────────────────────────────

class Post {
  final String id;
  final String bandId;
  final Author author;
  final String title;
  final String content;
  final List<Attachment> attachments;
  final List<String> targetSectionIds;
  final bool isPinned;
  final Map<ReactionType, Reaction> reactions;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.bandId,
    required this.author,
    required this.title,
    required this.content,
    this.attachments = const [],
    this.targetSectionIds = const [],
    this.isPinned = false,
    this.reactions = const {},
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final reactionsMap = <ReactionType, Reaction>{};
    final reactionsJson = json['reactions'] as Map<String, dynamic>?;
    if (reactionsJson != null) {
      for (final entry in reactionsJson.entries) {
        final type = ReactionType.fromJson(entry.key);
        reactionsMap[type] =
            Reaction.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    return Post(
      id: json['id'] as String,
      bandId: json['bandId'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      targetSectionIds: (json['targetSectionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPinned: json['isPinned'] as bool? ?? false,
      reactions: reactionsMap,
      commentCount: json['commentCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final reactionsMap = <String, dynamic>{};
    for (final entry in reactions.entries) {
      reactionsMap[entry.key.toJson()] = entry.value.toJson();
    }

    return {
      'id': id,
      'bandId': bandId,
      'author': author.toJson(),
      'title': title,
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'targetSectionIds': targetSectionIds,
      'isPinned': isPinned,
      'reactions': reactionsMap,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? bandId,
    Author? author,
    String? title,
    String? content,
    List<Attachment>? attachments,
    List<String>? targetSectionIds,
    bool? isPinned,
    Map<ReactionType, Reaction>? reactions,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Post(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        author: author ?? this.author,
        title: title ?? this.title,
        content: content ?? this.content,
        attachments: attachments ?? this.attachments,
        targetSectionIds: targetSectionIds ?? this.targetSectionIds,
        isPinned: isPinned ?? this.isPinned,
        reactions: reactions ?? this.reactions,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─── Attachment ───────────────────────────────────────────────────────────────

class Attachment {
  final String type;
  final String url;
  final int sizeBytes;
  final String filename;

  const Attachment({
    required this.type,
    required this.url,
    required this.sizeBytes,
    required this.filename,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        type: json['type'] as String,
        url: json['url'] as String,
        sizeBytes: json['sizeBytes'] as int,
        filename: json['filename'] as String,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'sizeBytes': sizeBytes,
        'filename': filename,
      };
}

// ─── Comment ──────────────────────────────────────────────────────────────────

class Comment {
  final String id;
  final String postId;
  final Author author;
  final String content;
  final String? imageUrl;
  final String? parentId;
  final bool isDeleted;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    this.imageUrl,
    this.parentId,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        author: Author.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String,
        imageUrl: json['imageUrl'] as String?,
        parentId: json['parentId'] as String?,
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'author': author.toJson(),
        'content': content,
        'imageUrl': imageUrl,
        'parentId': parentId,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
      };

  Comment copyWith({
    String? id,
    String? postId,
    Author? author,
    String? content,
    String? imageUrl,
    String? parentId,
    bool? isDeleted,
    DateTime? createdAt,
  }) =>
      Comment(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        author: author ?? this.author,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        parentId: parentId ?? this.parentId,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
      );
}
