import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/screens/group_trades/edit_group_trade_screen.dart';
import 'package:souq_skills/screens/listings/edit_listing_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _uid = 'uid-maha';
const _otherUid = 'uid-sami';
const _offline = ListingException('Check your internet connection.');

/// The offline sign-in, but with a Firebase-like uid, so listings are
/// stored under a real owner id rather than 'me'.
class _UidAuth extends DemoAuthRepository {
  _UidAuth() : super(isKnownPhone: AuthService().isKnownPhone);

  @override
  String? get uid => _uid;
}

/// Stands in for Firestore; each write can be held back or made to fail.
class _Listings extends DemoListingRepository {
  _Listings({super.documents});

  bool fail = false;
  Completer<void>? hold;
  int writes = 0;

  Future<void> _write() async {
    writes++;
    await hold?.future;
    if (fail) throw _offline;
  }

  @override
  Future<SkillListing> createListing(String uid, SkillListing draft) async {
    await _write();
    return super.createListing(uid, draft);
  }

  @override
  Future<void> updateListing(String uid, SkillListing listing) async {
    await _write();
    return super.updateListing(uid, listing);
  }

  @override
  Future<void> deleteListing(String uid, String id) async {
    await _write();
    return super.deleteListing(uid, id);
  }
}

/// A listing of the signed-in member, as stored online.
Map<String, dynamic> _stored({String owner = _uid}) => {
  'ownerId': owner,
  'category': 'Cooking',
  'title': 'Learn Baking',
  'offers': 'Baking',
  'wants': 'Piano',
  'distance': '',
  'description': 'Practical Baking sessions, exchanged for Piano.',
  'city': 'Jeddah',
  'availability': 'Weekends',
  'sessionsMinutes': 60,
  'onlineOnly': false,
  'womenOnly': false,
  'isPaused': false,
  'createdAt': '2026-01-01',
};

Future<void> _signIn(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '501234567');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Future<void> _fillPostForm(WidgetTester tester) async {
  await tester.tap(find.text('Post'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cooking'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Baking'));
  await tester.pumpAndSettle();
}

/// Opens Edit listing for the stored listing 'abc'.
Future<void> _openEdit(WidgetTester tester) async {
  await _signIn(tester);
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('My listings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Learn Baking'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit listing'));
  await tester.pumpAndSettle();
}

Future<void> _openMenuItem(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip('More options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
}

bool _buttonEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Listings listings;

  /// Puts the stored listing 'abc' on the device too, as mine.
  void addOwnListing() => repository.listings.add(
    ListingDocument.fromData('abc', _stored(), viewerUid: _uid),
  );

  setUp(() {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    AuthService.repository = _UidAuth();
    listings = _Listings(documents: {'abc': _stored()});
    ListingService.repository = listings;
  });

  tearDown(() {
    ListingService.repository = null;
    AuthService.repository = originalAuth;
  });

  group('creating', () {
    testWidgets('a listing is saved online, then shown as published', (
      tester,
    ) async {
      await _signIn(tester);
      await _fillPostForm(tester);
      final saving = listings.hold = Completer<void>();
      final mineBefore = ListingService().mine().length;

      await tester.tap(find.text('Publish'));
      await tester.pump();

      // Nothing is shown as published before it has been saved.
      expect(find.text('Publishing…'), findsOneWidget);
      expect(_buttonEnabled(tester), isFalse);
      expect(ListingService().mine(), hasLength(mineBefore));

      saving.complete();
      await tester.pumpAndSettle();

      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Edit listing'), findsOneWidget);
      final published = ListingService().mine().singleWhere(
        (item) => item.title == 'Learn Baking' && item.id != 'abc',
      );
      final stored = listings.storedData(published.id)!;
      expect(stored['ownerId'], _uid);
      expect(stored['offers'], 'Baking');
      expect(stored.containsKey('isSaved'), isFalse);
      expect(published.ownerId, 'me');
    });

    testWidgets('a failed publish keeps the form and can be retried', (
      tester,
    ) async {
      await _signIn(tester);
      await _fillPostForm(tester);
      listings.fail = true;
      final before = ListingService().mine().length;

      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Post a skill'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(ListingService().mine(), hasLength(before));
      expect(await listings.fetchListings(uid: _uid), hasLength(1));

      listings.fail = false;
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(find.text('Published'), findsOneWidget);
      expect(ListingService().mine(), hasLength(before + 1));
    });
  });

  group('editing', () {
    testWidgets('a change is saved online, then on the device', (tester) async {
      addOwnListing();
      await _openEdit(tester);

      await tester.tap(find.text('90 min'));
      await tester.pump();
      final saving = listings.hold = Completer<void>();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Saving…'), findsOneWidget);
      expect(ListingService().byId('abc')!.sessionsMinutes, 60);

      saving.complete();
      await tester.pumpAndSettle();

      expect(find.text('Listing updated'), findsOneWidget);
      final stored = listings.storedData('abc')!;
      expect(stored['sessionsMinutes'], 90);
      // Generated text and fields not on the form are kept.
      expect(stored['title'], 'Learn Baking');
      expect(stored['description'], _stored()['description']);
      expect(stored['createdAt'], '2026-01-01');
      expect(ListingService().byId('abc')!.sessionsMinutes, 90);
    });

    testWidgets('a failed save keeps the screen and the listing as it was', (
      tester,
    ) async {
      addOwnListing();
      await _openEdit(tester);
      listings.fail = true;

      await tester.tap(find.text('90 min'));
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(listings.storedData('abc')!['sessionsMinutes'], 60);
      expect(ListingService().byId('abc')!.sessionsMinutes, 60);
    });

    testWidgets('pausing and resuming are saved online', (tester) async {
      addOwnListing();
      await _openEdit(tester);

      await _openMenuItem(tester, 'Pause listing');
      await tester.pumpAndSettle();
      expect(find.text('Listing paused'), findsOneWidget);
      expect(listings.storedData('abc')!['isPaused'], isTrue);
      expect(ListingService().byId('abc')!.isPaused, isTrue);

      await _openMenuItem(tester, 'Resume listing');
      await tester.pumpAndSettle();
      expect(listings.storedData('abc')!['isPaused'], isFalse);
      expect(ListingService().byId('abc')!.isPaused, isFalse);

      // A failure leaves it as it was.
      listings.fail = true;
      await _openMenuItem(tester, 'Pause listing');
      await tester.pumpAndSettle();
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(listings.storedData('abc')!['isPaused'], isFalse);
      expect(ListingService().byId('abc')!.isPaused, isFalse);
    });
  });

  group('deleting', () {
    testWidgets('the screen only closes once the listing is deleted', (
      tester,
    ) async {
      addOwnListing();
      await _openEdit(tester);
      final deleting = listings.hold = Completer<void>();

      await _openMenuItem(tester, 'Delete listing');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(EditListingScreen), findsOneWidget);
      expect(find.byTooltip('More options'), findsNothing);
      expect(ListingService().byId('abc'), isNotNull);

      deleting.complete();
      await tester.pumpAndSettle();

      expect(find.text('Listing deleted'), findsOneWidget);
      expect(find.byType(EditListingScreen), findsNothing);
      expect(find.text('My listings'), findsOneWidget);
      expect(listings.storedData('abc'), isNull);
      expect(ListingService().byId('abc'), isNull);
    });

    testWidgets('a failed delete stays on the screen and keeps the listing', (
      tester,
    ) async {
      addOwnListing();
      await _openEdit(tester);
      listings.fail = true;

      await _openMenuItem(tester, 'Delete listing');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.byType(EditListingScreen), findsOneWidget);
      expect(listings.storedData('abc'), isNotNull);
      expect(ListingService().byId('abc'), isNotNull);
    });
  });

  group('ownership', () {
    test("another member's listing cannot be changed or deleted", () async {
      final theirs = ListingService().byId('l-flutter')!;
      expect(ListingService().isMine(theirs), isFalse);

      await expectLater(
        ListingService().update(theirs.copyWith(title: 'Hijacked')),
        throwsA(same(ListingException.notYours)),
      );
      await expectLater(
        ListingService().setPaused('l-flutter', true),
        throwsA(same(ListingException.notYours)),
      );
      await expectLater(
        ListingService().delete('l-flutter'),
        throwsA(same(ListingException.notYours)),
      );

      expect(listings.writes, 0);
      expect(ListingService().byId('l-flutter')!.toJson(), theirs.toJson());
    });

    test('a listing owned by someone else online is refused', () async {
      // The device believes it is mine; the stored owner says otherwise.
      final repositoryListings = _Listings(
        documents: {'abc': _stored(owner: _otherUid)},
      );
      ListingService.repository = repositoryListings;
      addOwnListing();

      await expectLater(
        ListingService().update(
          ListingService().byId('abc')!.copyWith(title: 'Hijacked'),
        ),
        throwsA(same(ListingException.notYours)),
      );
      await expectLater(
        ListingService().delete('abc'),
        throwsA(same(ListingException.notYours)),
      );
      expect(ListingService().byId('abc')!.title, 'Learn Baking');
      expect(repositoryListings.storedData('abc')!['title'], 'Learn Baking');
    });

    testWidgets('Edit listing refuses to open for someone else', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: EditListingScreen(listingId: 'l-flutter')),
      );

      expect(find.text('Not your listing'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
      expect(find.byTooltip('More options'), findsNothing);
    });
  });

  group('group trades are unchanged', () {
    testWidgets('publishing a group writes no listing', (tester) async {
      await _signIn(tester);
      final groupsBefore = GroupTradeService().all().length;
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Singing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(find.text('Group created'), findsOneWidget);
      expect(find.text('Music skill circle'), findsOneWidget);
      expect(GroupTradeService().all(), hasLength(groupsBefore + 1));
      expect(listings.writes, 0);
    });

    testWidgets('editing a group saves straight away, as before', (
      tester,
    ) async {
      final id = await PostingService().publish(
        const SkillPost(
          kind: ListingKind.group,
          category: 'Music',
          skills: ['Piano', 'Singing'],
          city: 'Riyadh',
          availability: 'Weekends',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EditGroupTradeScreen(groupId: id),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oud lessons'));
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      // Saved in the same step, with no waiting state.
      expect(find.text('Saving…'), findsNothing);
      expect(
        GroupTradeService().byId(id)!.skills,
        containsAll(['Piano', 'Singing', 'Oud lessons']),
      );
      await tester.pumpAndSettle();
      expect(find.text('Group trade updated'), findsOneWidget);
      expect(listings.writes, 0);
    });
  });
}
