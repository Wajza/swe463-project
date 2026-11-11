import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

/// The demo signs every account in as 'me'.
const _uid = 'me';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Verifies a new number and fills in Create account with [username].
Future<void> _signUp(WidgetTester tester, String username) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '512345678');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
  expect(find.text('About you'), findsOneWidget);

  await tester.enterText(_field('First name'), 'Maha');
  await tester.enterText(_field('Last name'), 'Alzahrani');
  await tester.enterText(_field('Username'), username);
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
}

Future<void> _deleteAccount(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete account'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

void main() {
  final repository = Repository.instance;

  setUp(() {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    AuthService.deviceAccount = MemoryDeviceAccountStore();
  });

  tearDown(() {
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
  });

  testWidgets('an available username creates the account and claims it', (
    tester,
  ) async {
    final profiles = DemoProfileRepository();
    AuthService.profiles = profiles;

    await _signUp(tester, 'Maha_Z');

    expect(find.byType(HomeScreen), findsOneWidget);
    final saved = (await profiles.fetchProfile(_uid))!;
    expect(saved.toJson(), ProfileService().currentUser.toJson());
    expect(saved.username, 'Maha_Z');
    expect(profiles.ownerOf('maha_z'), _uid);
  });

  testWidgets('after signing up, no other account can take the username', (
    tester,
  ) async {
    final profiles = DemoProfileRepository();
    AuthService.profiles = profiles;

    await _signUp(tester, 'maha_z');

    await expectLater(
      profiles.saveProfile(
        'other-uid',
        const User(
          id: 'x',
          firstName: 'Other',
          lastName: 'Member',
          username: 'MAHA_Z',
        ),
      ),
      throwsA(same(ProfileException.usernameTaken)),
    );
    expect(profiles.ownerOf('maha_z'), _uid);
  });

  testWidgets('a claimed username is refused and nothing is created', (
    tester,
  ) async {
    final profiles = DemoProfileRepository(claims: {'maha_z': 'other-uid'});
    AuthService.profiles = profiles;
    final before = repository.currentUser.toJson();

    await _signUp(tester, 'MAHA_z');

    expect(find.text('That username is already taken'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(await profiles.fetchProfile(_uid), isNull);
    expect(profiles.ownerOf('maha_z'), 'other-uid');
    expect(repository.currentUser.toJson(), before);
    expect(repository.isSignedIn, isFalse);
  });

  testWidgets('after a refused username, another one can be chosen', (
    tester,
  ) async {
    final profiles = DemoProfileRepository(claims: {'maha_z': 'other-uid'});
    AuthService.profiles = profiles;

    await _signUp(tester, 'maha_z');
    expect(find.text('That username is already taken'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.enterText(_field('Username'), 'maha_2');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect((await profiles.fetchProfile(_uid))!.username, 'maha_2');
    expect(profiles.ownerOf('maha_2'), _uid);
    expect(profiles.ownerOf('maha_z'), 'other-uid');
    expect(ProfileService().currentUser.username, 'maha_2');
  });

  testWidgets('deleting the account frees its username', (tester) async {
    final profiles = DemoProfileRepository();
    AuthService.profiles = profiles;
    await _signUp(tester, 'maha_z');
    expect(profiles.ownerOf('maha_z'), _uid);

    await _deleteAccount(tester);

    expect(find.text('Get started'), findsOneWidget);
    expect(await profiles.fetchProfile(_uid), isNull);
    expect(profiles.ownerOf('maha_z'), isNull);
    await profiles.saveProfile(
      'other-uid',
      const User(
        id: 'x',
        firstName: 'Other',
        lastName: 'Member',
        username: 'Maha_Z',
      ),
    );
    expect(profiles.ownerOf('maha_z'), 'other-uid');
  });

  group('DemoProfileRepository.deleteProfile', () {
    test('removes the profile and its own claim only', () async {
      const profile = User(
        id: User.currentUserId,
        firstName: 'Maha',
        lastName: 'Alzahrani',
        username: 'maha_z',
      );
      final profiles = DemoProfileRepository(
        profiles: {_uid: profile},
        claims: {'maha_z': 'other-uid'},
      );

      await profiles.deleteProfile(_uid);

      expect(await profiles.fetchProfile(_uid), isNull);
      // Held by another account, so it is left alone.
      expect(profiles.ownerOf('maha_z'), 'other-uid');
    });

    test('does nothing for an account without a profile', () async {
      final profiles = DemoProfileRepository(claims: {'sami': 'other-uid'});

      await profiles.deleteProfile(_uid);

      expect(profiles.ownerOf('sami'), 'other-uid');
    });
  });
}
