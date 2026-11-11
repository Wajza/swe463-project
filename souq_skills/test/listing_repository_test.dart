import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';

const _me = 'uid-maha';
const _other = 'uid-sami';

/// A listing as the app holds it: owned by the current member, 'me'.
const _draft = SkillListing(
  id: 'l-7',
  ownerId: User.currentUserId,
  category: 'Design',
  title: 'Learn Calligraphy',
  offers: 'Arabic calligraphy',
  wants: 'Photography',
  distance: '2 km',
  description: 'Practical sessions.',
  city: 'Jeddah',
  availability: 'Weekends',
  sessionsMinutes: 45,
  onlineOnly: true,
  womenOnly: true,
  isSaved: true,
  isPaused: true,
);

/// What [_draft] looks like once stored for [_me].
Map<String, dynamic> _stored({String owner = _me}) => {
  'ownerId': owner,
  'category': 'Design',
  'title': 'Learn Calligraphy',
  'offers': 'Arabic calligraphy',
  'wants': 'Photography',
  'distance': '2 km',
  'description': 'Practical sessions.',
  'city': 'Jeddah',
  'availability': 'Weekends',
  'sessionsMinutes': 45,
  'onlineOnly': true,
  'womenOnly': true,
  'isPaused': true,
};

void main() {
  group('ListingDocument.toData', () {
    test('stores the owner by uid, without the id or isSaved', () {
      expect(ListingDocument.toData(_me, _draft), _stored());
    });

    test('accepts a listing already naming the uid as owner', () {
      expect(
        ListingDocument.toData(_me, _draft.copyWith(ownerId: _me)),
        _stored(),
      );
    });

    test("refuses another member's listing", () {
      expect(
        () => ListingDocument.toData(_me, _draft.copyWith(ownerId: _other)),
        throwsA(same(ListingException.notYours)),
      );
    });
  });

  group('ListingDocument.fromData', () {
    test("shows the viewer's own listing as owned by 'me'", () {
      final listing = ListingDocument.fromData(
        'abc',
        _stored(),
        viewerUid: _me,
      );

      expect(listing.id, 'abc');
      expect(listing.ownerId, User.currentUserId);
      expect(
        listing.toJson(),
        _draft.copyWith(id: 'abc', isSaved: false).toJson(),
      );
    });

    test("keeps other members' uids, and every uid when signed out", () {
      expect(
        ListingDocument.fromData('abc', _stored(), viewerUid: _other).ownerId,
        _me,
      );
      expect(ListingDocument.fromData('abc', _stored()).ownerId, _me);
    });

    test('never reads a stored isSaved', () {
      final listing = ListingDocument.fromData('abc', {
        ..._stored(),
        'isSaved': true,
      }, viewerUid: _me);

      expect(listing.isSaved, isFalse);
    });

    test('gives an older record with missing fields the usual defaults', () {
      final listing = ListingDocument.fromData('old', {
        'ownerId': _other,
        'category': 'Cooking',
        'offers': 'Baking',
      });

      const defaults = SkillListing(ownerId: '', category: '');
      expect(listing.ownerId, _other);
      expect(listing.category, 'Cooking');
      expect(listing.offers, 'Baking');
      expect(listing.title, '');
      expect(listing.wants, '');
      expect(listing.description, '');
      expect(listing.city, defaults.city);
      expect(listing.availability, '');
      expect(listing.sessionsMinutes, defaults.sessionsMinutes);
      expect(listing.onlineOnly, isFalse);
      expect(listing.womenOnly, isFalse);
      expect(listing.isPaused, isFalse);
    });

    test('ignores wrongly typed and extra fields', () {
      final listing = ListingDocument.fromData('odd', {
        'ownerId': 42,
        'category': null,
        'title': ['not', 'text'],
        'city': 7,
        'sessionsMinutes': 30.0,
        'onlineOnly': 'yes',
        'isPaused': 1,
        'createdAt': DateTime(2026),
        'id': 'some-other-id',
      });

      expect(listing.id, 'odd');
      expect(listing.ownerId, '');
      expect(listing.category, '');
      expect(listing.title, '');
      expect(listing.city, 'Riyadh');
      expect(listing.sessionsMinutes, 30);
      expect(listing.onlineOnly, isFalse);
      expect(listing.isPaused, isFalse);
    });

    test('reads an empty record', () {
      final listing = ListingDocument.fromData('empty', {});

      expect(listing.id, 'empty');
      expect(listing.ownerId, '');
    });
  });

  group('DemoListingRepository', () {
    test('creates a listing owned by the uid, returned as mine', () async {
      final repository = DemoListingRepository();

      final created = await repository.createListing(_me, _draft);

      expect(created.id, isNot(anyOf('', _draft.id)));
      expect(created.ownerId, User.currentUserId);
      expect(created.isSaved, isFalse);
      expect(repository.storedData(created.id), _stored());
    });

    test('gives every new listing its own id', () async {
      final repository = DemoListingRepository(
        documents: {'listing-1': _stored(owner: _other)},
      );

      final first = await repository.createListing(_me, _draft);
      final second = await repository.createListing(_me, _draft);

      expect({first.id, second.id, 'listing-1'}, hasLength(3));
    });

    test('fetches one listing as the viewer sees it', () async {
      final repository = DemoListingRepository();
      final created = await repository.createListing(_me, _draft);

      final mine = await repository.fetchListing(created.id, uid: _me);
      final theirs = await repository.fetchListing(created.id, uid: _other);

      expect(mine!.toJson(), created.toJson());
      expect(theirs!.ownerId, _me);
      expect(await repository.fetchListing('missing', uid: _me), isNull);
    });

    test("fetches everyone's listings, paused ones included", () async {
      final repository = DemoListingRepository(
        documents: {
          'sami-1': _stored(owner: _other),
          'maha-1': {..._stored(), 'isPaused': false},
        },
      );

      final listings = await repository.fetchListings(uid: _me);

      expect(listings.map((item) => item.id), ['sami-1', 'maha-1']);
      expect(listings.first.ownerId, _other);
      expect(listings.first.isPaused, isTrue);
      expect(listings.last.ownerId, User.currentUserId);
    });

    test('updates its owner\'s listing and keeps unknown fields', () async {
      final repository = DemoListingRepository(
        documents: {
          'abc': {..._stored(), 'createdAt': '2026-01-01', 'isSaved': true},
        },
      );
      final listing = (await repository.fetchListing('abc', uid: _me))!;

      await repository.updateListing(
        _me,
        listing.copyWith(city: 'Riyadh', isPaused: false, isSaved: true),
      );

      final stored = repository.storedData('abc')!;
      expect(stored['city'], 'Riyadh');
      expect(stored['isPaused'], isFalse);
      expect(stored['title'], 'Learn Calligraphy');
      expect(stored['ownerId'], _me);
      expect(stored['createdAt'], '2026-01-01');
      // An old shared isSaved is left as it was, never written.
      expect(stored['isSaved'], isTrue);
    });

    test("refuses to update another member's listing", () async {
      final repository = DemoListingRepository(
        documents: {'abc': _stored(owner: _other)},
      );

      // The app could only send it as someone else's, or claim it as mine.
      final asSeen = (await repository.fetchListing('abc', uid: _me))!;
      await expectLater(
        repository.updateListing(_me, asSeen.copyWith(title: 'Hijacked')),
        throwsA(same(ListingException.notYours)),
      );
      await expectLater(
        repository.updateListing(
          _me,
          asSeen.copyWith(ownerId: User.currentUserId, title: 'Hijacked'),
        ),
        throwsA(same(ListingException.notYours)),
      );
      expect(repository.storedData('abc'), _stored(owner: _other));
    });

    test('refuses to update a listing that does not exist', () async {
      await expectLater(
        DemoListingRepository().updateListing(_me, _draft),
        throwsA(same(ListingException.notFound)),
      );
    });

    test("deletes its owner's listing", () async {
      final repository = DemoListingRepository();
      final created = await repository.createListing(_me, _draft);

      await repository.deleteListing(_me, created.id);

      expect(await repository.fetchListing(created.id, uid: _me), isNull);
    });

    test(
      "refuses to delete another member's listing or a missing one",
      () async {
        final repository = DemoListingRepository(
          documents: {'abc': _stored(owner: _other)},
        );

        await expectLater(
          repository.deleteListing(_me, 'abc'),
          throwsA(same(ListingException.notYours)),
        );
        await expectLater(
          repository.deleteListing(_me, 'missing'),
          throwsA(same(ListingException.notFound)),
        );
        expect(repository.storedData('abc'), _stored(owner: _other));
      },
    );

    test('opens older stored records and can update them', () async {
      final repository = DemoListingRepository(
        documents: {
          'old': {'ownerId': _me, 'category': 'Cooking', 'offers': 'Baking'},
        },
      );

      final old = (await repository.fetchListing('old', uid: _me))!;
      expect(old.ownerId, User.currentUserId);
      expect(old.sessionsMinutes, 60);

      await repository.updateListing(_me, old.copyWith(wants: 'Piano'));
      final updated = (await repository.fetchListing('old', uid: _me))!;
      expect(updated.wants, 'Piano');
      expect(updated.offers, 'Baking');
      expect(repository.storedData('old')!.containsKey('isSaved'), isFalse);
    });

    test('hands out copies, so changes to them are not stored', () async {
      final repository = DemoListingRepository(documents: {'abc': _stored()});

      repository.storedData('abc')!['title'] = 'Changed';

      expect(repository.storedData('abc')!['title'], 'Learn Calligraphy');
    });
  });
}
