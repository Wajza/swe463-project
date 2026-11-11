import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _offline = ListingException('Check your internet connection.');

/// The offline sign-in with a Firebase-like uid, counting account deletions.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  int deletions = 0;

  @override
  String? get uid => _maha;

  @override
  Future<void> deleteAccount() async {
    deletions++;
    await super.deleteAccount();
  }
}

/// Listings online; deleting all of an owner's can fail, optionally after
/// deleting one of them, as an interrupted run would.
class _Listings extends DemoListingRepository {
  _Listings({super.documents});

  bool fail = false;
  bool failAfterOne = false;

  @override
  Future<void> deleteAllListingsOf(String uid) async {
    if (failAfterOne) {
      final mine = (await fetchListings(uid: uid))
          .where((item) => item.ownerId == User.currentUserId);
      await deleteListing(uid, mine.first.id);
      throw _offline;
    }
    if (fail) throw _offline;
    return super.deleteAllListingsOf(uid);
  }
}

class _Saved extends DemoSavedListingsRepository {
  _Saved({super.saved});

  bool fail = false;

  @override
  Future<void> unsaveAll(String uid) async {
    if (fail) throw _offline;
    return super.unsaveAll(uid);
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

User _profile(String username) => User(
  id: User.currentUserId,
  firstName: 'Yara',
  lastName: 'Alghamdi',
  username: username,
  phone: '501234567',
  isVerified: true,
);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late DemoProfileRepository profiles;
  late _Listings listings;
  late _Saved saved;

  Future<Set<String>> remainingListingIds() async => {
    for (final item in await listings.fetchListings()) item.id,
  };

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    profiles = DemoProfileRepository();
    await profiles.saveProfile(_maha, _profile('yara'));
    await profiles.saveProfile(_sami, _profile('sami_a'));
    AuthService.profiles = profiles;
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    listings = _Listings(
      documents: {
        'maha-1': _listing(_maha, 'Learn Baking'),
        'maha-2': _listing(_maha, 'Learn Oud'),
        'sami-1': _listing(_sami, 'Flutter from zero'),
        'lina-1': _listing(_lina, 'Calligraphy basics'),
      },
    );
    ListingService.repository = listings;
    saved = _Saved(
      saved: {
        _maha: {'sami-1', 'lina-1'},
        _sami: {'maha-1', 'lina-1'},
      },
    );
    ListingService.savedRepository = saved;
    await ListingService().refresh();
    AuthService().signIn();
  });

  tearDown(() {
    ListingService.repository = null;
    ListingService.savedRepository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('a successful deletion', () {
    test("removes only this account's listings", () async {
      final othersBefore = {
        'sami-1': listings.storedData('sami-1'),
        'lina-1': listings.storedData('lina-1'),
      };

      await AuthService().deleteAccount();

      expect(await remainingListingIds(), {'sami-1', 'lina-1'});
      expect(listings.storedData('sami-1'), othersBefore['sami-1']);
      expect(listings.storedData('lina-1'), othersBefore['lina-1']);
      // The device no longer shows them either.
      expect(ListingService().mine(), isEmpty);
    });

    test("removes only this account's saved listings", () async {
      await AuthService().deleteAccount();

      expect(await saved.fetchSavedIds(_maha), isEmpty);
      // Others keep theirs, even when they saved a listing of this account.
      expect(await saved.fetchSavedIds(_sami), {'maha-1', 'lina-1'});
      expect(
        ListingService().byId('sami-1')!.isSaved,
        isFalse,
        reason: 'no hearts of the deleted account stay on the device',
      );
    });

    test('then removes the profile, username and sign-in account', () async {
      await AuthService().deleteAccount();

      expect(await profiles.fetchProfile(_maha), isNull);
      expect(profiles.ownerOf('yara'), isNull);
      expect(await profiles.fetchProfile(_sami), isNotNull);
      expect(auth.deletions, 1);
      expect(repository.isSignedIn, isFalse);
    });
  });

  group('a failed cleanup', () {
    Future<void> expectStopped() async {
      await expectLater(
        AuthService().deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('account was not deleted'),
              contains('Check your internet connection.'),
            ),
          ),
        ),
      );
      // Nothing after the cleanup has happened.
      expect(await profiles.fetchProfile(_maha), isNotNull);
      expect(profiles.ownerOf('yara'), _maha);
      expect(auth.deletions, 0);
      expect(repository.isSignedIn, isTrue);
    }

    test('of listings stops before anything else is deleted', () async {
      listings.fail = true;

      await expectStopped();

      expect(await remainingListingIds(), hasLength(4));
      expect(await saved.fetchSavedIds(_maha), {'sami-1', 'lina-1'});
    });

    test('of saved listings stops before the profile and account', () async {
      saved.fail = true;

      await expectStopped();

      expect(await saved.fetchSavedIds(_maha), {'sami-1', 'lina-1'});
    });

    test('part-way through can be finished by trying again', () async {
      listings.failAfterOne = true;

      await expectStopped();
      expect(await remainingListingIds(), hasLength(3));

      listings.failAfterOne = false;
      await AuthService().deleteAccount();

      expect(await remainingListingIds(), {'sami-1', 'lina-1'});
      expect(await saved.fetchSavedIds(_maha), isEmpty);
      expect(await profiles.fetchProfile(_maha), isNull);
      expect(auth.deletions, 1);
    });
  });

  group('from Settings', () {
    Future<void> deleteFromSettings(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(800, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.isSignedIn = false;
      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '501234567');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }

    testWidgets('a failure is explained and the member stays signed in', (
      tester,
    ) async {
      listings.fail = true;

      await deleteFromSettings(tester);

      expect(find.textContaining('account was not deleted'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Get started'), findsNothing);
      expect(auth.deletions, 0);
    });

    testWidgets('a success returns to the welcome screen', (tester) async {
      await deleteFromSettings(tester);

      expect(find.text('Get started'), findsOneWidget);
      expect(await remainingListingIds(), {'sami-1', 'lina-1'});
      expect(auth.deletions, 1);
    });
  });

  group('offline demo', () {
    test('deleting the account works as before', () async {
      ListingService.repository = null;
      ListingService.savedRepository = null;
      AuthService.profiles = null;
      final localBefore = repository.listings.length;

      await AuthService().deleteAccount();

      expect(repository.hasAccount, isFalse);
      expect(repository.isSignedIn, isFalse);
      expect(auth.deletions, 1);
      // Nothing online to clean up, and the device data is left as before.
      expect(repository.listings, hasLength(localBefore));
    });
  });
}
