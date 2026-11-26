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
  bool failVisibility = false;
  int saves = 0;

  @override
  Future<ProfileVisibility?> fetchVisibility(String uid) async {
    if (failVisibility) {
      throw const ProfileException('Check your internet connection.');
    }
    return super.fetchVisibility(uid);
  }

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
    // Each test is a new app session.
    MemberService.forgetChecked();
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

    testWidgets('a private location chosen at sign-up stays private on '
        'another device', (tester) async {
      await useProfiles(_Profiles(), publish: false);
      await _start(tester);
      await _signIn(tester, phone: '555555555');
      await tester.enterText(_field('First name'), 'Maha');
      await tester.enterText(_field('Last name'), 'Alzahrani');
      await tester.enterText(_field('Username'), 'maha_new');
      await tester.tap(find.text('Keep my location private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      // Kept with the private profile, not only on this device.
      expect(
        profiles.storedDataOf(_maha),
        allOf(
          containsPair('profileVisible', true),
          containsPair('locationVisible', false),
        ),
      );

      // A new device: nothing saved on it, owned by nobody known.
      await tester.pumpWidget(const SizedBox());
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService.deviceAccount = MemoryDeviceAccountStore();
      await _start(tester);
      await _signIn(tester, phone: '555555555');

      expect(ProfileService().settings.locationVisible, isFalse);
      expect(ProfileService().settings.profileVisible, isTrue);
      await ProfileService().addOfferedSkill('Baking');
      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['skillsOffered'], contains('Baking'));
      expect(shown['city'], '');
    });

    testWidgets(
      'Edit profile explains a bio over the limit and saves nothing',
      (tester) async {
        await _start(tester);
        await _signIn(tester);
        await _openSettings(tester);
        await tester.tap(find.text('Edit profile'));
        await tester.pumpAndSettle();

        await tester.enterText(_field('Bio (optional)'), 'x' * 501);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(
          find.text('Your bio can be at most 500 characters.'),
          findsOneWidget,
        );
        // Still editing (only Edit profile has this field), with nothing
        // changed anywhere.
        expect(_field('Bio (optional)'), findsOneWidget);
        expect(find.text('Profile updated'), findsNothing);
        expect(repository.currentUser.bio, 'Maha teaches.');
        expect(profiles.storedDataOf(_maha)!['bio'], 'Maha teaches.');
        expect(profiles.publicDataOf(_maha)!['bio'], 'Maha teaches.');

        // At the limit, it saves.
        await tester.enterText(_field('Bio (optional)'), 'x' * 500);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.text('Profile updated'), findsOneWidget);
        expect(profiles.publicDataOf(_maha)!['bio'], hasLength(500));
      },
    );

    testWidgets('sign-up explains a name over the limit and creates nothing', (
      tester,
    ) async {
      await useProfiles(_Profiles(), publish: false);
      await _start(tester);
      await _signIn(tester, phone: '555555555');

      await tester.enterText(_field('First name'), 'M' * 51);
      await tester.enterText(_field('Last name'), 'Alzahrani');
      await tester.enterText(_field('Username'), 'maha_new');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(
        find.text('First and last names can be at most 50 characters.'),
        findsOneWidget,
      );
      expect(find.text('About you'), findsOneWidget);
      expect(await profiles.fetchProfile(_maha), isNull);
      expect(profiles.publicDataOf(_maha), isNull);
      expect(profiles.ownerOf('maha_new'), isNull);
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

    testWidgets('stays off when signing in on another device', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await _openSettings(tester);
      await tester.tap(publicSwitch());
      await tester.pumpAndSettle();
      expect(
        profiles.storedDataOf(_maha),
        containsPair('profileVisible', false),
      );

      // A new device: nothing saved on it, owned by nobody known.
      await tester.pumpWidget(const SizedBox());
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService.deviceAccount = MemoryDeviceAccountStore();
      expect(ProfileService().settings.profileVisible, isTrue);
      await _start(tester);
      await _signIn(tester);

      expect(ProfileService().settings.profileVisible, isFalse);
      await _openSettings(tester);
      expect(tester.widget<SwitchListTile>(publicSwitch()).value, isFalse);

      // Editing on the new device does not publish the profile again.
      await ProfileService().addOfferedSkill('Baking');
      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['profileVisible'], isFalse);
      expect(shown['bio'], '');
      expect(shown['skillsOffered'], isEmpty);
    });
  });

  group('choices changed on another device since signing in', () {
    Finder publicSwitch() =>
        find.widgetWithText(SwitchListTile, 'Public profile');

    /// Another device saves Maha's profile with [visibility], while this
    /// one still shows its own, older settings.
    Future<void> changedElsewhere(ProfileVisibility visibility) async =>
        profiles.saveProfile(
          _maha,
          (await profiles.fetchProfile(_maha))!,
          visibility: visibility,
        );

    /// What this device's settings say, to compare.
    (bool, bool) deviceChoices() => (
      ProfileService().settings.profileVisible,
      ProfileService().settings.locationVisible,
    );

    testWidgets('an ordinary edit keeps the profile hidden', (tester) async {
      await _start(tester);
      await _signIn(tester);
      await changedElsewhere(
        const ProfileVisibility(showProfile: false, showLocation: false),
      );
      expect(deviceChoices(), (true, true));

      await ProfileService().addOfferedSkill('Baking');
      await ProfileService().saveProfile(
        ProfileService().currentUser.copyWith(bio: 'A new bio.'),
      );

      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['profileVisible'], isFalse);
      expect(shown['bio'], '');
      expect(shown['skillsOffered'], isEmpty);
      expect(shown['city'], '');
      // The edits are saved, and this device now shows the choices too.
      expect(
        (await profiles.fetchProfile(_maha))!.skillsOffered,
        contains('Baking'),
      );
      expect(deviceChoices(), (false, false));
    });

    testWidgets('changing the location does not make a hidden profile public', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await changedElsewhere(
        const ProfileVisibility(showProfile: false, showLocation: false),
      );

      // As Edit profile saves it, sharing the location again.
      await ProfileService().saveProfile(
        ProfileService().currentUser.copyWith(city: 'Riyadh'),
        locationVisible: true,
      );

      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['profileVisible'], isFalse);
      expect(shown['city'], '');
      expect(
        profiles.storedDataOf(_maha),
        allOf(
          containsPair('profileVisible', false),
          containsPair('locationVisible', true),
        ),
      );
      expect(deviceChoices(), (false, true));
    });

    testWidgets('the Settings switch applies the new choice and keeps the '
        'location as saved online', (tester) async {
      await _start(tester);
      await _signIn(tester);
      // Location made private elsewhere; this device still shares it.
      await changedElsewhere(const ProfileVisibility(showLocation: false));
      await _openSettings(tester);

      await tester.tap(publicSwitch());
      await tester.pumpAndSettle();
      expect(profiles.publicDataOf(_maha)!['profileVisible'], isFalse);
      expect(deviceChoices(), (false, false));

      await tester.tap(publicSwitch());
      await tester.pumpAndSettle();
      final shown = profiles.publicDataOf(_maha)!;
      expect(shown['profileVisible'], isTrue);
      expect(shown['bio'], 'Maha teaches.');
      // Not shared again by this device's older setting.
      expect(shown['city'], '');
      expect(deviceChoices(), (true, false));
      expect(tester.widget<SwitchListTile>(publicSwitch()).value, isTrue);
    });

    testWidgets('if the latest choices cannot be read, nothing is saved', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await changedElsewhere(
        const ProfileVisibility(showProfile: false, showLocation: false),
      );
      profiles
        ..failVisibility = true
        ..saves = 0;
      final before = ProfileService().currentUser.toJson();

      await expectLater(
        ProfileService().addOfferedSkill('Baking'),
        throwsA(isA<ProfileException>()),
      );
      await expectLater(
        ProfileService().updateVisibility(locationVisible: true),
        throwsA(isA<ProfileException>()),
      );

      expect(profiles.saves, 0);
      expect(profiles.publicDataOf(_maha)!['profileVisible'], isFalse);
      expect(ProfileService().currentUser.toJson(), before);
      expect(deviceChoices(), (true, true));
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

  group('members kept from an earlier session', () {
    /// Maha's app has seen Sami; then Sami renames himself to Samir.
    Future<void> seenThenRenamed() async {
      await repository.restore();
      AuthService().signIn();
      await MemberService().loadMembers([_sami]);
      expect(MemberService().nameOf(_sami), 'Sami Alharbi');
      await profiles.saveProfile(
        _sami,
        _samiProfile.copyWith(firstName: 'Samir'),
      );
    }

    /// Closes and reopens Maha's app, as a page refresh does: what is kept
    /// on the device comes back, and a new app session starts.
    Future<void> restart() async {
      final source = repository.dataSource as MemoryDataSource;
      await repository.save();
      final saved = source.snapshot;
      repository.reset();
      source.snapshot = saved;
      await repository.restore();
      MemberService.forgetChecked();
    }

    test(
      'are checked once in a new session, then show their new name',
      () async {
        await seenThenRenamed();
        // Same session: the copy is not asked for again.
        await MemberService().loadMembers([_sami]);
        expect(MemberService().nameOf(_sami), 'Sami Alharbi');
        expect(profiles.fetchesOf(_sami), 1);

        await restart();
        // Shown at once from this device, before anything is fetched.
        expect(MemberService().nameOf(_sami), 'Sami Alharbi');

        await MemberService().loadMembers([_sami]);

        expect(MemberService().nameOf(_sami), 'Samir Alharbi');
        expect(profiles.fetchesOf(_sami), 2);
      },
    );

    test(
      'are checked at most once per session; asking still refetches',
      () async {
        await seenThenRenamed();
        await restart();

        await MemberService().loadMembers([_sami]);
        await MemberService().loadMembers([_sami, _sami]);
        await ListingService().refresh();
        await MemberService().loadMembers([_sami]);
        expect(profiles.fetchesOf(_sami), 2);

        // An explicit refresh is unchanged.
        await MemberService().loadMembers([_sami], refresh: true);
        expect(profiles.fetchesOf(_sami), 3);
      },
    );

    test(
      'keep their copy if the check fails, until the next session',
      () async {
        await seenThenRenamed();
        await restart();
        profiles.failFetch = true;

        await MemberService().loadMembers([_sami]);
        expect(MemberService().nameOf(_sami), 'Sami Alharbi');
        expect(profiles.fetchesOf(_sami), 2);
        // Not asked for again and again in this session, even once back
        // online.
        profiles.failFetch = false;
        await MemberService().loadMembers([_sami]);
        expect(profiles.fetchesOf(_sami), 2);
        expect(MemberService().nameOf(_sami), 'Sami Alharbi');

        await restart();
        await MemberService().loadMembers([_sami]);
        expect(profiles.fetchesOf(_sami), 3);
        expect(MemberService().nameOf(_sami), 'Samir Alharbi');
      },
    );

    test('keep their copy if no longer published, asked for once', () async {
      await seenThenRenamed();
      await profiles.deleteProfile(_sami);
      await restart();

      await MemberService().loadMembers([_sami]);
      await MemberService().loadMembers([_sami]);

      expect(MemberService().nameOf(_sami), 'Sami Alharbi');
      expect(profiles.fetchesOf(_sami), 2);
    });

    test(
      'a member not known yet who failed is still tried every time',
      () async {
        AuthService().signIn();
        profiles.failFetch = true;

        await MemberService().loadMembers([_sami]);
        await MemberService().loadMembers([_sami]);
        expect(MemberService().byId(_sami), isNull);
        expect(profiles.fetchesOf(_sami), 2);

        profiles.failFetch = false;
        await MemberService().loadMembers([_sami]);
        expect(MemberService().nameOf(_sami), 'Sami Alharbi');
        expect(profiles.fetchesOf(_sami), 3);
        // Then known, and checked: not asked for again.
        await MemberService().loadMembers([_sami]);
        expect(profiles.fetchesOf(_sami), 3);
      },
    );

    testWidgets('their profile shows the copy at once, then the new name', (
      tester,
    ) async {
      await seenThenRenamed();
      await restart();
      final slow = profiles.holdFetch = Completer<void>();

      await tester.pumpWidget(
        const MaterialApp(home: PublicMemberProfileScreen(memberId: _sami)),
      );

      // Straight away, without a spinner, while the check runs.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Sami Alharbi'), findsOneWidget);
      expect(profiles.fetchesOf(_sami), 2);

      slow.complete();
      await tester.pumpAndSettle();
      expect(find.text('Samir Alharbi'), findsOneWidget);
      expect(find.text('Sami Alharbi'), findsNothing);
    });

    test('checks made for one account never count for another', () async {
      await seenThenRenamed();
      expect(profiles.fetchesOf(_sami), 1);

      // Lina signs in on the same app, with Sami's copy still here.
      auth.currentUid = _lina;
      await MemberService().loadMembers([_sami]);

      expect(profiles.fetchesOf(_sami), 2);
      expect(MemberService().nameOf(_sami), 'Samir Alharbi');
      // And a check still under way for Lina is not kept for Maha.
      final slow = profiles.holdFetch = Completer<void>();
      final loading = MemberService().loadMembers([_sami], refresh: true);
      auth.currentUid = _maha;
      slow.complete();
      await loading;
      await MemberService().loadMembers([_sami]);
      expect(profiles.fetchesOf(_sami), 4);
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
