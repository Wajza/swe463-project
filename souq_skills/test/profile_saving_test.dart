import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

/// The demo signs every account in as 'me'.
const _uid = 'me';

/// Stands in for Firestore, keeping one stored profile.
class _FakeProfiles implements ProfileRepository {
  _FakeProfiles(this.stored);

  User? stored;
  bool failSaves = false;
  Completer<void>? holdSaves;
  final List<String> savedUids = [];

  @override
  Future<User?> fetchProfile(String uid) async => stored;

  @override
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids) async =>
      {for (final uid in uids) uid: ?stored};

  @override
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  }) async {
    await holdSaves?.future;
    if (failSaves) {
      throw const ProfileException('Check your internet connection.');
    }
    savedUids.add(uid);
    stored = profile;
  }

  @override
  Future<void> deleteProfile(String uid) async => stored = null;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Signs the demo member in and opens Edit profile.
Future<void> _openEditProfile(WidgetTester tester) async {
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
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit profile'));
  await tester.pumpAndSettle();
}

void main() {
  final repository = Repository.instance;
  late User original;
  late _FakeProfiles profiles;

  setUp(() {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    original = repository.currentUser;
    profiles = _FakeProfiles(original);
    AuthService.profiles = profiles;
    // The saved demo data belongs to this account, so it is kept.
    AuthService.deviceAccount = MemoryDeviceAccountStore(_uid);
  });

  tearDown(() {
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
  });

  testWidgets('a saved change reaches the online profile, then the device', (
    tester,
  ) async {
    await _openEditProfile(tester);
    final saving = profiles.holdSaves = Completer<void>();

    await tester.enterText(_field('Bio (optional)'), 'Now teaching Figma.');
    await tester.tap(find.text('Save'));
    await tester.pump();

    // While saving: the member sees it, cannot save twice, and the device
    // does not change before the online profile has.
    expect(find.text('Saving…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(ProfileService().currentUser.bio, original.bio);

    saving.complete();
    await tester.pumpAndSettle();

    expect(profiles.savedUids, [_uid]);
    expect(profiles.stored!.bio, 'Now teaching Figma.');
    expect(ProfileService().currentUser.bio, 'Now teaching Figma.');
    expect(find.text('Profile updated'), findsOneWidget);
    expect(_field('Bio (optional)'), findsNothing);
  });

  testWidgets('a failed save changes nothing and says so', (tester) async {
    await _openEditProfile(tester);
    profiles.failSaves = true;

    await tester.enterText(_field('Bio (optional)'), 'Lost change');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Check your internet connection.'), findsOneWidget);
    expect(find.text('Profile updated'), findsNothing);
    expect(_field('Bio (optional)'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(ProfileService().currentUser.toJson(), original.toJson());
    expect(profiles.stored!.toJson(), original.toJson());

    // The typed change is still there to retry.
    profiles.failSaves = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(profiles.stored!.bio, 'Lost change');
    expect(ProfileService().currentUser.bio, 'Lost change');
  });

  testWidgets('editing one field keeps every other field', (tester) async {
    expect(original.skillsOffered, isNotEmpty);
    await _openEditProfile(tester);

    await tester.enterText(_field('First name'), 'Yasmin');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final expected = original.copyWith(firstName: 'Yasmin').toJson();
    expect(profiles.stored!.toJson(), expected);
    expect(ProfileService().currentUser.toJson(), expected);
  });

  testWidgets('a verified new number is not asked for again on retry', (
    tester,
  ) async {
    await _openEditProfile(tester);
    profiles.failSaves = true;

    await tester.enterText(_field('Phone number'), '555555555');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Verify phone'), findsOneWidget);
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Check your internet connection.'), findsOneWidget);
    expect(ProfileService().currentUser.phone, original.phone);

    profiles.failSaves = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Verify phone'), findsNothing);
    expect(profiles.stored!.phone, '555555555');
    expect(ProfileService().currentUser.phone, '555555555');
  });
}
