import 'identifiable.dart';

enum TradeStatus {
  pending('Pending'),
  accepted('Accepted'),
  completed('Completed'),
  declined('Declined'),
  cancelled('Cancelled'),
  disputed('Disputed');

  const TradeStatus(this.label);
  final String label;
}

/// A skill exchange seen from the current user's side: [offeredSkill] is what
/// they give and [requestedSkill] is what they receive.
class Trade implements Identifiable {
  const Trade({
    required this.id,
    required this.proposalId,
    required this.otherMemberId,
    required this.offeredSkill,
    required this.requestedSkill,
    this.sessionsMinutes = 60,
    this.status = TradeStatus.pending,
    this.sessionId,
  });

  @override
  final String id;
  final String proposalId;
  final String otherMemberId;
  final String offeredSkill;
  final String requestedSkill;
  final int sessionsMinutes;
  final TradeStatus status;
  final String? sessionId;

  bool get isComplete => status == TradeStatus.completed;
  bool get isActive =>
      status == TradeStatus.pending ||
      status == TradeStatus.accepted ||
      status == TradeStatus.disputed;
  String get title => '$offeredSkill ⇄ $requestedSkill';

  Trade copyWith({
    String? proposalId,
    String? offeredSkill,
    String? requestedSkill,
    int? sessionsMinutes,
    TradeStatus? status,
    String? sessionId,
  }) => Trade(
    id: id,
    proposalId: proposalId ?? this.proposalId,
    otherMemberId: otherMemberId,
    offeredSkill: offeredSkill ?? this.offeredSkill,
    requestedSkill: requestedSkill ?? this.requestedSkill,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    status: status ?? this.status,
    sessionId: sessionId ?? this.sessionId,
  );
}
