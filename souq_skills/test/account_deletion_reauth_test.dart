import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/blocked_members_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/safety_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _phone = '501234567';
const _wrongCode = '654321';

/// Sign-in that, like Firebase, needs the phone number verified again
/// before the account can be deleted.
class _Auth extends DemoAuthRepository {
  _Auth()
    : super(
        isKnownPhone: AuthService().isKnownPhone,
        requiresReauthentication: true,
      );

  String? currentUid = _maha;
  AuthException? sendFailure;
  final List<String> codesSentTo = [];
  int reauthentications = 0;
  int deletions = 0;

  @override
  String? get uid => currentUid;

  @override
  Future<void> sendReauthenticationCode(String phoneNumber) async {
    if (sendFailure case final failure?) throw failure;
    codesSentTo.add(phoneNumber);
  }

  @override
  Future<void> reauthenticate(String smsCode) async {
    await super.reauthenticate(smsCode);
    reauthentications++;
  }

  @override
  Future<void> deleteAccount() async {
    deletions++;
    await super.deleteAccount();
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

User _profile(String username, String phone) => User(
  id: User.currentUserId,
  firstName: 'Yara',
  lastName: 'Alghamdi',
  username: username,
  phone: phone,
  isVerified: true,
);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  final originalClock = AuthService.clock;
  late _Auth auth;
  late DemoProfileRepository profiles;
  late DemoListingRepository listings;
  late DemoSavedListingsRepository saved;
  late DemoBlockedMembersRepository blocked;

  /// Everything online that deleting the account would remove.
  Future<Map<String, Object?>> accountData() async => {
    'listings': {
      for (final item in await listings.fetchListings())
        if (listings.storedData(item.id)!['ownerId'] == _maha) item.id,
    },
    'saved': await saved.fetchSavedIds(_maha),
    'blocked': await blocked.fetchBlockedIds(_maha),
    'profile': (await profiles.fetchProfile(_maha))?.username,
    'username': profiles.ownerOf('yara'),
    'publicProfile': profiles.publicDataOf(_maha)?['username'],
  };

  late Map<String, Object?> before;

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    profiles = DemoProfileRepository();
    await profiles.saveProfile(_maha, _profile('yara', _phone));
    await profiles.saveProfile(_sami, _profile('sami_a', '512345678'));
    AuthService.profiles = profiles;
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    listings = DemoListingRepository(
      documents: {
        'maha-1': _listing(_maha, 'Learn Baking'),
        'maha-2': _listing(_maha, 'Learn Oud'),
        'sami-1': _listing(_sami, 'Flutter from zero'),
      },
    );
    ListingService.repository = listings;
    saved = DemoSavedListingsRepository(
      saved: {
        _maha: {'sami-1'},
      },
    );
    ListingService.savedRepository = saved;
    blocked = DemoBlockedMembersRepository(
      blocked: {
        _maha: {_sami},
      },
    );
    SafetyService.repository = blocked;
    await ListingService().refresh();
    AuthService().signIn();
    before = await accountData();
    expect(before, {
      'listings': {'maha-1', 'maha-2'},
      'saved': {'sami-1'},
      'blocked': {_sami},
      'profile': 'yara',
      'username': _maha,
      'publicProfile': 'yara',
    });
  });

  tearDown(() {
    AuthService.clock = originalClock;
    ListingService.repository = null;
    ListingService.savedRepository = null;
    SafetyService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('the service', () {
    test(
      'refuses to delete anything before the phone is verified again',
      () async {
        expect(AuthService().needsIdentityCheck, isTrue);

        await expectLater(
          AuthService().deleteAccount(),
          throwsA(same(AuthService.identityCheckRequired)),
        );

        expect(await accountData(), before);
        expect(auth.deletions, 0);
        expect(repository.hasAccount, isTrue);
        expect(AuthService().isSignedIn, isTrue);
      },
    );

    test(
      'a wrong code leaves the member signed in and deletes nothing',
      () async {
        await AuthService().sendIdentityCode();

        await expectLater(
          AuthService().confirmIdentity(_wrongCode),
          throwsA(isA<AuthException>()),
        );
        expect(AuthService().needsIdentityCheck, isTrue);
        await expectLater(
          AuthService().deleteAccount(),
          throwsA(same(AuthService.identityCheckRequired)),
        );

        expect(await accountData(), before);
        expect(auth.deletions, 0);
        expect(AuthService().isSignedIn, isTrue);
        expect(repository.currentUser.username, 'yara');
      },
    );

    test('once verified, the account is deleted as before', () async {
      await AuthService().sendIdentityCode();
      expect(auth.codesSentTo, ['+966$_phone']);
      await AuthService().confirmIdentity(DemoAuthRepository.demoCode);
      expect(AuthService().needsIdentityCheck, isFalse);

      await AuthService().deleteAccount();

      expect(await accountData(), {
        'listings': <String>{},
        'saved': <String>{},
        'blocked': <String>{},
        'profile': null,
        'username': null,
        'publicProfile': null,
      });
      // Other members' data is left alone.
      expect(listings.storedData('sami-1'), isNotNull);
      expect(profiles.publicDataOf(_sami), isNotNull);
      expect(auth.deletions, 1);
      expect(repository.hasAccount, isFalse);
      expect(repository.isSignedIn, isFalse);
      // A later deletion needs a new check.
      expect(AuthService().needsIdentityCheck, isTrue);
    });

    test('a check only counts for a few minutes', () async {
      var now = DateTime(2026, 11, 11, 12);
      AuthService.clock = () => now;
      await AuthService().confirmIdentity(DemoAuthRepository.demoCode);

      now = now.add(AuthService.identityCheckWindow);
      expect(AuthService().needsIdentityCheck, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(AuthService().needsIdentityCheck, isTrue);
      await expectLater(
        AuthService().deleteAccount(),
        throwsA(same(AuthService.identityCheckRequired)),
      );
      expect(await accountData(), before);
    });

    test('a check only counts for the account that passed it', () async {
      await AuthService().confirmIdentity(DemoAuthRepository.demoCode);

      auth.currentUid = _lina;
      expect(AuthService().needsIdentityCheck, isTrue);
      auth.currentUid = _maha;
      await AuthService().signOut();
      expect(AuthService().needsIdentityCheck, isTrue);
    });

    test('the offline demo deletes without a check, as before', () async {
      AuthService.repository = DemoAuthRepository(
        isKnownPhone: AuthService().isKnownPhone,
      );
      ListingService.repository = null;
      ListingService.savedRepository = null;
      SafetyService.repository = null;
      AuthService.profiles = null;

      expect(AuthService().needsIdentityCheck, isFalse);
      await AuthService().deleteAccount();
      expect(repository.hasAccount, isFalse);
    });
  });

  group('from Settings', () {
    Future<void> startDeleting(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(800, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.isSignedIn = false;
      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), _phone);
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

    Future<void> enterCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for the phone number again, then deletes', (
      tester,
    ) async {
      await startDeleting(tester);

      // Nothing is deleted while the code is being asked for.
      expect(find.text('Verify phone'), findsOneWidget);
      expect(
        find.text('Enter the 6-digit code sent to +966 $_phone.'),
        findsOne,
      );
      expect(auth.codesSentTo, ['+966$_phone']);
      expect(await accountData(), before);

      await enterCode(tester, DemoAuthRepository.demoCode);

      expect(find.text('Get started'), findsOneWidget);
      expect(auth.reauthentications, 1);
      expect(auth.deletions, 1);
      expect((await accountData())['listings'], isEmpty);
      expect(profiles.ownerOf('yara'), isNull);
    });

    testWidgets(
      'a wrong code keeps the member signed in, with nothing deleted',
      (tester) async {
        await startDeleting(tester);

        await enterCode(tester, _wrongCode);

        expect(find.text('That code is not correct.'), findsOneWidget);
        expect(find.text('Verify phone'), findsOneWidget);
        expect(await accountData(), before);
        expect(auth.deletions, 0);
        expect(AuthService().isSignedIn, isTrue);

        // Going back cancels; the member is still in Settings.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Delete account'), findsOneWidget);
        expect(await accountData(), before);
        expect(auth.deletions, 0);
        expect(AuthService().isSignedIn, isTrue);
      },
    );

    testWidgets('going back from the code cancels the deletion', (
      tester,
    ) async {
      await startDeleting(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Get started'), findsNothing);
      expect(await accountData(), before);
      expect(auth.reauthentications, 0);
      expect(auth.deletions, 0);
      expect(repository.hasAccount, isTrue);
      expect(AuthService().isSignedIn, isTrue);
    });

    testWidgets('if the code cannot be sent, nothing is deleted', (
      tester,
    ) async {
      auth.sendFailure = const AuthException('Check your internet connection.');

      await startDeleting(tester);

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Verify phone'), findsNothing);
      expect(find.text('Delete account'), findsOneWidget);
      expect(await accountData(), before);
      expect(auth.deletions, 0);
      expect(AuthService().isSignedIn, isTrue);
    });
  });
}
