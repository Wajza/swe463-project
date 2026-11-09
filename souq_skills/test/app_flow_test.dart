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

Future<void> _signIn(WidgetTester tester) async {
  // A tall screen so lazily built list items exist without scrolling.
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '501234567');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '123456');
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(Repository.instance.reset);

  testWidgets('profile opens settings from an icon, not a list item', (
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
    expect(find.text('App preferences'), findsOneWidget);
  });

  testWidgets('a finished exchange can be rated and appears on the profile', (
    tester,
  ) async {
    await _signIn(tester);
    final creditsBefore = WalletService().balance;

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('My trades'));
    await tester.tap(find.text('UI design ⇄ Photography'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm completion'));
    await tester.pumpAndSettle();

    expect(find.text('Rate your experience'), findsOneWidget);
    expect(WalletService().balance, creditsBefore + 10);

    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Lovely photo lesson');
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();
    expect(find.text('Rating saved'), findsOneWidget);

    await tester.tap(find.text('See it on my profile'));
    await tester.pumpAndSettle();
    expect(find.text('You rated Sami Alharbi'), findsOneWidget);
    expect(find.text('Lovely photo lesson'), findsOneWidget);

    await tester.pump(MemberSimulator.replyDelay);
    await tester.pumpAndSettle();
    expect(find.text('Sami Alharbi rated you'), findsOneWidget);
  });

  testWidgets('posting a skill publishes it to My listings', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cooking').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Bread baking');
    await tester.enterText(find.byType(TextFormField).at(1), 'Baking');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Learn to bake bread at home.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Guitar');
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Your skill is live'), findsOneWidget);

    await tester.tap(find.text('View listing'));
    await tester.pumpAndSettle();
    expect(find.text('Bread baking'), findsOneWidget);
    expect(find.text('Manage listing'), findsOneWidget);
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
      name: 'New Member',
      username: 'new_member',
      phone: '512345678',
      city: 'Jeddah',
    );

    expect(TradeService().all(), isEmpty);
    expect(ReviewService().averageRatingOf(User.currentUserId), isNull);
    expect(WalletService().balance, 120);
  });
}
