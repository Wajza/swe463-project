import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';

import 'chat_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'notification_service.dart';
import 'repository.dart';

class ProposalService {
  final Repository _repo = Repository.instance;

  TradeProposal? byId(String id) => _repo.find(_repo.proposals, id);

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
  void send(TradeProposal draft) {
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
  }

  /// Replaces [originalId] with the current user's new terms on the same trade.
  void counter(String originalId, TradeProposal draft) {
    final original = byId(originalId);
    if (original == null || !original.isPending) return;
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
  }

  void accept(String id, {bool byOtherMember = false}) {
    final proposal = byId(id);
    if (proposal == null || !proposal.isPending) return;
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
  }

  void decline(String id) => _close(
    id,
    ProposalStatus.declined,
    TradeStatus.declined,
    'Proposal declined.',
  );

  void cancel(String id) => _close(
    id,
    ProposalStatus.cancelled,
    TradeStatus.cancelled,
    'Proposal cancelled.',
  );

  void _close(
    String id,
    ProposalStatus proposalStatus,
    TradeStatus tradeStatus,
    String chatNote,
  ) {
    final proposal = byId(id);
    if (proposal == null || !proposal.isPending) return;
    _setStatus(id, proposalStatus);
    _setTradeStatus(proposal, tradeStatus);
    ChatService().postSystem(otherMemberId(proposal), chatNote);
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
