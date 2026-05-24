import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/models/letter.dart';
import 'package:future_me/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreService service;

  setUp(() {
    fake = FakeFirebaseFirestore();
    service = FirestoreService(db: fake);
  });

  Letter make({
    String authorId = 'me',
    String title = 'hi',
    DateTime? unlockAt,
    bool isPublic = true,
    Map<String, String> reactions = const {},
  }) {
    return Letter(
      id: '',
      authorId: authorId,
      authorName: 'Me',
      title: title,
      content: 'content',
      createdAt: DateTime(2026, 1, 1),
      unlockAt: unlockAt ?? DateTime(2030, 1, 1),
      isPublic: isPublic,
      reactions: reactions,
    );
  }

  test('createLetter writes a document and returns its id', () async {
    final id = await service.createLetter(make());
    expect(id, isNotEmpty);
    final doc = await fake.collection('letters').doc(id).get();
    expect(doc.exists, true);
    expect(doc.data()!['title'], 'hi');
    expect(doc.data()!['authorId'], 'me');
    expect(doc.data()!['unlockAt'], isA<Timestamp>());
  });

  test('getLetter returns null for missing doc', () async {
    expect(await service.getLetter('does-not-exist'), null);
  });

  test('getLetter returns Letter for existing doc', () async {
    final id = await service.createLetter(make(title: 'hello'));
    final got = await service.getLetter(id);
    expect(got, isNotNull);
    expect(got!.title, 'hello');
  });

  test('updateLetter only updates given fields', () async {
    final id = await service.createLetter(make(title: 'old', isPublic: false));
    await service.updateLetter(id, title: 'new');
    final got = await service.getLetter(id);
    expect(got!.title, 'new');
    expect(got.isPublic, false);
  });

  test('deleteLetter removes the document', () async {
    final id = await service.createLetter(make());
    await service.deleteLetter(id);
    expect(await service.getLetter(id), null);
  });

  test('setReaction adds and removes a user\'s reaction', () async {
    final id = await service.createLetter(make());
    await service.setReaction(id, 'u1', ReactionType.heart);
    var got = await service.getLetter(id);
    expect(got!.reactions['u1'], 'heart');

    await service.setReaction(id, 'u1', null);
    got = await service.getLetter(id);
    expect(got!.reactions.containsKey('u1'), false);
  });

  test('watchMyLetters streams only that user\'s letters', () async {
    await service.createLetter(make(authorId: 'me', title: 'mine'));
    await service.createLetter(make(authorId: 'other', title: 'theirs'));

    final letters = await service.watchMyLetters('me').first;
    expect(letters, hasLength(1));
    expect(letters.first.title, 'mine');
  });

  test('watchPublicUnlocked excludes locked and private letters', () async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    final future = DateTime.now().add(const Duration(days: 1));

    await service.createLetter(
      make(title: 'public-unlocked', unlockAt: past, isPublic: true),
    );
    await service.createLetter(
      make(title: 'public-locked', unlockAt: future, isPublic: true),
    );
    await service.createLetter(
      make(title: 'private-unlocked', unlockAt: past, isPublic: false),
    );

    final letters = await service.watchPublicUnlocked().first;
    expect(letters.map((l) => l.title), ['public-unlocked']);
  });
}
