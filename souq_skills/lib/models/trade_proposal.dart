enum ProposalStatus { pending, accepted, declined, countered, cancelled }

class TradeProposal {
  const TradeProposal({
    required this.offeredSkill,
    required this.requestedSkill,
    this.id = '',
    this.senderId = '',
    this.receiverId = '',
    this.sessionsMinutes = 60,
    this.deliveryMethod = 'Online',
    this.notes = '',
    this.status = ProposalStatus.pending,
  });

  final String id;
  final String offeredSkill;
  final String requestedSkill;
  final String senderId;
  final String receiverId;
  final int sessionsMinutes;
  final String deliveryMethod;
  final String notes;
  final ProposalStatus status;
}
