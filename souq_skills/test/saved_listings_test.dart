import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/home/saved_skills_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _noura = 'uid-noura';
const _offline = ListingException('Check your internet connection.');

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Stands in for Firestore's listings; loading can be held back.
class _Listings extends DemoListingRepository {
  _Listings({super.documents});

  Completer<void>? hold;

  @override
  Future<List<SkillListing>> fetchListings({String? uid}) async {
    await hold?.future;
    return super.fetchListings(uid: uid);
  }
}

/// Stands in for each member's saved listings; can fail or hold writes.
class _Saved extends DemoSavedListingsRepository {
  _Saved({super.saved});

  bool failFetch = false;
  bool failWrites = false;
  Completer<void>? holdWrites;
  int writes = 0;

  @override
  Future<Set<String>> fetchSavedIds(String uid) async {
    if (failFetch) throw _offline;
    return super.fetchSavedIds(uid);
  }

  @override
  Future<void> save(String uid, String listingId) async {
    await _write();
    return super.save(uid, listingId);
  }

  @override
  Future<void> unsave(String uid, String listingId) async {
    await _write();
    return super.unsave(uid, listingId);
  }

  Future<void> _write() async {
    writes++;
    await holdWrites?.future;
    if (failWrites) throw _offline;
  }
}

Map<String, dynamic> _listing(String owner, String title) => {
  'ownerId': owner,
  'category': 'Cooking',
  'title': title,
  'offers': 'Baking',
  'wants': 'Piano',
  'distance': '',
  'description': '$title, in full.',
  'city': 'Riyadh',
  'availability': 'Weekends',
  'sessionsMinutes': 60,
  'onlineOnly': false,
  'womenOnly': false,
  'isPaused': false,
};

Map<String, Map<String, dynamic>> _documents() => {
  'maha-1': _listing(_maha, 'Learn Baking'),
  'sami-1': _listing(_sami, 'Flutter from zero'),
  'lina-1': _listing(_lina, 'Calligraphy basics'),
};

Future<void> _start(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, {bool settle = true}) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '501234567');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _signOut(WidgetTester tester) async {
  // On the Profile tab already, its title also reads "Profile".
  if (find.byTooltip('Settings').evaluate().isEmpty) {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out').last);
  await tester.pumpAndSettle();
}

Future<void> _openSaved(WidgetTester tester, {bool settle = true}) async {
  // A spinner never settles, so then step through the frames instead.
  Future<void> wait() async {
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await tester.tap(find.text('Profile'));
  await wait();
  await tester.tap(find.text('Saved skills'));
  await wait();
}

/// The heart on the Home card of the listing titled [title].
Finder _heart(String title, {required bool saved}) => find.descendant(
  of: find.widgetWithText(Card, title),
  matching: find.byTooltip(saved ? 'Remove from saved' : 'Save skill'),
);

/// The titles listed on Saved skills.
List<String> _savedTitles(WidgetTester tester) => [
  for (final title in [
    'Learn Baking',
    'Flutter from zero',
    'Calligraphy basics',
  ])
    if (find
        .descendant(
          of: find.byType(SavedSkillsScreen),
          matching: find.text(title),
        )
        .evaluate()
        .isNotEmpty)
      title,
];

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late _Listings listings;
  late _Saved saved;

  void useSaved(Map<String, Set<String>> initial) {
    saved = _Saved(saved: initial);
    ListingService.savedRepository = saved;
  }

  setUp(() {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    listings = _Listings(documents: _documents());
    ListingService.repository = listings;
    useSaved({});
  });

  tearDown(() {
    ListingService.repository = null;
    ListingService.savedRepository = null;
    AuthService.repository = originalAuth;
  });

  group('saving and unsaving', () {
    testWidgets('the heart saves a listing for this member only', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);

      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();

      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
      expect(await saved.fetchSavedIds(_maha), {'sami-1'});
      expect(await saved.fetchSavedIds(_sami), isEmpty);
      // The shared listing is never marked as saved.
      expect(listings.storedData('sami-1')!.containsKey('isSaved'), isFalse);

      await _openSaved(tester);
      expect(_savedTitles(tester), ['Flutter from zero']);
    });

    testWidgets('the heart on the details page unsaves it', (tester) async {
      useSaved({
        _maha: {'sami-1'},
      });
      await _start(tester);
      await _signIn(tester);

      await tester.tap(find.text('Flutter from zero'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Save skill'), findsOneWidget);
      expect(await saved.fetchSavedIds(_maha), isEmpty);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _openSaved(tester);
      expect(find.text('No saved skills'), findsOneWidget);
    });

    testWidgets('saved listings are fetched when signing in', (tester) async {
      useSaved({
        _maha: {'sami-1', 'lina-1'},
      });
      await _start(tester);
      await _signIn(tester);

      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
      expect(_heart('Calligraphy basics', saved: true), findsOneWidget);
      await _openSaved(tester);
      expect(_savedTitles(tester), ['Flutter from zero', 'Calligraphy basics']);
    });

    testWidgets('a failed save puts the heart back and says why', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      saved.failWrites = true;

      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(_heart('Flutter from zero', saved: false), findsOneWidget);
      expect(ListingService().byId('sami-1')!.isSaved, isFalse);
      expect(await saved.fetchSavedIds(_maha), isEmpty);
    });

    testWidgets('rapid taps send one change at a time', (tester) async {
      await _start(tester);
      await _signIn(tester);
      final saving = saved.holdWrites = Completer<void>();

      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pump();

      // Shown as saved straight away; more taps while saving are ignored,
      // and taken by the heart rather than opening the listing.
      final heart = _heart('Flutter from zero', saved: true);
      expect(heart, findsOneWidget);
      await tester.tap(heart);
      await tester.tap(heart);
      await tester.pump();
      expect(saved.writes, 1);
      expect(find.text('Listing details'), findsNothing);
      expect(heart, findsOneWidget);

      saving.complete();
      await tester.pumpAndSettle();
      expect(saved.writes, 1);
      expect(await saved.fetchSavedIds(_maha), {'sami-1'});
      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
    });
  });

  group('keeping saved listings', () {
    testWidgets('they survive a refresh', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();

      await tester.fling(
        find.text('Skills for you'),
        const Offset(0, 1500),
        1000,
      );
      await tester.pumpAndSettle();

      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
      expect(await saved.fetchSavedIds(_maha), {'sami-1'});
    });

    testWidgets('they survive signing out and back in', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();

      await _signOut(tester);
      await _signIn(tester);

      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
    });

    testWidgets('they come back after a restart with nothing on the device', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();

      // A fresh start: the device keeps nothing, saved listings are online.
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      ListingService.repository = listings;
      await tester.pumpWidget(const SizedBox());
      await _start(tester);
      await _signIn(tester);

      expect(_heart('Flutter from zero', saved: true), findsOneWidget);
    });
  });

  group('separate accounts', () {
    testWidgets('each account sees only its own saved listings', (
      tester,
    ) async {
      useSaved({
        _maha: {'sami-1'},
        _sami: {'lina-1'},
      });
      await _start(tester);
      await _signIn(tester);
      await _openSaved(tester);
      expect(_savedTitles(tester), ['Flutter from zero']);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _signOut(tester);
      auth.currentUid = _sami;
      await _signIn(tester);

      expect(_heart('Calligraphy basics', saved: true), findsOneWidget);
      await _openSaved(tester);
      expect(_savedTitles(tester), ['Calligraphy basics']);
    });

    testWidgets("the previous account's hearts never show for the next", (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(_heart('Flutter from zero', saved: false));
      await tester.pumpAndSettle();
      // Maha's heart is still marked on this device.
      expect(ListingService().byId('sami-1')!.isSaved, isTrue);

      await _signOut(tester);
      auth.currentUid = _noura;
      final loading = listings.hold = Completer<void>();
      await _signIn(tester, settle: false);
      await _openSaved(tester, settle: false);

      // While Noura's listings load, nothing of Maha's is shown.
      expect(find.byType(SavedSkillsScreen), findsOneWidget);
      expect(_savedTitles(tester), isEmpty);
      expect(
        find.descendant(
          of: find.byType(SavedSkillsScreen),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      loading.complete();
      await tester.pumpAndSettle();
      expect(find.text('No saved skills'), findsOneWidget);
      expect(ListingService().byId('sami-1')!.isSaved, isFalse);
      expect(await saved.fetchSavedIds(_maha), {'sami-1'});
    });
  });

  group('listings that are gone', () {
    testWidgets('a saved listing deleted elsewhere is dropped and forgotten', (
      tester,
    ) async {
      useSaved({
        _maha: {'sami-1', 'lina-1', 'deleted-long-ago'},
      });
      await listings.deleteListing(_lina, 'lina-1');
      await _start(tester);
      await _signIn(tester);

      await _openSaved(tester);
      expect(_savedTitles(tester), ['Flutter from zero']);
      // References to listings that no longer exist are cleaned up.
      expect(await saved.fetchSavedIds(_maha), {'sami-1'});
    });

    testWidgets(
      'a listing deleted while saved leaves Saved skills on refresh',
      (tester) async {
        useSaved({
          _maha: {'sami-1'},
        });
        await _start(tester);
        await _signIn(tester);
        await _openSaved(tester);
        expect(_savedTitles(tester), ['Flutter from zero']);

        await listings.deleteListing(_sami, 'sami-1');
        await tester.fling(
          find.text('Flutter from zero'),
          const Offset(0, 1500),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('No saved skills'), findsOneWidget);
        expect(await saved.fetchSavedIds(_maha), isEmpty);
      },
    );
  });

  group('loading', () {
    testWidgets('when saved listings cannot be loaded, nothing is guessed', (
      tester,
    ) async {
      saved.failFetch = true;
      await _start(tester);
      await _signIn(tester);

      expect(find.text('Could not load skills'), findsOneWidget);
      expect(find.text('Flutter from zero'), findsNothing);

      saved.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_heart('Flutter from zero', saved: false), findsOneWidget);
    });

    testWidgets('Saved skills can be refreshed and retried', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await _openSaved(tester);
      expect(find.text('No saved skills'), findsOneWidget);

      // Saved on another device.
      await saved.save(_maha, 'lina-1');
      saved.failFetch = true;
      await tester.fling(
        find.text('No saved skills'),
        const Offset(0, 1500),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load skills'), findsOneWidget);

      saved.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_savedTitles(tester), ['Calligraphy basics']);
    });
  });
}
