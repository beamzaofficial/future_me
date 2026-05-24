import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/letter.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _letters =>
      _db.collection('letters');

  // CREATE
  Future<String> createLetter(Letter letter) async {
    final doc = await _letters.add(letter.toMap());
    return doc.id;
  }

  // READ — single
  Future<Letter?> getLetter(String id) async {
    final snap = await _letters.doc(id).get();
    if (!snap.exists) return null;
    return Letter.fromMap(snap.id, snap.data()!);
  }

  Stream<Letter?> watchLetter(String id) {
    return _letters.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Letter.fromMap(snap.id, snap.data()!);
    });
  }

  // READ — public wall (only unlocked, public letters)
  Stream<List<Letter>> watchPublicUnlocked({int limit = 50}) {
    final now = Timestamp.fromDate(DateTime.now());
    return _letters
        .where('isPublic', isEqualTo: true)
        .where('unlockAt', isLessThanOrEqualTo: now)
        .orderBy('unlockAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Letter.fromDoc).toList());
  }

  // READ — my vault (all letters by user, sorted by unlock time ASC)
  Stream<List<Letter>> watchMyLetters(String userId) {
    return _letters
        .where('authorId', isEqualTo: userId)
        .orderBy('unlockAt')
        .snapshots()
        .map((snap) => snap.docs.map(Letter.fromDoc).toList());
  }

  // UPDATE — only allowed before unlock and only by author
  Future<void> updateLetter(
    String id, {
    String? title,
    String? content,
    DateTime? unlockAt,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (unlockAt != null) data['unlockAt'] = Timestamp.fromDate(unlockAt);
    if (isPublic != null) data['isPublic'] = isPublic;
    if (data.isEmpty) return;
    await _letters.doc(id).update(data);
  }

  // DELETE
  Future<void> deleteLetter(String id) async {
    await _letters.doc(id).delete();
  }

  // REACT — set or remove reaction by current user
  Future<void> setReaction(
    String letterId,
    String userId,
    ReactionType? reaction,
  ) async {
    final field = 'reactions.$userId';
    if (reaction == null) {
      await _letters.doc(letterId).update({field: FieldValue.delete()});
    } else {
      await _letters.doc(letterId).update({field: reaction.key});
    }
  }
}
