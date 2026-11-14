import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/trade_session_service.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

Future<void> _signIn(WidgetTester tester) async {
  // A tall screen so lazily built list items exist without scrolling.
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
}

void main() {
  late MemoryDataSource source;

  setUp(() {
    source = MemoryDataSource();
    Repository.instance
      ..dataSource = source
      ..reset();
  });

  testWidgets('profile shows settings icon, badges and ratings', (
    tester,
  ) async {
    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.textContaining('Badges ('), findsOneWidget);
    expect(find.text('Ratings and reviews'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Dark mode'), findsOneWidget);
  });

  testWidgets('home has no category section', (tester) async {
    await _signIn(tester);
    expect(find.text('Categories'), findsNothing);
    expect(find.text('Skills for you'), findsOneWidget);
  });

  testWidgets('typing on Home filters the skills straight away', (
    tester,
  ) async {
    await _signIn(tester);
    expect(find.text('Build your first Flutter app'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'oud');
    await tester.pump();

    expect(find.text('Oud lessons from scratch'), findsOneWidget);
    expect(find.text('Build your first Flutter app'), findsNothing);
  });

  testWidgets('Home filters apply as soon as they are tapped', (tester) async {
    await _signIn(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cooking'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();

    expect(find.text('Traditional Saudi cooking'), findsOneWidget);
    expect(find.text('Build your first Flutter app'), findsNothing);
  });

  testWidgets('a finished exchange can be rated and appears on the profile', (
    tester,
  ) async {
    await _signIn(tester);
    final creditsBefore = WalletService().balance;

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My trades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UI design ⇄ Photography'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as complete'));
    await tester.pumpAndSettle();

    expect(find.text('Rate your experience'), findsOneWidget);
    expect(WalletService().balance, creditsBefore + 10);

    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    await tester.tap(find.text('On time'));
    await tester.pump();
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();

    expect(find.text('You rated Sami Alharbi'), findsOneWidget);
    expect(find.text('On time'), findsOneWidget);

    await tester.pump(MemberSimulator.replyDelay);
    await tester.pumpAndSettle();
    expect(find.text('Sami Alharbi rated you'), findsOneWidget);
  });

  Future<void> openPostTab(WidgetTester tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
  }

  testWidgets('a solo listing is published with selections only', (
    tester,
  ) async {
    await openPostTab(tester);
    await tester.tap(find.text('Cooking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    // The success page shows what was published and leads on to it.
    expect(find.text('Your skill is out there'), findsOneWidget);
    expect(find.text('Learn Baking'), findsOneWidget);
    await tester.tap(find.text('View listing'));
    await tester.pumpAndSettle();
    expect(find.text('Learn Baking'), findsOneWidget);
    expect(find.text('Edit listing'), findsOneWidget);
  });

  testWidgets('a group trade is published with selections only', (
    tester,
  ) async {
    await openPostTab(tester);
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Piano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Singing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Music skill circle'), findsOneWidget);
    expect(find.text('Piano'), findsOneWidget);
  });

  testWidgets('publishing without selections shows validation', (tester) async {
    await openPostTab(tester);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Choose at least one skill'), findsOneWidget);
  });

  test('a proposal becomes a schedulable trade when accepted', () {
    AuthService().signIn();
    final proposals = ProposalService();
    const incoming = 'p-noura';

    proposals.accept(incoming);

    final trade = TradeService().byId('t-noura')!;
    expect(proposals.byId(incoming)!.status, ProposalStatus.accepted);
    expect(trade.status, TradeStatus.accepted);

    TradeSessionService().schedule(
      tradeId: trade.id,
      scheduledAt: DateTime(2030),
      method: 'Online',
      locationOrLink: '',
      notes: '',
    );
    expect(TradeService().byId(trade.id)!.sessionId, isNotNull);
  });

  test('a new account starts without the demo activity', () {
    AuthService().createAccount(
      firstName: 'New',
      lastName: 'Member',
      username: 'new_member',
      phone: '512345678',
      city: 'Jeddah',
      keepLocationPrivate: false,
    );

    expect(TradeService().all(), isEmpty);
    expect(ReviewService().averageRatingOf(User.currentUserId), isNull);
    expect(WalletService().balance, 120);
  });
}
