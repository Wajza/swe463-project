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
    this.creditsPaid = 0,
    this.status = TradeStatus.pending,
    this.sessionId,
    this.confirmedByMe = false,
    this.confirmedByOther = false,
  });

  @override
  final String id;
  final String proposalId;
  final String otherMemberId;
  final String offeredSkill;
  final String requestedSkill;
  final int sessionsMinutes;

  /// Credits the current user pays in place of a skill.
  final int creditsPaid;
  final TradeStatus status;
  final String? sessionId;

  /// Whether the current user, and the other member, confirmed the
  /// exchange happened. A shared trade is completed once both have.
  final bool confirmedByMe;
  final bool confirmedByOther;

  bool get isComplete => status == TradeStatus.completed;
  bool get isActive =>
      status == TradeStatus.pending ||
      status == TradeStatus.accepted ||
      status == TradeStatus.disputed;
  String get givenLabel =>
      creditsPaid > 0 ? '$creditsPaid credits' : offeredSkill;
  String get title => '$givenLabel ⇄ $requestedSkill';

  Trade copyWith({
    String? proposalId,
    String? offeredSkill,
    String? requestedSkill,
    int? sessionsMinutes,
    int? creditsPaid,
    TradeStatus? status,
    String? sessionId,
    bool? confirmedByMe,
    bool? confirmedByOther,
  }) => Trade(
    id: id,
    proposalId: proposalId ?? this.proposalId,
    otherMemberId: otherMemberId,
    offeredSkill: offeredSkill ?? this.offeredSkill,
    requestedSkill: requestedSkill ?? this.requestedSkill,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    creditsPaid: creditsPaid ?? this.creditsPaid,
    status: status ?? this.status,
    sessionId: sessionId ?? this.sessionId,
    confirmedByMe: confirmedByMe ?? this.confirmedByMe,
    confirmedByOther: confirmedByOther ?? this.confirmedByOther,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'proposalId': proposalId,
    'otherMemberId': otherMemberId,
    'offeredSkill': offeredSkill,
    'requestedSkill': requestedSkill,
    'sessionsMinutes': sessionsMinutes,
    'creditsPaid': creditsPaid,
    'status': status.name,
    'sessionId': sessionId,
    'confirmedByMe': confirmedByMe,
    'confirmedByOther': confirmedByOther,
  };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    id: json['id'] as String,
    proposalId: json['proposalId'] as String,
    otherMemberId: json['otherMemberId'] as String,
    offeredSkill: json['offeredSkill'] as String,
    requestedSkill: json['requestedSkill'] as String,
    sessionsMinutes: json['sessionsMinutes'] as int,
    creditsPaid: json['creditsPaid'] as int,
    status: TradeStatus.values.byName(json['status'] as String),
    sessionId: json['sessionId'] as String?,
    // Missing from data saved before confirmations existed.
    confirmedByMe: json['confirmedByMe'] as bool? ?? false,
    confirmedByOther: json['confirmedByOther'] as bool? ?? false,
  );
}
