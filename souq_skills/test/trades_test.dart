import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/notification.dart';
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
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

/// A built-in demo member, whose trades stay on this device.
const _demoSami = 'm-sami';

final _tomorrow = DateTime.now().add(const Duration(days: 1));

TradeProposal _draft({
  String to = _sami,
  String from = User.currentUserId,
  String offered = 'Baking',
  String requested = 'Flutter',
  int credits = 0,
}) => TradeProposal(
  senderId: from,
  receiverId: to,
  offeredSkill: offered,
  requestedSkill: requested,
  creditsOffered: credits,
);

/// Whether the local id `'me'` appears anywhere in stored [value].
bool _mentionsMe(Object? value) => switch (value) {
  String() => value == User.currentUserId,
  Map() => value.keys.any(_mentionsMe) || value.values.any(_mentionsMe),
  List() => value.any(_mentionsMe),
  _ => false,
};

Future<void> _settle() => Future<void>.delayed(Duration.zero);

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
  group('stored trades and uids', () {
    test('the local id is stored as the uid, and read back as me', () {
      expect(TradeDocument.uidOf(User.currentUserId, _maha), _maha);
      expect(TradeDocument.uidOf(_sami, _maha), _sami);
      expect(TradeDocument.localIdOf(_maha, _maha), User.currentUserId);
      expect(TradeDocument.isSafeId(User.currentUserId), isFalse);

      final proposal = TradeDocument.proposalData(
        _maha,
        TradeDocument.receiverOf(_maha, _draft()),
        'trade1',
        _draft(),
        DateTime(2026),
      );
      expect(_mentionsMe(proposal), isFalse);
      expect(proposal['senderId'], _maha);
      expect(proposal['participantIds'], [_maha, _sami]);

      final asSami = TradeDocument.proposalFromData(
        'p1',
        proposal,
        viewerUid: _sami,
      )!;
      expect(asSami.senderId, _maha);
      expect(asSami.receiverId, User.currentUserId);
      expect(
        TradeDocument.proposalFromData('p1', proposal, viewerUid: _lina),
        isNull,
      );
    });

    test('proposals to oneself, to me or from someone else are refused', () {
      for (final draft in [
        _draft(to: User.currentUserId),
        _draft(to: _maha),
        _draft(to: 'bad id'),
        _draft(from: _lina),
      ]) {
        expect(
          () => TradeDocument.receiverOf(_maha, draft),
          throwsA(TradeException.invalidTerms),
          reason: '${draft.senderId} to ${draft.receiverId}',
        );
      }
      expect(
        () => TradeDocument.receiverOf(User.currentUserId, _draft()),
        throwsA(TradeException.sessionExpired),
      );
    });

    test('terms need a wanted skill and a skill or credits for it', () {
      for (final draft in [
        _draft(requested: ''),
        _draft(offered: ''),
        _draft(offered: 'x' * 61),
        _draft(credits: -1),
        _draft().copyWith(sessionsMinutes: 5),
      ]) {
        expect(
          () => TradeDocument.termsOf(draft),
          throwsA(TradeException.invalidTerms),
        );
      }
      expect(TradeDocument.termsOf(_draft(offered: '', credits: 20)), {
        'offeredSkill': '',
        'requestedSkill': 'Flutter',
        'sessionsMinutes': 60,
        'deliveryMethod': 'Online',
        'creditsOffered': 20,
      });
    });

    test('each member sees the trade from their own side', () {
      final data = TradeDocument.newTradeData(
        _maha,
        _sami,
        'p1',
        _draft(offered: '', credits: 20),
        DateTime(2026),
      );
      final mine = TradeDocument.tradeFromData(
        't1',
        data,
        viewerUid: _maha,
      )!.trade;
      expect(mine.otherMemberId, _sami);
      expect(mine.creditsPaid, 20);
      expect(mine.requestedSkill, 'Flutter');

      final theirs = TradeDocument.tradeFromData(
        't1',
        data,
        viewerUid: _sami,
      )!.trade;
      expect(theirs.otherMemberId, _maha);
      expect(theirs.offeredSkill, 'Flutter');
      expect(theirs.requestedSkill, '20 credits');
      expect(theirs.creditsPaid, 0);
      expect(TradeDocument.tradeFromData('t1', data, viewerUid: _lina), isNull);
    });
  });

  group('two members, one server', () {
    late DemoTradeRepository server;
    final blocks = <String, Set<String>>{};

    setUp(() {
      blocks.clear();
      server = DemoTradeRepository(
        isRealMember: (uid) => uid != 'uid-gone',
        hasBlocked: (uid, other) => blocks[uid]?.contains(other) ?? false,
      );
    });

    Future<SentProposal> send() => server.sendProposal(_maha, _draft());

    Future<Trade> tradeAs(String uid, String tradeId) async {
      final trades = await server.watchTrades(uid).first;
      return trades.singleWhere((item) => item.trade.id == tradeId).trade;
    }

    Future<void> accept(SentProposal sent) => server.respondToProposal(
      _sami,
      tradeId: sent.tradeId,
      proposalId: sent.proposalId,
      response: ProposalStatus.accepted,
    );

    test('a proposal starts a pending trade both members see', () async {
      final sent = await send();

      expect(_mentionsMe(server.storedTrade(sent.tradeId)), isFalse);
      expect(_mentionsMe(server.storedProposal(sent.proposalId)), isFalse);
      expect((await tradeAs(_maha, sent.tradeId)).status, TradeStatus.pending);
      expect((await tradeAs(_sami, sent.tradeId)).otherMemberId, _maha);
      final [incoming] = await server.watchProposals(_sami).first;
      expect(incoming.receiverId, User.currentUserId);
      expect(incoming.isPending, isTrue);
    });

    test('only the two members see a trade, and only they change it', () async {
      final sent = await send();

      expect(await server.watchTrades(_lina).first, isEmpty);
      expect(await server.watchProposals(_lina).first, isEmpty);
      for (final change in <Future<void> Function()>[
        () => server.respondToProposal(
          _lina,
          tradeId: sent.tradeId,
          proposalId: sent.proposalId,
          response: ProposalStatus.accepted,
        ),
        () => server.counterProposal(
          _lina,
          tradeId: sent.tradeId,
          proposalId: sent.proposalId,
          draft: _draft(),
        ),
        () => server.markDisputed(_lina, sent.tradeId),
      ]) {
        await expectLater(change(), throwsA(TradeException.notFound));
      }
      expect(server.storedTrade(sent.tradeId)!['status'], 'pending');
    });

    test('the receiver accepts or declines; the sender cancels', () async {
      Future<void> respond(String uid, SentProposal sent, ProposalStatus to) =>
          server.respondToProposal(
            uid,
            tradeId: sent.tradeId,
            proposalId: sent.proposalId,
            response: to,
          );

      final first = await send();
      await expectLater(
        respond(_maha, first, ProposalStatus.accepted),
        throwsA(TradeException.notSaved),
      );
      await expectLater(
        respond(_sami, first, ProposalStatus.cancelled),
        throwsA(TradeException.notSaved),
      );
      await respond(_sami, first, ProposalStatus.accepted);
      expect(server.storedTrade(first.tradeId)!['status'], 'accepted');
      expect(server.storedProposal(first.proposalId)!['status'], 'accepted');
      // Answered once only.
      await expectLater(
        respond(_sami, first, ProposalStatus.declined),
        throwsA(TradeException.alreadyAnswered),
      );

      final second = await send();
      await respond(_sami, second, ProposalStatus.declined);
      expect(server.storedTrade(second.tradeId)!['status'], 'declined');

      final third = await send();
      await respond(_maha, third, ProposalStatus.cancelled);
      expect(server.storedTrade(third.tradeId)!['status'], 'cancelled');
      expect(server.storedProposal(third.proposalId)!['status'], 'cancelled');
    });

    test(
      'a counteroffer replaces the terms, and the old one is closed',
      () async {
        final sent = await send();

        final counterId = await server.counterProposal(
          _sami,
          tradeId: sent.tradeId,
          proposalId: sent.proposalId,
          draft: _draft(
            from: User.currentUserId,
            to: _maha,
            offered: 'Flutter',
            requested: 'Sourdough',
          ),
        );

        expect(server.storedProposal(sent.proposalId)!['status'], 'countered');
        final counter = server.storedProposal(counterId)!;
        expect(counter['senderId'], _sami);
        expect(counter['receiverId'], _maha);
        expect(server.storedTrade(sent.tradeId)!['proposalId'], counterId);
        final asMaha = await tradeAs(_maha, sent.tradeId);
        expect(asMaha.offeredSkill, 'Sourdough');
        expect(asMaha.requestedSkill, 'Flutter');
        expect(asMaha.status, TradeStatus.pending);
        // The countered proposal can no longer be accepted; the new one can,
        // by Maha.
        await expectLater(
          accept(sent),
          throwsA(TradeException.alreadyAnswered),
        );
        await server.respondToProposal(
          _maha,
          tradeId: sent.tradeId,
          proposalId: counterId,
          response: ProposalStatus.accepted,
        );
        expect(
          (await tradeAs(_sami, sent.tradeId)).status,
          TradeStatus.accepted,
        );
      },
    );

    test('a session is booked and rescheduled once accepted', () async {
      final sent = await send();
      Future<void> schedule(String uid, DateTime at) => server.scheduleSession(
        uid,
        tradeId: sent.tradeId,
        scheduledAt: at,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );

      await expectLater(
        schedule(_maha, _tomorrow),
        throwsA(TradeException.notSaved),
      );
      await accept(sent);
      await expectLater(
        schedule(_maha, DateTime.now().subtract(const Duration(hours: 1))),
        throwsA(TradeException.pastSession),
      );
      await schedule(_maha, _tomorrow);
      final later = _tomorrow.add(const Duration(days: 2));
      await schedule(_sami, later);

      final [online] = await server.watchTrades(_maha).first;
      expect(online.session!.scheduledAt, later);
      expect(online.trade.sessionId, online.session!.id);
      expect(online.lastChangedByOther, isTrue);
    });

    test('a trade completes only once both members confirmed', () async {
      final sent = await send();
      await accept(sent);
      await expectLater(
        server.confirmCompletion(_maha, sent.tradeId),
        throwsA(TradeException.notSaved),
        reason: 'no session yet',
      );
      await server.scheduleSession(
        _sami,
        tradeId: sent.tradeId,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );

      expect(await server.confirmCompletion(_maha, sent.tradeId), isFalse);
      var asMaha = await tradeAs(_maha, sent.tradeId);
      final asSami = await tradeAs(_sami, sent.tradeId);
      expect(asMaha.status, TradeStatus.accepted);
      expect(asMaha.confirmedByMe, isTrue);
      expect(asSami.confirmedByOther, isTrue);
      expect(asSami.confirmedByMe, isFalse);
      await expectLater(
        server.confirmCompletion(_maha, sent.tradeId),
        throwsA(TradeException.alreadyConfirmed),
      );

      expect(await server.confirmCompletion(_sami, sent.tradeId), isTrue);
      asMaha = await tradeAs(_maha, sent.tradeId);
      expect(asMaha.status, TradeStatus.completed);
      expect(asMaha.confirmedByOther, isTrue);
    });

    test(
      'blocks stop new proposals and acceptance, not ending a trade',
      () async {
        final sent = await send();
        blocks[_sami] = {_maha};

        await expectLater(send(), throwsA(TradeException.notSaved));
        await expectLater(accept(sent), throwsA(TradeException.notSaved));
        await server.respondToProposal(
          _sami,
          tradeId: sent.tradeId,
          proposalId: sent.proposalId,
          response: ProposalStatus.declined,
        );
        expect(server.storedTrade(sent.tradeId)!['status'], 'declined');
        await expectLater(
          server.sendProposal(_maha, _draft(to: 'uid-gone')),
          throwsA(TradeException.notSaved),
        );
      },
    );

    test('changes arrive live on the other member\'s stream', () async {
      final seen = <TradeStatus>[];
      final watch = server
          .watchTrades(_sami)
          .listen(
            (items) => seen.addAll(items.map((item) => item.trade.status)),
          );
      final sent = await send();
      await accept(sent);
      await _settle();
      await watch.cancel();

      expect(seen, [TradeStatus.pending, TradeStatus.accepted]);
    });
  });

  group('trades in the app', () {
    final repository = Repository.instance;
    final originalAuth = AuthService.repository;
    final blocks = <String, Set<String>>{};
    late _Auth auth;
    late DemoTradeRepository trades;
    late DemoChatRepository chats;
    final chatId = 'dm_${_maha}_$_sami';

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      repository.notifications.clear();
      auth = _Auth();
      AuthService.repository = auth;
      AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_maha, _user('Maha', 'maha_z'));
      await profiles.saveProfile(_sami, _user('Sami', 'sami_a'));
      await profiles.saveProfile(_lina, _user('Lina', 'lina_s'));
      AuthService.profiles = profiles;
      blocks.clear();
      bool hasBlocked(String uid, String other) =>
          blocks[uid]?.contains(other) ?? false;
      chats = DemoChatRepository(hasBlocked: hasBlocked);
      trades = DemoTradeRepository(hasBlocked: hasBlocked);
      ChatService.repository = chats;
      OnlineTrades.repository = trades;
      AuthService().signIn();
      await _settle();
    });

    tearDown(() {
      OnlineTrades.repository = null;
      ChatService.repository = null;
      AuthService.profiles = null;
      AuthService.deviceAccount = null;
      AuthService.repository = originalAuth;
    });

    List<AppNotification> notifications(NotificationType type) => [
      for (final item in repository.notifications)
        if (item.type == type) item,
    ];

    /// Maha proposes to Sami; returns the trade as Maha sees it.
    Future<Trade> propose() async {
      await ProposalService().send(_draft());
      await _settle();
      return OnlineTrades.trades().first;
    }

    Future<void> samiAccepts(Trade trade) async {
      await trades.respondToProposal(
        _sami,
        tradeId: trade.id,
        proposalId: trade.proposalId,
        response: ProposalStatus.accepted,
      );
      await _settle();
    }

    Future<void> schedule(Trade trade) async {
      await TradeSessionService().schedule(
        tradeId: trade.id,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      await _settle();
    }

    test('a proposal to a real member is shared online by uid', () async {
      final localProposals = repository.proposals.length;
      final localTrades = repository.trades.length;

      final trade = await propose();

      expect(repository.proposals, hasLength(localProposals));
      expect(repository.trades, hasLength(localTrades));
      expect(trade.otherMemberId, _sami);
      expect(TradeService().byId(trade.id), isNotNull);
      expect(TradeService().all().first.id, trade.id);
      final stored = trades.storedTrade(trade.id)!;
      expect(stored['proposerId'], _maha);
      expect(_mentionsMe(stored), isFalse);
      expect(_mentionsMe(trades.storedProposal(trade.proposalId)), isFalse);
      final proposal = ProposalService().byId(trade.proposalId)!;
      expect(proposal.senderId, User.currentUserId);
      expect(ProposalService().isIncoming(proposal), isFalse);
      // The proposal card is in the shared Phase 1 chat for both members.
      final [card] = chats.storedMessages(chatId);
      expect(card['kind'], 'proposal');
      expect(card['proposalId'], trade.proposalId);
      expect(card['tradeId'], trade.id);
      expect(card['senderId'], _maha);
    });

    test('the other member accepting arrives live and is notified', () async {
      final trade = await propose();

      await samiAccepts(trade);

      expect(TradeService().byId(trade.id)!.status, TradeStatus.accepted);
      expect(
        ProposalService().byId(trade.proposalId)!.status,
        ProposalStatus.accepted,
      );
      final [notice] = notifications(NotificationType.trade);
      expect(notice.title, 'Proposal accepted');
      expect(notice.routeArgument, trade.id);
    });

    test('a counteroffer from the other member is incoming here', () async {
      final trade = await propose();
      final counterId = await trades.counterProposal(
        _sami,
        tradeId: trade.id,
        proposalId: trade.proposalId,
        draft: _draft(to: _maha, offered: 'Flutter', requested: 'Bread'),
      );
      await _settle();

      final counter = ProposalService().byId(counterId)!;
      expect(ProposalService().isIncoming(counter), isTrue);
      expect(
        ProposalService().byId(trade.proposalId)!.status,
        ProposalStatus.countered,
      );

      await ProposalService().accept(counterId);
      await _settle();
      final accepted = TradeService().byId(trade.id)!;
      expect(accepted.status, TradeStatus.accepted);
      expect(accepted.offeredSkill, 'Bread');
      expect(accepted.requestedSkill, 'Flutter');
      expect(
        chats.storedMessages(chatId).map((item) => item['kind']),
        containsAll(['proposal', 'system']),
      );
    });

    test('declining and cancelling close the trade for both', () async {
      final trade = await propose();
      await ProposalService().cancel(trade.proposalId);
      await _settle();
      expect(TradeService().byId(trade.id)!.status, TradeStatus.cancelled);
      expect(trades.storedTrade(trade.id)!['updatedBy'], _maha);

      // Maha cannot decline her own proposal: only the receiver can.
      final second = await propose();
      await expectLater(
        ProposalService().decline(second.proposalId),
        throwsA(TradeException.notSaved),
      );
    });

    test('both members must confirm before the trade completes', () async {
      final trade = await propose();
      await samiAccepts(trade);
      await schedule(trade);
      expect(
        TradeSessionService().byId(TradeService().byId(trade.id)!.sessionId),
        isNotNull,
      );
      final balance = WalletService().balance;

      expect(await TradeService().complete(trade.id), isFalse);
      await _settle();
      var shown = TradeService().byId(trade.id)!;
      expect(shown.status, TradeStatus.accepted);
      expect(shown.confirmedByMe, isTrue);
      expect(notifications(NotificationType.review), isEmpty);
      expect(WalletService().balance, balance);

      expect(await trades.confirmCompletion(_sami, trade.id), isTrue);
      await _settle();
      shown = TradeService().byId(trade.id)!;
      expect(shown.status, TradeStatus.completed);
      expect(TradeSessionService().byId(shown.sessionId)!.isCompleted, isTrue);
      expect(notifications(NotificationType.review), hasLength(1));
      // The local reward is recorded once, however often the trade arrives.
      expect(WalletService().balance, balance + TradeService.completionCredits);
      await propose();
      expect(WalletService().balance, balance + TradeService.completionCredits);
    });

    test('the other member confirming first is notified', () async {
      final trade = await propose();
      await samiAccepts(trade);
      await schedule(trade);

      expect(await trades.confirmCompletion(_sami, trade.id), isFalse);
      await _settle();

      expect(TradeService().byId(trade.id)!.confirmedByOther, isTrue);
      expect(
        notifications(NotificationType.trade).map((item) => item.title),
        contains('Sami Test marked the trade as complete'),
      );
      expect(await TradeService().complete(trade.id), isTrue);
    });

    test('a blocked member cannot be sent proposals or accepted', () async {
      final trade = await propose();
      repository.blockedMemberIds.add(_sami);

      await expectLater(
        ProposalService().send(_draft()),
        throwsA(TradeException.blocked),
      );
      // Blocked by the other member: refused by the server instead.
      repository.blockedMemberIds.remove(_sami);
      blocks[_sami] = {_maha};
      await expectLater(
        ProposalService().send(_draft()),
        throwsA(TradeException.notSaved),
      );
      // Ending the trade stays possible, though no chat note gets through.
      final notes = chats.storedMessages(chatId).length;
      await ProposalService().cancel(trade.proposalId);
      await _settle();
      expect(TradeService().byId(trade.id)!.status, TradeStatus.cancelled);
      expect(chats.storedMessages(chatId), hasLength(notes));
    });

    test('demo members\' trades stay on this device', () async {
      final localProposals = repository.proposals.length;

      await ProposalService().send(_draft(to: _demoSami));
      await _settle();

      expect(repository.proposals, hasLength(localProposals + 1));
      expect(OnlineTrades.trades(), isEmpty);
      final local = repository.trades.last;
      await ProposalService().accept(repository.proposals.last.id);
      expect(TradeService().byId(local.id)!.status, TradeStatus.accepted);
    });

    test('offline, every trade stays on this device as before', () async {
      OnlineTrades.repository = null;
      final localProposals = repository.proposals.length;

      await ProposalService().send(_draft());

      expect(repository.proposals, hasLength(localProposals + 1));
      expect(repository.proposals.last.receiverId, _sami);
      final local = repository.trades.last;
      await ProposalService().accept(repository.proposals.last.id);
      await TradeSessionService().schedule(
        tradeId: local.id,
        scheduledAt: _tomorrow,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      // One member's confirmation completes a trade on this device.
      expect(await TradeService().complete(local.id), isTrue);
      expect(TradeService().byId(local.id)!.status, TradeStatus.completed);
    });

    test(
      'another account signing in does not see the first one\'s trades',
      () async {
        await propose();

        auth.currentUid = _lina;
        OnlineTrades.syncSession();
        await _settle();

        expect(OnlineTrades.trades(), isEmpty);
      },
    );

    test('a loading error is reported and what loaded stays shown', () async {
      final trade = await propose();

      trades.failStreams(
        const TradeException('Check your internet connection.'),
      );
      await _settle();

      expect(OnlineTrades.loadError, 'Check your internet connection.');
      expect(TradeService().byId(trade.id), isNotNull);
    });
  });
}
