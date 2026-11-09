import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/location_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

class _FakeLocator implements DeviceLocator {
  _FakeLocator({this.fail = false});

  final bool fail;

  @override
  Future<(double, double)> currentPosition() async {
    if (fail) throw const LocationUnavailable('Allow location access.');
    return (21.5, 39.2);
  }
}

Future<void> _openPhone(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await _openPhone(tester);
  await tester.enterText(find.byType(TextField), '501234567');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Future<void> _openSignUp(WidgetTester tester) async {
  await _openPhone(tester);
  await tester.enterText(find.byType(TextField), '512345678');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  final repository = Repository.instance;

  setUp(() {
    LocationService.locator = _FakeLocator();
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  testWidgets('an incoming proposal can be countered from its card', (
    tester,
  ) async {
    await _signIn(tester);
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noura Alotaibi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send counteroffer'));
    await tester.pumpAndSettle();

    expect(find.text('Countered'), findsOneWidget);
    expect(find.text('Your proposal • 45 min • In person'), findsOneWidget);

    await tester.pump(MemberSimulator.proposalReplyDelay);
    await tester.pumpAndSettle();
    expect(find.text('View trade'), findsOneWidget);
  });

  testWidgets('your own proposal can be countered from its card', (
    tester,
  ) async {
    await _signIn(tester);
    ProposalService().send(
      const TradeProposal(
        senderId: 'me',
        receiverId: 'm-sami',
        offeredSkill: 'Figma',
        requestedSkill: 'Flutter',
      ),
    );
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sami Alharbi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();
    expect(find.text('Send counteroffer'), findsOneWidget);
    await tester.tap(find.text('Send counteroffer'));
    await tester.pumpAndSettle();
    expect(find.text('Countered'), findsOneWidget);

    await tester.pump(MemberSimulator.proposalReplyDelay);
    await tester.pumpAndSettle();
  });

  group('sign up', () {
    testWidgets('requires names and a unique username', (tester) async {
      await _openSignUp(tester);
      await tester.enterText(_field('First name'), 'Maha');
      await tester.enterText(_field('Last name'), 'Alzahrani');
      await tester.enterText(_field('Username'), 'SAMI');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('That username is already taken'), findsOneWidget);

      await tester.enterText(_field('Username'), 'maha_z');
      await tester.tap(find.text('Keep my location private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      final user = ProfileService().currentUser;
      expect(user.name, 'Maha Alzahrani');
      expect(user.username, 'maha_z');
      expect(ProfileService().settings.locationVisible, isFalse);
    });

    testWidgets('can take the location from the device', (tester) async {
      await _openSignUp(tester);
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();
      expect(find.text('Jeddah'), findsOneWidget);
    });

    testWidgets('explains when the location is unavailable', (tester) async {
      LocationService.locator = _FakeLocator(fail: true);
      await _openSignUp(tester);
      await tester.tap(find.text('Use my current location'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Allow location access.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  test('the nearest offered city is chosen', () {
    expect(LocationService().nearestCity(26.45, 50.08), 'Dammam');
    expect(LocationService().nearestCity(24.8, 46.7), 'Riyadh');
  });

  testWidgets('a new phone number must be verified before it is saved', (
    tester,
  ) async {
    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Phone number'), '555555555');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Verify phone'), findsOneWidget);
    expect(ProfileService().currentUser.phone, '501234567');

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(ProfileService().currentUser.phone, '555555555');
  });

  testWidgets('a member is invited to a group by username', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group trades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language exchange club'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump();
    expect(
      find.text('No member can be invited with that username.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'omar');
    await tester.pump();
    await tester.tap(find.text('@omar'));
    await tester.pumpAndSettle();
    expect(find.text('Invited'), findsOneWidget);

    await tester.pump(MemberSimulator.replyDelay);
    await tester.pumpAndSettle();
    expect(find.text('Members (3)'), findsOneWidget);
  });

  test('a group you were not invited to is never visible', () {
    repository.groupTrades.add(
      const GroupTrade(id: 'g-x', title: 'Private', memberIds: ['m-sami']),
    );
    expect(
      GroupTradeService().all().map((group) => group.id),
      isNot(contains('g-x')),
    );
  });

  testWidgets('Settings has no search filters', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show only'), findsNothing);
  });

  testWidgets('listings show tags that can be filtered on Home', (
    tester,
  ) async {
    await _signIn(tester);
    expect(find.text('Women only'), findsWidgets);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Women only').last);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();

    expect(find.text('Home strength coaching'), findsOneWidget);
    expect(find.text('Build your first Flutter app'), findsNothing);
  });
}
