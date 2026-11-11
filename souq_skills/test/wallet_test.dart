import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/trade_session_service.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _welcome = WalletDocument.welcomeCredits;
const _reward = WalletDocument.completionReward;

final _tomorrow = DateTime.now().add(const Duration(days: 1));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

TradeProposal _draft({
  String from = User.currentUserId,
  String to = _sami,
  int credits = 0,
}) => TradeProposal(
  senderId: from,
  receiverId: to,
  offeredSkill: credits > 0 ? '' : 'Baking',
  requestedSkill: 'Flutter',
  creditsOffered: credits,
);

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

User _user(String first, String username) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: 'Test',
  username: username,
  phone: '501234567',
  city: 'Jeddah',
  isVerified: true,
);

void main() {
  group('settlement on the server', () {
    late DemoTradeRepository server;
    late DemoWalletRepository wallets;

    setUp(() {
      wallets = DemoWalletRepository();
      server = DemoTradeRepository(wallets: wallets);
    });

    int? balanceOf(String uid) =>
        WalletDocument.balanceOf(wallets.storedWallet(uid));

    /// [payer] offers [credits] to [payee], who accepts; a session is
    /// booked. Returns the trade id.
    Future<String> acceptedTrade({
      String payer = _maha,
      String payee = _sami,
      int credits = 0,
    }) async {
      final sent = await server.sendProposal(
        payer,
        _draft(from: payer, to: payee, credits: credits),
      );
      await server.respondToProposal(
        payee,
        tradeId: sent.tradeId,
        proposalId: sent.proposalId,
        response: ProposalStatus.accepted,
      );
      await server.scheduleSession(
        payer,
        tradeId: sent.tradeId,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      return sent.tradeId;
    }

    test('a wallet opens once, with the welcome credits', () async {
      await wallets.openWallet(_maha);
      await wallets.openWallet(_maha);

      expect(balanceOf(_maha), _welcome);
      expect(wallets.storedEntries(_maha).keys, [WalletDocument.welcomeId]);
      await expectLater(
        wallets.openWallet(User.currentUserId),
        throwsA(WalletException.sessionExpired),
      );
    });

    test('both members are rewarded once, after both confirmed', () async {
      final tradeId = await acceptedTrade();

      expect(await server.confirmCompletion(_maha, tradeId), isFalse);
      expect(balanceOf(_maha), _welcome, reason: 'nothing paid yet');
      expect(wallets.storedEntries(_maha).keys, [WalletDocument.welcomeId]);

      expect(await server.confirmCompletion(_sami, tradeId), isTrue);
      for (final (uid, other) in [(_maha, _sami), (_sami, _maha)]) {
        expect(balanceOf(uid), _welcome + _reward);
        final reward = wallets.storedEntries(
          uid,
        )[WalletDocument.rewardId(tradeId)]!;
        expect(reward['amount'], _reward);
        expect(reward['counterpartyId'], other);
        expect(
          wallets
              .storedEntries(uid)
              .containsKey(WalletDocument.paymentId(tradeId)),
          isFalse,
        );
      }
    });

    for (final payerConfirmsLast in [true, false]) {
      test(
        'credits move from the payer to the other member '
        '(${payerConfirmsLast ? 'payer' : 'receiver'} confirms last)',
        () async {
          final tradeId = await acceptedTrade(credits: 30);
          final order = payerConfirmsLast ? [_sami, _maha] : [_maha, _sami];
          for (final uid in order) {
            await server.confirmCompletion(uid, tradeId);
          }

          expect(balanceOf(_maha), _welcome + _reward - 30);
          expect(balanceOf(_sami), _welcome + _reward + 30);
          final paid = wallets.storedEntries(
            _maha,
          )[WalletDocument.paymentId(tradeId)]!;
          final received = wallets.storedEntries(
            _sami,
          )[WalletDocument.paymentId(tradeId)]!;
          expect(paid['kind'], WalletEntryKind.tradePayment.name);
          expect(paid['amount'], -30);
          expect(received['kind'], WalletEntryKind.tradeIncome.name);
          expect(received['amount'], 30);
        },
      );
    }

    test('the payer who countered is the one who pays', () async {
      final sent = await server.sendProposal(_maha, _draft());
      // Sami counters, offering credits instead of a skill; Maha accepts.
      final counterId = await server.counterProposal(
        _sami,
        tradeId: sent.tradeId,
        proposalId: sent.proposalId,
        draft: _draft(from: _sami, to: _maha, credits: 25),
      );
      await server.respondToProposal(
        _maha,
        tradeId: sent.tradeId,
        proposalId: counterId,
        response: ProposalStatus.accepted,
      );
      await server.scheduleSession(
        _maha,
        tradeId: sent.tradeId,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      await server.confirmCompletion(_maha, sent.tradeId);
      await server.confirmCompletion(_sami, sent.tradeId);

      expect(balanceOf(_sami), _welcome + _reward - 25);
      expect(balanceOf(_maha), _welcome + _reward + 25);
    });

    test(
      'a payer short of credits cannot complete, and nothing moves',
      () async {
        final tradeId = await acceptedTrade(credits: 200);

        await server.confirmCompletion(_sami, tradeId);
        await expectLater(
          server.confirmCompletion(_maha, tradeId),
          throwsA(TradeException.insufficientCredits),
        );
        expect(server.storedTrade(tradeId)!['status'], 'accepted');
        expect(balanceOf(_maha), _welcome);
        expect(balanceOf(_sami), _welcome);
        expect(wallets.storedEntries(_sami).keys, [WalletDocument.welcomeId]);
      },
    );

    test('the receiver confirming last is refused when the payer is short '
        'of credits', () async {
      final tradeId = await acceptedTrade(credits: 200);

      await server.confirmCompletion(_maha, tradeId);
      await expectLater(
        server.confirmCompletion(_sami, tradeId),
        throwsA(TradeException.notSaved),
      );
      expect(server.storedTrade(tradeId)!['status'], 'accepted');
      expect(balanceOf(_maha), _welcome);
      expect(balanceOf(_sami), _welcome);
    });

    test('exactly what the payer has can be paid', () async {
      final tradeId = await acceptedTrade(credits: _welcome + _reward);
      await server.confirmCompletion(_maha, tradeId);
      await server.confirmCompletion(_sami, tradeId);
      expect(balanceOf(_maha), 0);
    });

    test('a completed trade is never paid or rewarded twice', () async {
      final tradeId = await acceptedTrade(credits: 30);
      await server.confirmCompletion(_maha, tradeId);
      await server.confirmCompletion(_sami, tradeId);
      final balances = [balanceOf(_maha), balanceOf(_sami)];
      final ledger = wallets.storedEntries(_maha);

      for (final uid in [_maha, _sami]) {
        await expectLater(
          server.confirmCompletion(uid, tradeId),
          throwsA(isA<TradeException>()),
        );
      }
      // Settling again directly, as a replayed write would.
      expect(
        () => wallets.settle(
          _sami,
          tradeId,
          server.storedTrade(tradeId)!..['status'] = 'accepted',
          DateTime.now(),
        ),
        throwsA(TradeException.notSaved),
      );
      expect([balanceOf(_maha), balanceOf(_sami)], balances);
      expect(wallets.storedEntries(_maha), hasLength(ledger.length));
    });

    test('a disputed or unconfirmed trade pays nothing', () async {
      final tradeId = await acceptedTrade(credits: 30);
      await server.confirmCompletion(_maha, tradeId);
      await server.markDisputed(_sami, tradeId);

      await expectLater(
        server.confirmCompletion(_sami, tradeId),
        throwsA(TradeException.notSaved),
      );
      expect(balanceOf(_maha), _welcome);
      expect(balanceOf(_sami), _welcome);
      expect(wallets.storedEntries(_sami).keys, [WalletDocument.welcomeId]);
    });

    test('a member outside the trade cannot complete or be paid', () async {
      final tradeId = await acceptedTrade(credits: 30);
      await server.confirmCompletion(_maha, tradeId);

      await expectLater(
        server.confirmCompletion(_lina, tradeId),
        throwsA(TradeException.notFound),
      );
      expect(balanceOf(_lina), _welcome);
      expect(server.storedTrade(tradeId)!['status'], 'accepted');
    });

    test('a settlement never creates or destroys credits', () {
      final trade = {
        'participantIds': [_maha, _sami],
        'termsBy': _sami,
        'creditsOffered': 40,
      };
      final settlement = WalletDocument.settle('t1', trade, DateTime.now());

      expect(settlement.map((item) => item.uid), [_maha, _sami]);
      expect(settlement.fold(0, (sum, item) => sum + item.delta), 2 * _reward);
      expect(settlement.last.delta, _reward - 40);
      for (final member in settlement) {
        expect(
          member.entries.values.fold<int>(
            0,
            (sum, entry) => sum + (entry['amount'] as int),
          ),
          member.delta,
        );
      }
    });
  });

  group('the wallet in the app', () {
    final repository = Repository.instance;
    final originalAuth = AuthService.repository;
    late _Auth auth;
    late DemoTradeRepository trades;

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      auth = _Auth();
      AuthService.repository = auth;
      AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_maha, _user('Maha', 'maha_z'));
      await profiles.saveProfile(_sami, _user('Sami', 'sami_a'));
      await profiles.saveProfile(_lina, _user('Lina', 'lina_s'));
      AuthService.profiles = profiles;
      ChatService.repository = DemoChatRepository();
      trades = DemoTradeRepository();
      OnlineTrades.repository = trades;
      AuthService().signIn();
      await _settle();
    });

    tearDown(() {
      OnlineTrades.repository = null;
      OnlineWallet.syncSession();
      ChatService.repository = null;
      AuthService.profiles = null;
      AuthService.deviceAccount = null;
      AuthService.repository = originalAuth;
    });

    /// Maha proposes to Sami, offering [credits]; Sami accepts and a
    /// session is booked. Returns the trade.
    Future<Trade> acceptedTrade({int credits = 0}) async {
      await ProposalService().send(_draft(credits: credits));
      await _settle();
      final trade = OnlineTrades.trades().first;
      await trades.respondToProposal(
        _sami,
        tradeId: trade.id,
        proposalId: trade.proposalId,
        response: ProposalStatus.accepted,
      );
      await _settle();
      await TradeSessionService().schedule(
        tradeId: trade.id,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      await _settle();
      return trade;
    }

    test('a signed-in member sees their online wallet, opened once', () async {
      expect(OnlineWallet.isActive, isTrue);
      expect(WalletService().balance, _welcome);
      expect(trades.wallets.storedWallet(_maha)!['balance'], _welcome);
      final [welcome] = WalletService().transactions();
      expect(welcome.title, 'Welcome credits');
      expect(welcome.amount, _welcome);

      // Local records, such as a demo member's trade, do not change it.
      WalletService().record(title: 'Local', subtitle: '', amount: 500);
      expect(WalletService().balance, _welcome);
    });

    test('completing a credit trade updates the balance live', () async {
      final trade = await acceptedTrade(credits: 30);
      expect(WalletService().heldCredits(), 30);
      expect(WalletService().availableCredits(), _welcome - 30);

      expect(await TradeService().complete(trade.id), isFalse);
      await _settle();
      expect(WalletService().balance, _welcome);

      expect(await trades.confirmCompletion(_sami, trade.id), isTrue);
      await _settle();

      expect(WalletService().balance, _welcome + _reward - 30);
      expect(WalletService().heldCredits(), 0);
      final shown = {
        for (final item in WalletService().transactions()) item.title: item,
      };
      expect(shown['Credits paid']!.amount, -30);
      expect(shown['Credits paid']!.type, TransactionType.spent);
      expect(shown['Trade completed']!.amount, _reward);
      expect(shown['Trade completed']!.participantName, 'Sami Test');
      expect(trades.wallets.storedWallet(_sami)!['balance'], 160);

      // Nothing is added again however often the trade arrives.
      await ProposalService().send(_draft());
      await _settle();
      expect(WalletService().balance, _welcome + _reward - 30);
      expect(
        repository.transactions.where((item) => item.tradeId == trade.id),
        isEmpty,
        reason: 'not also recorded on this device',
      );
    });

    test('this member confirming last, short of credits, is told so', () async {
      final trade = await acceptedTrade(credits: 100);
      await trades.confirmCompletion(_sami, trade.id);
      // Most of the balance is spent first in another trade, e.g. from
      // another device; the server checks the balance at completion.
      final spend = await trades.sendProposal(
        _maha,
        _draft(from: _maha, to: _lina, credits: 120),
      );
      await trades.respondToProposal(
        _lina,
        tradeId: spend.tradeId,
        proposalId: spend.proposalId,
        response: ProposalStatus.accepted,
      );
      await trades.scheduleSession(
        _lina,
        tradeId: spend.tradeId,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      await trades.confirmCompletion(_lina, spend.tradeId);
      await trades.confirmCompletion(_maha, spend.tradeId);
      await _settle();
      expect(WalletService().balance, _welcome + _reward - 120);

      await expectLater(
        TradeService().complete(trade.id),
        throwsA(TradeException.insufficientCredits),
      );
      await _settle();
      expect(TradeService().byId(trade.id)!.status, TradeStatus.accepted);
      expect(WalletService().balance, _welcome + _reward - 120);
    });

    test('another account signing in sees only its own wallet', () async {
      final trade = await acceptedTrade(credits: 30);
      await TradeService().complete(trade.id);
      await trades.confirmCompletion(_sami, trade.id);
      await _settle();
      expect(WalletService().balance, _welcome + _reward - 30);

      auth.currentUid = _lina;
      OnlineTrades.syncSession();
      OnlineWallet.syncSession();
      await _settle();

      expect(WalletService().balance, _welcome);
      expect(WalletService().transactions().map((item) => item.id), [
        WalletDocument.welcomeId,
      ]);

      auth.currentUid = _maha;
      OnlineTrades.syncSession();
      OnlineWallet.syncSession();
      await _settle();
      expect(WalletService().balance, _welcome + _reward - 30);
    });

    test('signed out, the online wallet is no longer shown', () async {
      await AuthService().signOut();
      await _settle();
      expect(OnlineWallet.isActive, isFalse);
    });

    test('a wallet loading error is reported and the balance stays', () async {
      trades.wallets.failStreams(WalletException.offline);
      await _settle();

      expect(OnlineWallet.loadError, WalletException.offline.message);
      expect(WalletService().balance, _welcome);
    });

    test('offline, the wallet stays on this device as before', () async {
      OnlineTrades.repository = null;
      OnlineWallet.syncSession();
      expect(OnlineWallet.isActive, isFalse);
      final before = WalletService().balance;
      expect(
        before,
        repository.transactions.fold(0, (sum, item) => sum + item.amount),
      );

      await ProposalService().send(_draft(credits: 20));
      final local = repository.trades.last;
      await ProposalService().accept(repository.proposals.last.id);
      await TradeSessionService().schedule(
        tradeId: local.id,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      expect(await TradeService().complete(local.id), isTrue);

      expect(
        WalletService().balance,
        before + TradeService.completionCredits - 20,
      );
      // Recorded once, as before.
      TradeService().recordCompletion(TradeService().byId(local.id)!);
      expect(
        WalletService().balance,
        before + TradeService.completionCredits - 20,
      );
    });
  });
}
