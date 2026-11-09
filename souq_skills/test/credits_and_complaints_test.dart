import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

const _creditOffer = TradeProposal(
  senderId: 'me',
  receiverId: 'm-sami',
  requestedSkill: 'Flutter',
  creditsOffered: 20,
);

Future<void> _signIn(WidgetTester tester) async {
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

Future<void> _openHelp(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Help and support'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  testWidgets('credits can be offered in a counteroffer', (tester) async {
    await _signIn(tester);
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noura Alotaibi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 credits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send counteroffer'));
    await tester.pumpAndSettle();

    expect(find.text('30 credits ⇄ Fitness coaching'), findsOneWidget);
    expect(TradeService().byId('t-noura')!.creditsPaid, 30);

    await tester.pump(MemberSimulator.proposalReplyDelay);
    await tester.pumpAndSettle();
  });

  testWidgets('only credits that are not on hold can be offered', (
    tester,
  ) async {
    AuthService().signIn();
    final wallet = WalletService();
    final before = wallet.availableCredits();

    ProposalService().send(_creditOffer);
    expect(wallet.availableCredits(), before - 20);
    expect(wallet.balance, before);

    await tester.pump(MemberSimulator.proposalReplyDelay);
  });

  testWidgets('credits are paid only when the trade completes', (tester) async {
    AuthService().signIn();
    final wallet = WalletService();
    final before = wallet.balance;
    ProposalService().send(_creditOffer);
    await tester.pump(MemberSimulator.proposalReplyDelay);

    final trade = TradeService().all().first;
    expect(trade.status, TradeStatus.accepted);
    expect(wallet.balance, before);

    TradeService().complete(trade.id);
    expect(wallet.balance, before - 20 + TradeService.completionCredits);
    expect(wallet.heldCredits(), 0);
  });

  testWidgets('cancelling a proposal releases its credits', (tester) async {
    AuthService().signIn();
    final wallet = WalletService();
    final before = wallet.availableCredits();
    ProposalService().send(_creditOffer);

    ProposalService().cancel(Repository.instance.proposals.last.id);
    expect(wallet.availableCredits(), before);

    await tester.pump(MemberSimulator.proposalReplyDelay);
  });

  testWidgets('Edit profile is in Settings and not on the profile', (
    tester,
  ) async {
    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('a complaint is confirmed with a feedback message', (
    tester,
  ) async {
    await _signIn(tester);
    await _openHelp(tester);
    expect(find.text('Message support'), findsNothing);

    await tester.tap(find.text('Send a complaint'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send complaint'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a reason'), findsOneWidget);

    await tester.tap(find.text('A trade'));
    await tester.pump();
    await tester.tap(find.text('Send complaint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(SafetyService.complaintReceivedMessage), findsOneWidget);
    expect(
      NotificationService().all().first.message,
      SafetyService.complaintReceivedMessage,
    );
    expect(SafetyService().cases().first.reason, 'A trade');
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
