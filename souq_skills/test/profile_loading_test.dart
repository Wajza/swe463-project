import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/trade_service.dart';

import 'support/memory_data_source.dart';

/// The demo signs every account in as 'me'.
const _uid = 'me';

const _maha = User(
  id: User.currentUserId,
  firstName: 'Maha',
  lastName: 'Alzahrani',
  username: 'maha_z',
  city: 'Jeddah',
  phone: '512345678',
  isVerified: true,
);

class _FailingProfiles implements ProfileRepository {
  @override
  Future<User?> fetchProfile(String uid) async =>
      throw const ProfileException('Check your internet connection.');

  @override
  Future<ProfileVisibility?> fetchVisibility(String uid) async =>
      throw const ProfileException('Check your internet connection.');

  @override
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  }) async {}

  @override
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids) async =>
      const {};

  @override
  Future<void> deleteProfile(String uid) async {}
}

/// Has the profile, but its sharing choices cannot be read.
class _UnreadableChoices extends DemoProfileRepository {
  _UnreadableChoices() : super(profiles: {_uid: _maha});

  @override
  Future<ProfileVisibility?> fetchVisibility(String uid) async =>
      throw const ProfileException('Check your internet connection.');
}

const _hidden = ProfileVisibility(showProfile: false, showLocation: false);

/// The device's current sharing choices, to compare.
(bool, bool) _deviceChoices() => (
  Repository.instance.settings.profileVisible,
  Repository.instance.settings.locationVisible,
);

/// What [profiles] publishes for the account, to check nothing leaked.
Map<String, dynamic> _published(DemoProfileRepository profiles) =>
    profiles.publicDataOf(_uid)!;

class _RecordingAuth extends DemoAuthRepository {
  _RecordingAuth() : super(isKnownPhone: AuthService().isKnownPhone);

  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;
}

Future<void> _verify(WidgetTester tester, String phone) async {
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), phone);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late MemoryDataSource source;
  late MemoryDeviceAccountStore deviceAccount;

  setUp(() {
    source = MemoryDataSource();
    repository
      ..dataSource = source
      ..reset();
    deviceAccount = MemoryDeviceAccountStore();
    AuthService.deviceAccount = deviceAccount;
  });

  tearDown(() {
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('after sign-in', () {
    testWidgets('an existing profile is loaded and opens Home', (tester) async {
      AuthService.profiles = DemoProfileRepository(profiles: {_uid: _maha});

      await _verify(tester, '512345678');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(ProfileService().currentUser.toJson(), _maha.toJson());
      expect(AuthService().isSignedIn, isTrue);
    });

    testWidgets('another account never sees the saved data', (tester) async {
      // The device holds the demo member's trades, owned by nobody known.
      expect(TradeService().all(), isNotEmpty);
      AuthService.profiles = DemoProfileRepository(profiles: {_uid: _maha});

      await _verify(tester, '512345678');

      expect(ProfileService().currentUser.name, 'Maha Alzahrani');
      expect(TradeService().all(), isEmpty);
      expect(await deviceAccount.read(), _uid);
    });

    testWidgets('the same account keeps its saved data', (tester) async {
      await deviceAccount.write(_uid);
      final updated = repository.currentUser.copyWith(bio: 'From Firestore');
      AuthService.profiles = DemoProfileRepository(profiles: {_uid: updated});

      await _verify(tester, '501234567');

      expect(ProfileService().currentUser.bio, 'From Firestore');
      expect(TradeService().all(), isNotEmpty);
    });

    testWidgets('a missing profile goes to account creation', (tester) async {
      AuthService.profiles = DemoProfileRepository();
      final before = repository.currentUser.toJson();

      await _verify(tester, '512345678');

      expect(find.text('About you'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(repository.currentUser.toJson(), before);
      expect(repository.isSignedIn, isFalse);
    });

    testWidgets('a loading failure keeps the member out safely', (
      tester,
    ) async {
      final auth = _RecordingAuth();
      AuthService.repository = auth;
      AuthService.profiles = _FailingProfiles();
      final before = repository.currentUser.toJson();

      await _verify(tester, '512345678');

      expect(find.text('Verify phone'), findsOneWidget);
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(repository.currentUser.toJson(), before);
      expect(repository.isSignedIn, isFalse);
      expect(auth.signOuts, 1);
    });
  });

  group('sharing choices at sign-in', () {
    testWidgets('a new device restores a hidden profile, so an edit keeps it '
        'hidden', (tester) async {
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_uid, _maha, visibility: _hidden);
      AuthService.profiles = profiles;
      // A fresh start shares everything.
      expect(_deviceChoices(), (true, true));

      await _verify(tester, '512345678');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_deviceChoices(), (false, false));

      // The first edit used to publish the profile again.
      await ProfileService().addOfferedSkill('Baking');

      expect(_published(profiles)['profileVisible'], isFalse);
      expect(_published(profiles)['city'], '');
      expect(_published(profiles)['skillsOffered'], isEmpty);
      expect(
        (await profiles.fetchProfile(_uid))!.skillsOffered,
        contains('Baking'),
      );
      expect(
        profiles.storedDataOf(_uid),
        allOf(
          containsPair('profileVisible', false),
          containsPair('locationVisible', false),
        ),
      );
    });

    testWidgets('a private location is restored and stays private', (
      tester,
    ) async {
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(
        _uid,
        _maha,
        visibility: const ProfileVisibility(showLocation: false),
      );
      AuthService.profiles = profiles;

      await _verify(tester, '512345678');

      expect(_deviceChoices(), (true, false));
      await ProfileService().saveProfile(
        ProfileService().currentUser.copyWith(bio: 'Teaches calligraphy.'),
      );
      expect(_published(profiles)['bio'], 'Teaches calligraphy.');
      expect(_published(profiles)['city'], '');
    });

    testWidgets("another account on this device gets its own choices, not "
        "the last account's", (tester) async {
      // The previous account on this device kept its profile hidden.
      await deviceAccount.write('uid-previous');
      repository.updateSettings(
        repository.settings.copyWith(
          profileVisible: false,
          locationVisible: false,
        ),
      );
      // This account shares its profile but not its location: neither the
      // last account's choices nor a fresh start's defaults.
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(
        _uid,
        _maha,
        visibility: const ProfileVisibility(showLocation: false),
      );
      AuthService.profiles = profiles;

      await _verify(tester, '512345678');

      expect(_deviceChoices(), (true, false));
      expect(await deviceAccount.read(), _uid);
    });

    testWidgets("the same account's stale choices on this device are "
        'replaced; other settings stay', (tester) async {
      await deviceAccount.write(_uid);
      repository.updateSettings(repository.settings.copyWith(darkMode: true));
      final profiles = DemoProfileRepository();
      // Hidden from another device since.
      await profiles.saveProfile(
        _uid,
        repository.currentUser,
        visibility: _hidden,
      );
      AuthService.profiles = profiles;

      await _verify(tester, '501234567');

      expect(_deviceChoices(), (false, false));
      expect(repository.settings.darkMode, isTrue);
      expect(TradeService().all(), isNotEmpty);
    });

    testWidgets('an older account keeps what its public profile shows', (
      tester,
    ) async {
      final profiles = DemoProfileRepository(
        profiles: {_uid: _maha},
        publicProfiles: {
          _uid: ProfileDocument.toPublicData(
            _uid,
            _maha,
            _hidden,
            isVerified: true,
          ),
        },
      );
      AuthService.profiles = profiles;

      await _verify(tester, '512345678');

      expect(_deviceChoices(), (false, false));
      await ProfileService().addOfferedSkill('Baking');
      expect(_published(profiles)['profileVisible'], isFalse);
      // From now on the choices are stored with the profile.
      expect(
        profiles.storedDataOf(_uid),
        containsPair('profileVisible', false),
      );
    });

    testWidgets('an account never published keeps the choices on this device', (
      tester,
    ) async {
      AuthService.profiles = DemoProfileRepository(profiles: {_uid: _maha});

      await _verify(tester, '512345678');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_deviceChoices(), (true, true));
    });

    testWidgets('if the choices cannot be read, sign-in stops safely', (
      tester,
    ) async {
      final auth = _RecordingAuth();
      AuthService.repository = auth;
      AuthService.profiles = _UnreadableChoices();
      final before = repository.currentUser.toJson();

      await _verify(tester, '512345678');

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(repository.currentUser.toJson(), before);
      expect(repository.isSignedIn, isFalse);
      expect(auth.signOuts, 1);
    });
  });

  group('when the app opens signed in', () {
    /// Saves the demo member as signed in, as if the app had been closed.
    Future<void> saveSignedIn() async {
      await repository.restore();
      AuthService().signIn();
      await repository.save();
      final saved = source.snapshot;
      repository.reset();
      source.snapshot = saved;
    }

    testWidgets('the profile is loaded before Home', (tester) async {
      await saveSignedIn();
      AuthService.profiles = DemoProfileRepository(profiles: {_uid: _maha});

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(ProfileService().currentUser.name, 'Maha Alzahrani');
      expect(TradeService().all(), isEmpty);
    });

    testWidgets('the sharing choices are restored before Home', (tester) async {
      await saveSignedIn();
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_uid, _maha, visibility: _hidden);
      AuthService.profiles = profiles;

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_deviceChoices(), (false, false));
      // Older accounts are published if missing at start-up: this one is
      // published already, hidden, and stays so.
      expect(_published(profiles)['profileVisible'], isFalse);
    });

    testWidgets('restored choices are also what this device saves', (
      tester,
    ) async {
      await saveSignedIn();
      await deviceAccount.write(_uid);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(
        _uid,
        repository.currentUser,
        visibility: _hidden,
      );
      AuthService.profiles = profiles;

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();
      await repository.save();

      expect(source.snapshot, contains('"profileVisible":false'));
      expect(source.snapshot, contains('"locationVisible":false'));
    });

    testWidgets('choices that cannot be read keep another account out', (
      tester,
    ) async {
      await saveSignedIn();
      AuthService.profiles = _UnreadableChoices();

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.text('Could not load your data'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('a failure does not open another account\'s data', (
      tester,
    ) async {
      await saveSignedIn();
      AuthService.profiles = _FailingProfiles();

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.text('Could not load your data'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      AuthService.profiles = DemoProfileRepository(profiles: {_uid: _maha});
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(ProfileService().currentUser.name, 'Maha Alzahrani');
    });

    testWidgets('offline, the account\'s own saved copy still opens', (
      tester,
    ) async {
      await saveSignedIn();
      await deviceAccount.write(_uid);
      AuthService.profiles = _FailingProfiles();

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(ProfileService().currentUser.name, 'Yara Alghamdi');
    });

    testWidgets('an account without a profile is sent to sign in', (
      tester,
    ) async {
      await saveSignedIn();
      AuthService.profiles = DemoProfileRepository();

      await tester.pumpWidget(const SouqSkillsApp());
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(repository.isSignedIn, isFalse);
    });
  });
}
