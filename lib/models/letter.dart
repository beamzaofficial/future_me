import 'package:cloud_firestore/cloud_firestore.dart';

enum ReactionType { heart, hug, star }

extension ReactionTypeX on ReactionType {
  String get key => name;

  static ReactionType? fromKey(String key) {
    for (final r in ReactionType.values) {
      if (r.key == key) return r;
    }
    return null;
  }
}

class Letter {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isPublic;
  // Map<userId, reactionKey> — one reaction per user
  final Map<String, String> reactions;

  const Letter({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.unlockAt,
    required this.isPublic,
    this.reactions = const {},
  });

  bool isUnlockedAt(DateTime now) => !now.isBefore(unlockAt);
  bool get isUnlocked => isUnlockedAt(DateTime.now());
  Duration timeUntilUnlockAt(DateTime now) => unlockAt.difference(now);
  Duration get timeUntilUnlock => timeUntilUnlockAt(DateTime.now());

  int reactionCount(ReactionType type) =>
      reactions.values.where((v) => v == type.key).length;

  ReactionType? reactionOf(String userId) =>
      ReactionTypeX.fromKey(reactions[userId] ?? '');

  Letter copyWith({
    String? title,
    String? content,
    DateTime? unlockAt,
    bool? isPublic,
    Map<String, String>? reactions,
  }) {
    return Letter(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      isPublic: isPublic ?? this.isPublic,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'title': title,
    'content': content,
    'createdAt': Timestamp.fromDate(createdAt),
    'unlockAt': Timestamp.fromDate(unlockAt),
    'isPublic': isPublic,
    'reactions': reactions,
  };

  factory Letter.fromMap(String id, Map<String, dynamic> data) {
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    return Letter(
      id: id,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Anonymous',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      title: (data['title'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      unlockAt: _toDate(data['unlockAt']) ?? DateTime.now(),
      isPublic: (data['isPublic'] as bool?) ?? false,
      reactions: rawReactions.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  factory Letter.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Letter.fromMap(doc.id, doc.data() ?? {});
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
