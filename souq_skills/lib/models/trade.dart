enum TradeStatus { pending, accepted, completed, declined, cancelled, disputed }

class Trade {
  const Trade({
    required this.offeredSkill,
    required this.requestedSkill,
    this.id = '',
    this.otherMemberName = '',
    this.status = TradeStatus.pending,
    this.isComplete = false,
    this.sessionId,
  });

  final String id;
  final String offeredSkill;
  final String requestedSkill;
  final String otherMemberName;
  final TradeStatus status;
  final bool isComplete;
  final String? sessionId;

  Trade copyWith({
    String? id, String? offeredSkill, String? requestedSkill,
    String? otherMemberName, TradeStatus? status, bool? isComplete,
    String? sessionId,
  }) => Trade(
    id: id ?? this.id, offeredSkill: offeredSkill ?? this.offeredSkill,
    requestedSkill: requestedSkill ?? this.requestedSkill,
    otherMemberName: otherMemberName ?? this.otherMemberName,
    status: status ?? this.status, isComplete: isComplete ?? this.isComplete,
    sessionId: sessionId ?? this.sessionId,
  );
}
