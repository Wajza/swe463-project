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
  Future<void> saveProfile(String uid, User profile) async {}
}

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
    testWidgets('an existing profile is loaded and opens Home', (
      tester,
    ) async {
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
