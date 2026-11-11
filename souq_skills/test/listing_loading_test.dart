import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _noura = 'uid-noura';
const _omar = 'uid-omar';

/// The offline sign-in with a Firebase-like uid that can change, as when a
/// different account signs in.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Stands in for Firestore; loading can be held back or made to fail.
class _Remote extends DemoListingRepository {
  _Remote({super.documents});

  bool fail = false;
  Completer<void>? hold;
  int fetches = 0;

  @override
  Future<List<SkillListing>> fetchListings({String? uid}) async {
    fetches++;
    final waitFor = hold;
    await waitFor?.future;
    if (fail) throw const ListingException('Check your internet connection.');
    return super.fetchListings(uid: uid);
  }
}

Map<String, dynamic> _listing(
  String owner,
  String title, {
  String category = 'Cooking',
  String offers = 'Baking',
  String wants = 'Piano',
  String city = 'Riyadh',
  bool onlineOnly = false,
  bool womenOnly = false,
  bool isPaused = false,
}) => {
  'ownerId': owner,
  'category': category,
  'title': title,
  'offers': offers,
  'wants': wants,
  'distance': '',
  'description': '$title, in full.',
  'city': city,
  'availability': 'Weekends',
  'sessionsMinutes': 60,
  'onlineOnly': onlineOnly,
  'womenOnly': womenOnly,
  'isPaused': isPaused,
};

/// Each search and filter below matches exactly one of the others' listings.
Map<String, Map<String, dynamic>> _documents() => {
  'maha-1': _listing(_maha, 'Learn Baking'),
  'maha-2': _listing(_maha, 'Learn Oud', offers: 'Oud lessons', isPaused: true),
  'sami-1': _listing(
    _sami,
    'Flutter from zero',
    category: 'Technology',
    offers: 'Flutter',
    onlineOnly: true,
  ),
  'lina-1': _listing(
    _lina,
    'Calligraphy basics',
    category: 'Design',
    offers: 'Arabic calligraphy',
    wants: 'Baking',
    city: 'Jeddah',
    womenOnly: true,
  ),
  'noura-1': _listing(
    _noura,
    'Morning yoga',
    category: 'Fitness',
    offers: 'Yoga',
    wants: 'Photography',
    city: 'Dammam',
  ),
  'omar-1': _listing(_omar, 'Paused cooking class', isPaused: true),
};

/// Far enough to pull to refresh on the tall test screen: the pull needed
/// grows with the list's height.
const _pullDown = Offset(0, 1500);

const _othersActive = [
  'Flutter from zero',
  'Calligraphy basics',
  'Morning yoga',
];

Future<void> _start(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
}

/// Signs in from the welcome screen and waits on Home.
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
    // A spinner never settles, so step past the page transition.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out').last);
  await tester.pumpAndSettle();
}

Future<void> _openMyListings(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('My listings'));
  await tester.pumpAndSettle();
}

Future<void> _filter(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip('Filter'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
  await tester.tapAt(const Offset(400, 10));
  await tester.pumpAndSettle();
}

/// The listing titles Home shows.
List<String> _homeTitles(WidgetTester tester) => [
  for (final title in [
    ..._othersActive,
    'Learn Baking',
    'Learn Oud',
    'Paused cooking class',
  ])
    if (find
        .descendant(of: find.byType(HomeScreen), matching: find.text(title))
        .evaluate()
        .isNotEmpty)
      title,
];

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late _Remote remote;

  setUp(() {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    remote = _Remote(documents: _documents());
    ListingService.repository = remote;
  });

  tearDown(() {
    ListingService.repository = null;
    AuthService.repository = originalAuth;
  });

  group('loading', () {
    testWidgets("Home shows others' active listings once loaded", (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);

      expect(_homeTitles(tester), _othersActive);
      // The device holds exactly the shared listings: no samples, no copies.
      expect(
        repository.listings.map((item) => item.id),
        unorderedEquals(_documents().keys),
      );
      expect(find.text('Build your first Flutter app'), findsNothing);
      expect(ListingService.loadState.value.status, ListingLoadStatus.loaded);
    });

    testWidgets('shows only a spinner until the listings arrive', (
      tester,
    ) async {
      final loading = remote.hold = Completer<void>();
      await _start(tester);
      await _signIn(tester, settle: false);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      // Sample listings already on the device are not shown meanwhile.
      expect(find.text('Build your first Flutter app'), findsNothing);
      expect(find.text('No skills yet'), findsNothing);

      loading.complete();
      await tester.pumpAndSettle();
      expect(_homeTitles(tester), _othersActive);
    });

    testWidgets('a failed load explains itself and can be retried', (
      tester,
    ) async {
      remote.fail = true;
      await _start(tester);
      await _signIn(tester);

      expect(find.text('Could not load skills'), findsOneWidget);
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Build your first Flutter app'), findsNothing);
      expect(find.text('No skills yet'), findsNothing);

      remote.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load skills'), findsNothing);
      expect(_homeTitles(tester), _othersActive);
    });

    testWidgets('no shared listings shows an empty state', (tester) async {
      ListingService.repository = _Remote();
      await _start(tester);
      await _signIn(tester);

      expect(find.text('No skills yet'), findsOneWidget);
      expect(find.text('Build your first Flutter app'), findsNothing);
      expect(repository.listings, isEmpty);
    });

    testWidgets('pulling down shows a listing added elsewhere', (tester) async {
      await _start(tester);
      await _signIn(tester);
      expect(find.text('Saudi coffee'), findsNothing);

      await remote.createListing(
        _noura,
        const SkillListing(
          ownerId: _noura,
          category: 'Cooking',
          title: 'Saudi coffee',
          offers: 'Coffee making',
          wants: 'Yoga',
        ),
      );
      await tester.fling(find.text('Skills for you'), _pullDown, 1000);
      await tester.pumpAndSettle();

      expect(find.text('Saudi coffee'), findsOneWidget);
      expect(remote.fetches, 2);
      expect(repository.listings, hasLength(_documents().length + 1));
    });

    testWidgets('a refresh drops listings deleted elsewhere', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await remote.deleteListing(_sami, 'sami-1');

      await tester.fling(find.text('Skills for you'), _pullDown, 1000);
      await tester.pumpAndSettle();

      expect(find.text('Flutter from zero'), findsNothing);
      expect(ListingService().byId('sami-1'), isNull);
    });

    testWidgets('loading leaves group trades alone', (tester) async {
      final groupsBefore = GroupTradeService().all().map((g) => g.id).toList();
      await _start(tester);
      await _signIn(tester);

      expect(GroupTradeService().all().map((g) => g.id), groupsBefore);
    });

    testWidgets('a saved heart survives a refresh', (tester) async {
      await _start(tester);
      await _signIn(tester);
      ListingService().toggleSaved('lina-1');

      await ListingService().refresh();

      expect(ListingService().byId('lina-1')!.isSaved, isTrue);
      expect(ListingService().byId('sami-1')!.isSaved, isFalse);
    });
  });

  group('ownership', () {
    testWidgets(
      "own listings, paused included, are in My listings, others' are not",
      (tester) async {
        await _start(tester);
        await _signIn(tester);

        // The uid is shown as 'me' by the repository, not by the screens.
        expect(ListingService().byId('maha-1')!.ownerId, User.currentUserId);
        expect(ListingService().byId('sami-1')!.ownerId, _sami);
        // Home leaves out my own and paused listings.
        expect(_homeTitles(tester), isNot(contains('Learn Baking')));
        expect(_homeTitles(tester), isNot(contains('Paused cooking class')));

        await _openMyListings(tester);
        expect(find.text('Learn Baking'), findsOneWidget);
        expect(find.text('Learn Oud'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);
        expect(find.text('Flutter from zero'), findsNothing);
        expect(find.text('Paused cooking class'), findsNothing);
      },
    );

    testWidgets('My listings has its own empty and error states', (
      tester,
    ) async {
      ListingService.repository = _Remote(
        documents: {'sami-1': _documents()['sami-1']!},
      );
      await _start(tester);
      await _signIn(tester);
      await _openMyListings(tester);
      expect(find.text('No listings yet'), findsOneWidget);

      final failing = _Remote(documents: _documents())..fail = true;
      ListingService.repository = failing;
      await ListingService().refresh();
      await tester.pumpAndSettle();
      expect(find.text('Could not load skills'), findsOneWidget);
      expect(find.text('No listings yet'), findsNothing);

      failing.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Learn Baking'), findsOneWidget);
    });

    testWidgets(
      "another account never sees the previous account's listings as its own",
      (tester) async {
        await _start(tester);
        await _signIn(tester);
        await _signOut(tester);

        auth.currentUid = _sami;
        await _signIn(tester);

        // Maha's listing is now someone else's, and Sami's own is not on Home.
        expect(ListingService().byId('maha-1')!.ownerId, _maha);
        expect(ListingService().byId('sami-1')!.ownerId, User.currentUserId);
        expect(_homeTitles(tester), contains('Learn Baking'));
        expect(_homeTitles(tester), isNot(contains('Flutter from zero')));

        await _openMyListings(tester);
        expect(find.text('Flutter from zero'), findsOneWidget);
        expect(find.text('Learn Baking'), findsNothing);
        expect(find.text('Learn Oud'), findsNothing);
      },
    );

    test("a load that finishes after switching accounts is ignored", () async {
      final slow = remote.hold = Completer<void>();
      final first = ListingService().refresh();

      // Another account signs in while the first load is still running.
      auth.currentUid = _sami;
      remote.hold = null;
      await ListingService().refresh();
      expect(ListingService().byId('sami-1')!.ownerId, User.currentUserId);

      slow.complete();
      await first;
      expect(ListingService().byId('sami-1')!.ownerId, User.currentUserId);
      expect(ListingService().byId('maha-1')!.ownerId, _maha);
      expect(ListingService.loadState.value.status, ListingLoadStatus.loaded);
    });

    testWidgets('before loading for a new account, nothing is shown', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await _signOut(tester);

      auth.currentUid = _sami;
      final loading = remote.hold = Completer<void>();
      await _signIn(tester, settle: false);

      // Maha's listings are still on the device, but not shown to Sami.
      expect(_homeTitles(tester), isEmpty);
      loading.complete();
      await tester.pumpAndSettle();
      expect(_homeTitles(tester), contains('Learn Baking'));
    });
  });

  group('changed elsewhere', () {
    test('editing a listing deleted elsewhere removes it here', () async {
      await ListingService().refresh();
      await remote.deleteListing(_maha, 'maha-1');

      await expectLater(
        ListingService().update(
          ListingService().byId('maha-1')!.copyWith(title: 'Changed'),
        ),
        throwsA(
          isA<ListingException>().having(
            (error) => error.message,
            'message',
            ListingException.notFound.message,
          ),
        ),
      );
      expect(ListingService().byId('maha-1'), isNull);
    });

    test('deleting a listing already deleted elsewhere succeeds', () async {
      await ListingService().refresh();
      await remote.deleteListing(_maha, 'maha-1');

      await ListingService().delete('maha-1');

      expect(ListingService().byId('maha-1'), isNull);
    });

    testWidgets('a listing removed by a refresh shows Not found', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(find.text('Flutter from zero'));
      await tester.pumpAndSettle();
      expect(find.text('Listing details'), findsOneWidget);

      await remote.deleteListing(_sami, 'sami-1');
      await ListingService().refresh();
      await tester.pumpAndSettle();

      expect(find.text('Listing details'), findsNothing);
      expect(
        find.textContaining('not found', findRichText: true),
        findsWidgets,
      );
    });
  });

  group('search and filters on loaded listings', () {
    testWidgets('search matches title, offered and wanted skill', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      final search = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(TextField),
      );

      await tester.enterText(search, 'flutter');
      await tester.pump();
      expect(_homeTitles(tester), ['Flutter from zero']);

      await tester.enterText(search, 'CALLIGRAPHY');
      await tester.pump();
      expect(_homeTitles(tester), ['Calligraphy basics']);

      await tester.enterText(search, 'photography');
      await tester.pump();
      expect(_homeTitles(tester), ['Morning yoga']);

      await tester.enterText(search, 'nothing like this');
      await tester.pump();
      expect(find.text('No skills match'), findsOneWidget);
    });

    for (final (filter, expected) in [
      ('Design', 'Calligraphy basics'),
      ('Jeddah', 'Calligraphy basics'),
      ('Dammam', 'Morning yoga'),
      ('Online only', 'Flutter from zero'),
      ('Women only', 'Calligraphy basics'),
    ]) {
      testWidgets('the $filter filter applies to loaded listings', (
        tester,
      ) async {
        await _start(tester);
        await _signIn(tester);

        await _filter(tester, filter);

        expect(_homeTitles(tester), [expected]);
      });
    }
  });
}
