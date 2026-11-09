import 'identifiable.dart';

enum ProposalStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  countered('Countered'),
  cancelled('Cancelled');

  const ProposalStatus(this.label);
  final String label;
}

/// [offeredSkill] and [requestedSkill] are from the sender's point of view.
class TradeProposal implements Identifiable {
  const TradeProposal({
    required this.senderId,
    required this.receiverId,
    this.offeredSkill = '',
    this.requestedSkill = '',
    this.id = '',
    this.tradeId = '',
    this.sessionsMinutes = 60,
    this.deliveryMethod = 'Online',
    this.notes = '',
    this.status = ProposalStatus.pending,
  });

  @override
  final String id;
  final String tradeId;
  final String offeredSkill;
  final String requestedSkill;
  final String senderId;
  final String receiverId;
  final int sessionsMinutes;
  final String deliveryMethod;
  final String notes;
  final ProposalStatus status;

  bool get isPending => status == ProposalStatus.pending;

  TradeProposal copyWith({
    String? id,
    String? tradeId,
    String? offeredSkill,
    String? requestedSkill,
    String? senderId,
    String? receiverId,
    int? sessionsMinutes,
    String? deliveryMethod,
    String? notes,
    ProposalStatus? status,
  }) => TradeProposal(
    id: id ?? this.id,
    tradeId: tradeId ?? this.tradeId,
    offeredSkill: offeredSkill ?? this.offeredSkill,
    requestedSkill: requestedSkill ?? this.requestedSkill,
    senderId: senderId ?? this.senderId,
    receiverId: receiverId ?? this.receiverId,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    deliveryMethod: deliveryMethod ?? this.deliveryMethod,
    notes: notes ?? this.notes,
    status: status ?? this.status,
  );
}
