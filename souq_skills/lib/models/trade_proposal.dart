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
    this.creditsOffered = 0,
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
  final int creditsOffered;
  final ProposalStatus status;

  bool get isPending => status == ProposalStatus.pending;

  String get offerLabel =>
      creditsOffered > 0 ? '$creditsOffered credits' : offeredSkill;

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
    int? creditsOffered,
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
    creditsOffered: creditsOffered ?? this.creditsOffered,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tradeId': tradeId,
    'offeredSkill': offeredSkill,
    'requestedSkill': requestedSkill,
    'senderId': senderId,
    'receiverId': receiverId,
    'sessionsMinutes': sessionsMinutes,
    'deliveryMethod': deliveryMethod,
    'notes': notes,
    'creditsOffered': creditsOffered,
    'status': status.name,
  };

  factory TradeProposal.fromJson(Map<String, dynamic> json) => TradeProposal(
    id: json['id'] as String,
    tradeId: json['tradeId'] as String,
    offeredSkill: json['offeredSkill'] as String,
    requestedSkill: json['requestedSkill'] as String,
    senderId: json['senderId'] as String,
    receiverId: json['receiverId'] as String,
    sessionsMinutes: json['sessionsMinutes'] as int,
    deliveryMethod: json['deliveryMethod'] as String,
    notes: json['notes'] as String,
    creditsOffered: json['creditsOffered'] as int,
    status: ProposalStatus.values.byName(json['status'] as String),
  );
}
