import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/review_repository.dart';
import 'package:souq_skills/models/user.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

const _storedKeys = {
  'reviewerId',
  'subjectId',
  'rating',
  'tags',
  'contextId',
  'contextKind',
  'skillTitle',
  'createdAt',
};

ReviewDraft _draft({
  String subject = _sami,
  int rating = 5,
  List<String> tags = const ['On time'],
  String contextId = 't-1',
  String skillTitle = 'Guitar basics',
}) => ReviewDraft(
  subjectId: subject,
  rating: rating,
  tags: tags,
  contextId: contextId,
  contextKind: ReviewContextKind.trade,
  skillTitle: skillTitle,
);

void main() {
  group('ReviewDocument', () {
    test('the id is the reviewer and the member rated', () {
      expect(ReviewDocument.reviewIdFor(_maha, _sami), 'uid-maha_uid-sami');
      expect(
        () => ReviewDocument.reviewIdFor(_maha, 'a/b'),
        throwsA(isA<ReviewException>()),
      );
      expect(
        () => ReviewDocument.reviewIdFor('', _sami),
        throwsA(isA<ReviewException>()),
      );
    });

    test('stores only rating fields, by uid, with no profile data', () {
      final data = ReviewDocument.toData(_maha, _draft());

      expect({...data.keys, 'createdAt'}, _storedKeys);
      expect(data['reviewerId'], _maha);
      expect(data['subjectId'], _sami);
      expect(data['rating'], 5);
      expect(data['rating'], isA<int>());
      expect(data['tags'], ['On time']);
      expect(data['contextKind'], 'trade');
      expect(data.keys, isNot(contains('comment')));
      for (final value in data.values) {
        expect(value, isNot(User.currentUserId));
      }
    });

    test('leaves out an empty skill title and shortens a long one', () {
      expect(
        ReviewDocument.toData(_maha, _draft(skillTitle: '  ')),
        isNot(contains('skillTitle')),
      );
      final long = ReviewDocument.toData(_maha, _draft(skillTitle: 'x' * 150));
      expect(long['skillTitle'], hasLength(ReviewDocument.maxSkillTitleLength));
    });

    test('refuses rating yourself, by uid or as the current member', () {
      for (final self in [_maha, User.currentUserId]) {
        expect(
          () => ReviewDocument.validate(_maha, _draft(subject: self)),
          throwsA(same(ReviewException.cannotRateYourself)),
        );
      }
    });

    test('refuses ratings outside 1 to 5', () {
      for (final rating in [0, 6, -1]) {
        expect(
          () => ReviewDocument.validate(_maha, _draft(rating: rating)),
          throwsA(same(ReviewException.invalidRating)),
        );
      }
      for (final rating in [1, 5]) {
        ReviewDocument.validate(_maha, _draft(rating: rating));
      }
    });

    test('refuses unknown, repeated or too many tags', () {
      for (final tags in [
        ['Rude'],
        ['On time', 'On time'],
        [
          'Great teacher',
          'On time',
          'Friendly',
          'Well prepared',
          'Would trade again',
          'Great teacher',
        ],
      ]) {
        expect(
          () => ReviewDocument.validate(_maha, _draft(tags: tags)),
          throwsA(same(ReviewException.invalidTags)),
        );
      }
      ReviewDocument.validate(_maha, _draft(tags: const []));
    });

    test('refuses an exchange id that cannot be stored', () {
      expect(
        () => ReviewDocument.validate(_maha, _draft(contextId: 'trade/1')),
        throwsA(isA<ReviewException>()),
      );
    });

    test('the viewer reads their own uid as the current member', () {
      final data = {
        ...ReviewDocument.toData(_maha, _draft(tags: ['On time', 'Friendly'])),
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      };

      final asMaha = ReviewDocument.fromData('id', data, viewerUid: _maha);
      expect(asMaha.authorId, User.currentUserId);
      expect(asMaha.subjectId, _sami);
      expect(asMaha.rating, 5.0);
      expect(asMaha.comment, 'On time • Friendly');
      expect(asMaha.date, DateTime(2026, 3, 1));
      expect(asMaha.skillTitle, 'Guitar basics');

      final asSami = ReviewDocument.fromData('id', data, viewerUid: _sami);
      expect(asSami.authorId, _maha);
      expect(asSami.subjectId, User.currentUserId);

      final asLina = ReviewDocument.fromData('id', data, viewerUid: _lina);
      expect(asLina.authorId, _maha);
      expect(asLina.subjectId, _sami);
    });

    test('reads partial records safely', () {
      final review = ReviewDocument.fromData('id', {
        'reviewerId': _maha,
        'rating': 'five',
        'tags': ['On time', 3],
      });
      expect(review.subjectId, '');
      expect(review.rating, 0);
      expect(review.comment, 'On time');
      expect(review.contextId, '');
    });
  });

  group('DemoReviewRepository', () {
    test(
      'saves under the fixed id and returns it as the reviewer sees it',
      () async {
        final reviews = DemoReviewRepository();

        final saved = await reviews.createReview(_maha, _draft());

        expect(saved.id, 'uid-maha_uid-sami');
        expect(saved.authorId, User.currentUserId);
        expect(saved.subjectId, _sami);
        expect(reviews.storedData(saved.id)!.keys.toSet(), _storedKeys);
        expect(reviews.storedData(saved.id)!['reviewerId'], _maha);
      },
    );

    test('each member can rate another once', () async {
      final reviews = DemoReviewRepository();
      await reviews.createReview(_maha, _draft());

      await expectLater(
        reviews.createReview(_maha, _draft(contextId: 't-2', rating: 1)),
        throwsA(same(ReviewException.duplicate)),
      );
      expect(reviews.storedData('uid-maha_uid-sami')!['rating'], 5);
      // The other way round, and other members, are separate.
      await reviews.createReview(_sami, _draft(subject: _maha));
      await reviews.createReview(_lina, _draft());
    });

    test('nothing is stored for an invalid rating', () async {
      final reviews = DemoReviewRepository();
      await expectLater(
        reviews.createReview(_maha, _draft(subject: _maha)),
        throwsA(same(ReviewException.cannotRateYourself)),
      );
      await expectLater(
        reviews.createReview(_maha, _draft(rating: 9)),
        throwsA(same(ReviewException.invalidRating)),
      );
      expect(await reviews.fetchReviewsBy(_maha), isEmpty);
    });

    test(
      'fetches reviews about a member and by a member, newest first',
      () async {
        final reviews = DemoReviewRepository();
        await reviews.createReview(_maha, _draft(rating: 4));
        await reviews.createReview(_lina, _draft(rating: 2));
        await reviews.createReview(_maha, _draft(subject: _lina));

        final aboutSami = await reviews.fetchReviewsAbout(
          _sami,
          viewerUid: _lina,
        );
        expect([for (final r in aboutSami!) r.rating], [2, 4]);
        expect(aboutSami.first.authorId, User.currentUserId);

        final byMaha = await reviews.fetchReviewsBy(_maha);
        expect([for (final r in byMaha) r.subjectId], [_lina, _sami]);
      },
    );

    test('a hidden profile keeps its reviews private, but stored', () async {
      final public = {_sami: false};
      final reviews = DemoReviewRepository(
        isPublic: (uid) => public[uid] ?? true,
      );
      await reviews.createReview(_maha, _draft());

      expect(await reviews.fetchReviewsAbout(_sami, viewerUid: _lina), isNull);
      // The member always sees their own.
      final own = await reviews.fetchReviewsAbout(_sami, viewerUid: _sami);
      expect(own, hasLength(1));
      expect(own!.single.subjectId, User.currentUserId);
      // The reviewer still has what they wrote.
      expect(await reviews.fetchReviewsBy(_maha), hasLength(1));

      public[_sami] = true;
      expect(
        await reviews.fetchReviewsAbout(_sami, viewerUid: _lina),
        hasLength(1),
      );
    });
  });
}
