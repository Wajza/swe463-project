import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Profiles online; public-profile fetches and saves can be held or fail.
class _Profiles extends DemoProfileRepository {
  _Profiles({super.profiles});

  final List<Set<String>> fetched = [];
  Completer<void>? holdFetch;
  bool failFetch = false;
  Completer<void>? holdSaves;
  bool failSaves = false;
  int saves = 0;

  /// How many fetches asked for [uid].
  int fetchesOf(String uid) => fetched.where((ids) => ids.contains(uid)).length;

  @override
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids) async {
    fetched.add({...uids});
    await holdFetch?.future;
    if (failFetch) throw StateError('offline');
    return super.fetchPublicProfiles(uids);
  }

  @override
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  }) async {
    saves++;
    await holdSaves?.future;
    if (failSaves) {
      throw const ProfileException('Check your internet connection.');
    }
    return super.saveProfile(uid, profile, visibility: visibility);
  }
}

User _user(String first, String last, String username, String phone) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: last,
  username: username,
  phone: phone,
  city: 'Jeddah',
  bio: '$first teaches.',
  isVerified: true,
  skillsOffered: const ['Arabic calligraphy'],
  skillsWanted: const ['Piano'],
  availability: 'Weekends',
);

final _mahaProfile = _user('Maha', 'Alzahrani', 'maha_z', '501234567');
final _samiProfile = _user('Sami', 'Alharbi', 'sami_a', '512345678');

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

Future<void> _start(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, {String phone = '501234567'}) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), phone);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// The owner line of the Home card titled [title].
Finder _ownerOnCard(String title, String owner) => find.descendant(
  of: find.widgetWithText(Card, title),
  matching: find.textContaining(owner),
);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late _Profiles profiles;
  late DemoListingRepository listings;

  Future<void> useProfiles(_Profiles value, {bool publish = true}) async {
    profiles = value;
    if (publish) {
      await profiles.saveProfile(_maha, _mahaProfile);
      await profiles.saveProfile(_sami, _samiProfile);
    }
    AuthService.profiles = profiles;
  }

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    await useProfiles(_Profiles());
    profiles.saves = 0;
    listings = DemoListingRepository(
      documents: {
        'sami-1': _listing(_sami, 'Flutter from zero'),
        'sami-2': _listing(_sami, 'Dart basics'),
        'lina-1': _listing(_lina, 'Calligraphy basics'),
        'maha-1': _listing(_maha, 'Learn Baking'),
      },
    );
    ListingService.repository = listings;
  });

  tearDown(() {
    ListingService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('publishing', () {
    testWidgets('signing up publishes, keeping the location private if asked', (
      tester,
    ) async {
      await useProfiles(_Profiles(), publish: false);
      await _start(tester);
      await _signIn(tester, phone: '555555555');
      expect(find.text('About you'), findsOneWidget);

      await tester.enterText(_field('First name'), 'Maha');
      await tester.enterText(_field('Last name'), 'Alzahrani');
      await tester.enterText(_field('Username'), 'maha_new');
      await tester.tap(find.text('Keep my location private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['username'], 'maha_new');
      expect(shown['city'], '');
      expect(shown.containsKey('phone'), isFalse);
    });

    test('profile and skill changes are published with the profile', () async {
      AuthService().signIn();
      repository.updateUser(_mahaProfile);

      await ProfileService().saveProfile(_mahaProfile.copyWith(bio: 'New bio'));
      await ProfileService().addOfferedSkill('Baking');

      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['bio'], 'New bio');
      expect(shown['skillsOffered'], ['Arabic calligraphy', 'Baking']);
    });

    test('a failed save changes neither profile', () async {
      AuthService().signIn();
      repository.updateUser(_mahaProfile);
      profiles.failSaves = true;

      await expectLater(
        ProfileService().saveProfile(_mahaProfile.copyWith(bio: 'Lost')),
        throwsA(isA<ProfileException>()),
      );

      expect(profiles.publicDataOf(_maha)!['bio'], 'Maha teaches.');
      expect(repository.currentUser.bio, 'Maha teaches.');
    });

    testWidgets('Edit profile publishes the new location choice', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await _openSettings(tester);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep my location private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(profiles.publicDataOf(_maha)!['city'], '');
      expect(ProfileService().settings.locationVisible, isFalse);
      expect(repository.currentUser.city, 'Jeddah');
    });
  });

  group('the Public profile switch', () {
    Finder publicSwitch() =>
        find.widgetWithText(SwitchListTile, 'Public profile');

    testWidgets('saves online first, then changes the setting', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await _openSettings(tester);
      final saving = profiles.holdSaves = Completer<void>();

      await tester.tap(publicSwitch());
      await tester.pump();
      // Not shown as changed until it is saved; more taps are ignored.
      expect(ProfileService().settings.profileVisible, isTrue);
      await tester.tap(publicSwitch());
      await tester.pump();
      expect(profiles.saves, 1);

      saving.complete();
      await tester.pumpAndSettle();
      expect(ProfileService().settings.profileVisible, isFalse);
      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['firstName'], 'Maha');
      expect(shown['username'], 'maha_z');
      expect(shown['bio'], '');
      expect(shown['skillsOffered'], isEmpty);
      expect(shown['city'], '');
    });

    testWidgets('a failure explains itself and leaves everything as it was', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await _openSettings(tester);
      profiles.failSaves = true;

      await tester.tap(publicSwitch());
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(ProfileService().settings.profileVisible, isTrue);
      expect(profiles.publicDataOf(_maha)!['bio'], 'Maha teaches.');
    });
  });

  group('members from public profiles', () {
    testWidgets('listing cards show real owner names once loaded', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);

      expect(_ownerOnCard('Flutter from zero', 'Sami Alharbi'), findsOneWidget);
      // Never published: still shown as a member, without breaking Home.
      expect(_ownerOnCard('Calligraphy basics', 'Member'), findsOneWidget);
      // Fetched once for both of Sami's listings.
      expect(profiles.fetchesOf(_sami), 1);
    });

    testWidgets('known members are not fetched again on refresh', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      expect(profiles.fetchesOf(_sami), 1);

      await ListingService().refresh();
      await tester.pumpAndSettle();
      expect(profiles.fetchesOf(_sami), 1);

      // Only when a refresh is asked for.
      await MemberService().loadMembers([_sami], refresh: true);
      expect(profiles.fetchesOf(_sami), 2);
    });

    testWidgets('a failed member fetch never breaks browsing', (tester) async {
      profiles.failFetch = true;
      await _start(tester);
      await _signIn(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Flutter from zero'), findsOneWidget);
      expect(_ownerOnCard('Flutter from zero', 'Member'), findsOneWidget);
      expect(ListingService.loadState.value.status, ListingLoadStatus.loaded);

      // Tried again next time, and then shown.
      profiles.failFetch = false;
      await ListingService().refresh();
      await tester.pumpAndSettle();
      expect(_ownerOnCard('Flutter from zero', 'Sami Alharbi'), findsOneWidget);
    });

    test('a member already being fetched is not fetched twice', () async {
      AuthService().signIn();
      final slow = profiles.holdFetch = Completer<void>();

      final first = MemberService().loadMembers([_sami]);
      final second = MemberService().loadMembers([_sami, _sami]);
      slow.complete();
      await Future.wait([first, second]);

      expect(profiles.fetchesOf(_sami), 1);
      expect(MemberService().byId(_sami)!.name, 'Sami Alharbi');
    });

    test(
      "the current member is never fetched or stored as someone else",
      () async {
        AuthService().signIn();

        await MemberService().loadMembers([_maha, User.currentUserId]);

        expect(profiles.fetched, isEmpty);
        expect(repository.members.where((m) => m.id == _maha), isEmpty);
        expect(
          MemberService().byId(User.currentUserId),
          repository.currentUser,
        );
      },
    );

    test('members fetched for a previous account are not kept', () async {
      AuthService().signIn();
      final slow = profiles.holdFetch = Completer<void>();
      final loading = MemberService().loadMembers([_sami]);

      auth.currentUid = _lina;
      slow.complete();
      await loading;

      expect(MemberService().byId(_sami), isNull);
    });

    testWidgets(
      "after switching accounts, the previous account is just another member",
      (tester) async {
        await _start(tester);
        await _signIn(tester);
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign out').last);
        await tester.pumpAndSettle();

        auth.currentUid = _sami;
        AuthService.deviceAccount = MemoryDeviceAccountStore(_sami);
        await _signIn(tester, phone: '512345678');

        expect(repository.currentUser.name, 'Sami Alharbi');
        expect(_ownerOnCard('Learn Baking', 'Maha Alzahrani'), findsOneWidget);
        final maha = MemberService().byId(_maha)!;
        expect(maha.id, _maha);
        expect(maha.phone, '');
        expect(repository.members.where((m) => m.id == _sami), isEmpty);
      },
    );

    testWidgets("opening a real member's profile fetches it first", (
      tester,
    ) async {
      AuthService().signIn();
      final slow = profiles.holdFetch = Completer<void>();
      await tester.pumpWidget(
        const MaterialApp(home: PublicMemberProfileScreen(memberId: _sami)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      slow.complete();
      await tester.pumpAndSettle();

      expect(find.text('Sami Alharbi'), findsOneWidget);
      expect(find.text('@sami_a'), findsOneWidget);
      expect(find.textContaining('512345678'), findsNothing);
    });

    testWidgets('a member who does not exist shows Not found', (tester) async {
      AuthService().signIn();
      await tester.pumpWidget(
        const MaterialApp(home: PublicMemberProfileScreen(memberId: _lina)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('not found', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Calligraphy basics'), findsNothing);
    });
  });

  group('older accounts and account deletion', () {
    testWidgets('an account without a public profile gets one at sign-in', (
      tester,
    ) async {
      await useProfiles(
        _Profiles(profiles: {_maha: _mahaProfile}),
        publish: false,
      );
      expect(profiles.publicDataOf(_maha), isNull);

      await _start(tester);
      await _signIn(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(profiles.publicDataOf(_maha)!['username'], 'maha_z');
    });

    testWidgets('a failed migration never stops signing in', (tester) async {
      await useProfiles(
        _Profiles(profiles: {_maha: _mahaProfile}),
        publish: false,
      );
      profiles.failSaves = true;

      await _start(tester);
      await _signIn(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(profiles.publicDataOf(_maha), isNull);
    });

    test(
      'an account already published is not saved again at sign-in',
      () async {
        AuthService().signIn();

        await ProfileService().publishIfMissing();

        expect(profiles.saves, 0);
      },
    );

    test('deleting the account removes its public profile', () async {
      AuthService().signIn();

      await AuthService().deleteAccount();

      expect(profiles.publicDataOf(_maha), isNull);
      expect(profiles.publicDataOf(_sami), isNotNull);
    });
  });

  group('offline demo', () {
    test('demo members work as before, with nothing fetched', () async {
      AuthService.profiles = null;

      await MemberService().loadMembers(['m-sami', 'someone']);

      expect(MemberService().nameOf('m-sami'), 'Sami Alharbi');
      expect(MemberService().nameOf('someone'), 'Member');
      expect(profiles.fetched, isEmpty);
    });

    testWidgets('a demo member profile opens straight away', (tester) async {
      AuthService.profiles = null;
      await tester.pumpWidget(
        const MaterialApp(home: PublicMemberProfileScreen(memberId: 'm-sami')),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Sami Alharbi'), findsOneWidget);
    });
  });
}
