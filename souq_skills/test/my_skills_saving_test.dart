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
  Future<void> saveProfile(String uid, User profile) async {
    savedUids.add(uid);
    await holdSaves?.future;
    if (failSaves) {
      throw const ProfileException('Check your internet connection.');
    }
    stored = profile;
  }

  @override
  Future<void> deleteProfile(String uid) async => stored = null;
}

/// Signs the demo member in and opens My skills.
Future<void> _openMySkills(WidgetTester tester) async {
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
  await tester.tap(find.text('My skills'));
  await tester.pumpAndSettle();
}

/// Picks [skill] from the sheet opened by the first Add chip ("I offer").
Future<void> _addOffered(WidgetTester tester, String skill) async {
  await tester.tap(find.widgetWithText(ActionChip, 'Add').first);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, skill));
}

Finder _deleteButtonOf(String skill) => find.descendant(
  of: find.widgetWithText(InputChip, skill),
  matching: find.byTooltip('Delete'),
);

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

  testWidgets('adding a skill saves it online, then on the device', (
    tester,
  ) async {
    await _openMySkills(tester);

    await _addOffered(tester, 'Baking');
    await tester.pumpAndSettle();

    final expected = [...original.skillsOffered, 'Baking'];
    expect(profiles.savedUids, [_uid]);
    expect(profiles.stored!.skillsOffered, expected);
    expect(ProfileService().currentUser.skillsOffered, expected);
    expect(find.widgetWithText(InputChip, 'Baking'), findsOneWidget);
  });

  testWidgets('removing a skill saves it online, then on the device', (
    tester,
  ) async {
    await _openMySkills(tester);

    await tester.tap(_deleteButtonOf('Figma'));
    await tester.pumpAndSettle();

    final expected = original.skillsOffered.where((s) => s != 'Figma');
    expect(profiles.savedUids, [_uid]);
    expect(profiles.stored!.skillsOffered, expected);
    expect(ProfileService().currentUser.skillsOffered, expected);
    expect(find.widgetWithText(InputChip, 'Figma'), findsNothing);
  });

  testWidgets('a failed save keeps the skills and can be retried', (
    tester,
  ) async {
    await _openMySkills(tester);
    profiles.failSaves = true;

    await _addOffered(tester, 'Baking');
    await tester.pumpAndSettle();

    expect(find.text('Check your internet connection.'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Baking'), findsNothing);
    expect(ProfileService().currentUser.toJson(), original.toJson());
    expect(profiles.stored!.toJson(), original.toJson());

    // Nothing is left locked: the same change can simply be made again.
    profiles.failSaves = false;
    await _addOffered(tester, 'Baking');
    await tester.pumpAndSettle();
    expect(profiles.stored!.skillsOffered, contains('Baking'));
    expect(ProfileService().currentUser.skillsOffered, contains('Baking'));
  });

  testWidgets('changing skills keeps every other profile field', (
    tester,
  ) async {
    await _openMySkills(tester);

    await _addOffered(tester, 'Baking');
    await tester.pumpAndSettle();
    await tester.tap(_deleteButtonOf('Photography'));
    await tester.pumpAndSettle();

    final expected = original
        .copyWith(
          skillsOffered: [...original.skillsOffered, 'Baking'],
          skillsWanted: original.skillsWanted
              .where((s) => s != 'Photography')
              .toList(),
        )
        .toJson();
    expect(profiles.stored!.toJson(), expected);
    expect(ProfileService().currentUser.toJson(), expected);
  });

  testWidgets('no other change can be made while one is saving', (
    tester,
  ) async {
    await _openMySkills(tester);
    final saving = profiles.holdSaves = Completer<void>();

    await _addOffered(tester, 'Baking');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(ProfileService().currentUser.skillsOffered, original.skillsOffered);
    for (final chip in tester.widgetList<ActionChip>(find.byType(ActionChip))) {
      expect(chip.onPressed, isNull);
    }
    for (final chip in tester.widgetList<InputChip>(find.byType(InputChip))) {
      expect(chip.onDeleted, isNull);
    }

    // Tapping again does not start a second save.
    await tester.tap(find.widgetWithText(InputChip, 'Figma'));
    await tester.tap(
      find.widgetWithText(ActionChip, 'Add').first,
      warnIfMissed: false,
    );
    await tester.pump();
    expect(profiles.savedUids, [_uid]);

    saving.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(profiles.savedUids, [_uid]);
    expect(ProfileService().currentUser.skillsOffered, contains('Baking'));
    expect(find.text('Add a skill'), findsNothing);
  });
}
