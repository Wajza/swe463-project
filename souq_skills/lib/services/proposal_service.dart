import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';

import 'chat_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'notification_service.dart';
import 'online_trades.dart';
import 'repository.dart';

/// Proposals kept on this device (demo members and the offline demo) and
/// proposals with real members, kept online by [OnlineTrades]. The changes
/// throw a [TradeException] if they could not be saved online.
class ProposalService {
  final Repository _repo = Repository.instance;

  TradeProposal? byId(String id) =>
      _repo.find(_repo.proposals, id) ?? OnlineTrades.proposal(id);

  bool isIncoming(TradeProposal proposal) =>
      proposal.receiverId == User.currentUserId;

  String otherMemberId(TradeProposal proposal) =>
      isIncoming(proposal) ? proposal.senderId : proposal.receiverId;

  /// The current user's side of a counteroffer to [proposal].
  TradeProposal counterDraft(TradeProposal proposal) => isIncoming(proposal)
      ? proposal.copyWith(
          offeredSkill: proposal.requestedSkill,
          requestedSkill: proposal.offeredSkill,
        )
      : proposal;

  /// Starts a pending trade from a proposal the current user wrote.
  Future<void> send(TradeProposal draft) {
    if (OnlineTrades.isOnlineMember(draft.receiverId)) {
      return _sendOnline(draft);
    }
    final proposal = draft.copyWith(
      id: _repo.nextId('p'),
      tradeId: _repo.nextId('t'),
    );
    _repo.insert(_repo.proposals, proposal);
    _repo.insert(
      _repo.trades,
      Trade(
        id: proposal.tradeId,
        proposalId: proposal.id,
        otherMemberId: proposal.receiverId,
        offeredSkill: proposal.offeredSkill,
        requestedSkill: proposal.requestedSkill,
        sessionsMinutes: proposal.sessionsMinutes,
        creditsPaid: proposal.creditsOffered,
      ),
    );
    _postAndAwaitReply(proposal);
    return Future.value();
  }

  /// Replaces [originalId] with the current user's new terms on the same trade.
  Future<void> counter(String originalId, TradeProposal draft) {
    final online = OnlineTrades.proposal(originalId);
    if (online != null) return _counterOnline(online, draft);
    final original = _repo.find(_repo.proposals, originalId);
    if (original == null || !original.isPending) return Future.value();
    _setStatus(originalId, ProposalStatus.countered);
    final proposal = draft.copyWith(
      id: _repo.nextId('p'),
      tradeId: original.tradeId,
      senderId: User.currentUserId,
      receiverId: otherMemberId(original),
      status: ProposalStatus.pending,
    );
    _repo.insert(_repo.proposals, proposal);
    _repo.update(
      _repo.trades,
      original.tradeId,
      (trade) => trade.copyWith(
        proposalId: proposal.id,
        offeredSkill: proposal.offeredSkill,
        requestedSkill: proposal.requestedSkill,
        sessionsMinutes: proposal.sessionsMinutes,
        creditsPaid: proposal.creditsOffered,
      ),
    );
    _postAndAwaitReply(proposal);
    return Future.value();
  }

  Future<void> accept(String id, {bool byOtherMember = false}) {
    final online = OnlineTrades.proposal(id);
    if (online != null) {
      return _respondOnline(
        online,
        ProposalStatus.accepted,
        'Proposal accepted. The next step is to schedule a session.',
      );
    }
    final proposal = _repo.find(_repo.proposals, id);
    if (proposal == null || !proposal.isPending) return Future.value();
    _setStatus(id, ProposalStatus.accepted);
    _setTradeStatus(proposal, TradeStatus.accepted);
    final memberId = otherMemberId(proposal);
    ChatService().postSystem(
      memberId,
      'Proposal accepted. The next step is to schedule a session.',
    );
    if (byOtherMember) {
      NotificationService().push(
        title: 'Proposal accepted',
        message: '${MemberService().nameOf(memberId)} accepted your proposal.',
        type: NotificationType.trade,
        route: AppRoutes.tradeDetails,
        routeArgument: proposal.tradeId,
      );
    }
    return Future.value();
  }

  Future<void> decline(String id) => _close(
    id,
    ProposalStatus.declined,
    TradeStatus.declined,
    'Proposal declined.',
  );

  Future<void> cancel(String id) => _close(
    id,
    ProposalStatus.cancelled,
    TradeStatus.cancelled,
    'Proposal cancelled.',
  );

  Future<void> _close(
    String id,
    ProposalStatus proposalStatus,
    TradeStatus tradeStatus,
    String chatNote,
  ) {
    final online = OnlineTrades.proposal(id);
    if (online != null) return _respondOnline(online, proposalStatus, chatNote);
    final proposal = _repo.find(_repo.proposals, id);
    if (proposal == null || !proposal.isPending) return Future.value();
    _setStatus(id, proposalStatus);
    _setTradeStatus(proposal, tradeStatus);
    ChatService().postSystem(otherMemberId(proposal), chatNote);
    return Future.value();
  }

  Future<void> _sendOnline(TradeProposal draft) async {
    final (online, uid) = OnlineTrades.signedIn();
    OnlineTrades.checkNotBlocked(draft.receiverId);
    final sent = await online.sendProposal(uid, draft);
    await OnlineTrades.postToChat(
      draft.receiverId,
      'Trade proposal',
      tradeId: sent.tradeId,
      proposalId: sent.proposalId,
    );
  }

  Future<void> _counterOnline(
    TradeProposal original,
    TradeProposal draft,
  ) async {
    final (online, uid) = OnlineTrades.signedIn();
    final memberId = otherMemberId(original);
    OnlineTrades.checkNotBlocked(memberId);
    final proposalId = await online.counterProposal(
      uid,
      tradeId: original.tradeId,
      proposalId: original.id,
      draft: draft,
    );
    await OnlineTrades.postToChat(
      memberId,
      'Trade proposal',
      tradeId: original.tradeId,
      proposalId: proposalId,
    );
  }

  Future<void> _respondOnline(
    TradeProposal proposal,
    ProposalStatus response,
    String chatNote,
  ) async {
    final (online, uid) = OnlineTrades.signedIn();
    final memberId = otherMemberId(proposal);
    // Declining or cancelling stays possible after a block.
    if (response == ProposalStatus.accepted) {
      OnlineTrades.checkNotBlocked(memberId);
    }
    await online.respondToProposal(
      uid,
      tradeId: proposal.tradeId,
      proposalId: proposal.id,
      response: response,
    );
    await OnlineTrades.postToChat(
      memberId,
      chatNote,
      tradeId: proposal.tradeId,
    );
  }

  void _postAndAwaitReply(TradeProposal proposal) {
    ChatService().post(
      proposal.receiverId,
      'Trade proposal',
      proposalId: proposal.id,
    );
    MemberSimulator().acceptProposal(proposal.id);
  }

  void _setStatus(String id, ProposalStatus status) => _repo.update(
    _repo.proposals,
    id,
    (item) => item.copyWith(status: status),
  );

  void _setTradeStatus(TradeProposal proposal, TradeStatus status) =>
      _repo.update(
        _repo.trades,
        proposal.tradeId,
        (trade) => trade.copyWith(status: status),
      );
}
