import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/trade_session_service.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/proposal_card.dart';
import 'package:souq_skills/widgets/status_chip.dart';

import 'support/memory_data_source.dart';

const _tradeId = 't-card';

/// A proposal of the current member's to Sami, on trade [_tradeId].
TradeProposal _proposal(ProposalStatus status) => TradeProposal(
  id: 'p-card',
  tradeId: _tradeId,
  senderId: User.currentUserId,
  receiverId: 'm-sami',
  offeredSkill: 'Baking',
  requestedSkill: 'Flutter',
  status: status,
);

Trade _trade(TradeStatus status) => Trade(
  id: _tradeId,
  proposalId: 'p-card',
  otherMemberId: 'm-sami',
  offeredSkill: 'Baking',
  requestedSkill: 'Flutter',
  status: status,
);

/// The label of the only status chip on screen.
String _chipLabel(WidgetTester tester) =>
    tester.widget<StatusChip>(find.byType(StatusChip)).label;

void main() {
  final repository = Repository.instance;

  group('the status a proposal card shows', () {
    setUp(() {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService().signIn();
    });

    Future<void> showCard(WidgetTester tester, ProposalStatus status) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiveView(
                builder: (_) => ProposalCard(proposal: _proposal(status)),
              ),
            ),
          ),
        );

    for (final (trade, shown) in [
      (TradeStatus.completed, 'Completed'),
      (TradeStatus.disputed, 'Disputed'),
      (TradeStatus.accepted, 'Accepted'),
    ]) {
      testWidgets('an accepted proposal whose trade is ${trade.name} shows '
          '$shown', (tester) async {
        repository.insert(repository.trades, _trade(trade));

        await showCard(tester, ProposalStatus.accepted);

        expect(_chipLabel(tester), shown);
        // Its action stays the same.
        expect(find.text('View trade'), findsOneWidget);
      });
    }

    testWidgets('an accepted proposal whose trade has not loaded shows '
        'Accepted', (tester) async {
      expect(TradeService().byId(_tradeId), isNull);

      await showCard(tester, ProposalStatus.accepted);

      expect(_chipLabel(tester), 'Accepted');
    });

    for (final (status, shown) in [
      (ProposalStatus.pending, 'Pending'),
      (ProposalStatus.countered, 'Countered'),
      (ProposalStatus.declined, 'Declined'),
      (ProposalStatus.cancelled, 'Cancelled'),
    ]) {
      testWidgets('a ${status.name} proposal keeps showing $shown, whatever '
          'its trade', (tester) async {
        // Even a trade that says otherwise does not change it.
        repository.insert(repository.trades, _trade(TradeStatus.completed));

        await showCard(tester, status);

        expect(_chipLabel(tester), shown);
      });
    }

    testWidgets('the card changes as soon as its trade completes', (
      tester,
    ) async {
      repository.insert(repository.trades, _trade(TradeStatus.accepted));
      await showCard(tester, ProposalStatus.accepted);
      expect(_chipLabel(tester), 'Accepted');

      repository.update(
        repository.trades,
        _tradeId,
        (trade) => trade.copyWith(status: TradeStatus.completed),
      );
      await tester.pump();

      expect(_chipLabel(tester), 'Completed');
    });
  });

  group('in the chat, after both members confirm', () {
    const maha = 'uid-maha';
    const sami = 'uid-sami';
    final originalAuth = AuthService.repository;
    late DemoTradeRepository trades;

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService.repository = _Auth(maha);
      AuthService.deviceAccount = MemoryDeviceAccountStore(maha);
      final profiles = DemoProfileRepository();
      for (final (uid, name) in [(maha, 'maha_z'), (sami, 'sami_a')]) {
        await profiles.saveProfile(
          uid,
          User(
            id: User.currentUserId,
            firstName: name,
            lastName: 'Test',
            username: name,
            phone: '501234567',
            isVerified: true,
          ),
        );
      }
      AuthService.profiles = profiles;
      ChatService.repository = DemoChatRepository();
      trades = DemoTradeRepository();
      OnlineTrades.repository = trades;
      AuthService().signIn();
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      OnlineTrades.repository = null;
      ChatService.repository = null;
      AuthService.profiles = null;
      AuthService.deviceAccount = null;
      AuthService.repository = originalAuth;
    });

    testWidgets('the proposal card shows Completed, as the trade does', (
      tester,
    ) async {
      // The reported flow, between two real members.
      final trade = (await tester.runAsync(() async {
        Future<void> settle() => Future<void>.delayed(Duration.zero);
        await ProposalService().send(
          const TradeProposal(
            senderId: User.currentUserId,
            receiverId: sami,
            offeredSkill: 'Baking',
            requestedSkill: 'Flutter',
          ),
        );
        await settle();
        final sent = OnlineTrades.trades().single;
        await trades.respondToProposal(
          sami,
          tradeId: sent.id,
          proposalId: sent.proposalId,
          response: ProposalStatus.accepted,
        );
        await settle();
        await TradeSessionService().schedule(
          tradeId: sent.id,
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          method: 'Online',
          locationOrLink: '',
          notes: '',
        );
        await settle();
        await trades.confirmCompletion(sami, sent.id);
        await settle();
        await TradeService().complete(sent.id);
        await settle();
        return TradeService().byId(sent.id)!;
      }))!;
      expect(trade.status, TradeStatus.completed);
      // The proposal itself stays accepted; the card shows its trade.
      expect(
        ProposalService().byId(trade.proposalId)!.status,
        ProposalStatus.accepted,
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: (_) => [
            AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.chat, arguments: sami),
            ),
          ],
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Trade marked as complete.'), findsOneWidget);
      final card = find.byType(ProposalCard);
      expect(card, findsOneWidget);
      final chip = tester.widget<StatusChip>(
        find.descendant(of: card, matching: find.byType(StatusChip)),
      );
      expect(chip.label, 'Completed');
    });
  });
}

/// The offline sign-in with a Firebase-like [uid].
class _Auth extends DemoAuthRepository {
  _Auth(this._uid) : super(isKnownPhone: AuthService().isKnownPhone);

  final String _uid;

  @override
  String? get uid => _uid;
}
