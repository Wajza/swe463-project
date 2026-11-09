import 'identifiable.dart';

enum DisputeStatus {
  submitted('Submitted'),
  underReview('Under review'),
  awaitingResponse('Awaiting response'),
  resolved('Resolved'),
  closed('Closed');

  const DisputeStatus(this.label);
  final String label;
}

enum CaseKind {
  memberReport('Member report'),
  tradeReport('Trade report'),
  tradeDispute('Trade dispute'),
  complaint('Complaint');

  const CaseKind(this.label);
  final String label;
}

class DisputeCase implements Identifiable {
  const DisputeCase({
    required this.id,
    required this.caseNumber,
    required this.kind,
    required this.reason,
    required this.createdAt,
    this.tradeId,
    this.memberId,
    this.status = DisputeStatus.submitted,
  });

  @override
  final String id;
  final String caseNumber;
  final CaseKind kind;
  final String reason;
  final DateTime createdAt;
  final String? tradeId;
  final String? memberId;
  final DisputeStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseNumber': caseNumber,
    'kind': kind.name,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'tradeId': tradeId,
    'memberId': memberId,
    'status': status.name,
  };

  factory DisputeCase.fromJson(Map<String, dynamic> json) => DisputeCase(
    id: json['id'] as String,
    caseNumber: json['caseNumber'] as String,
    kind: CaseKind.values.byName(json['kind'] as String),
    reason: json['reason'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    tradeId: json['tradeId'] as String?,
    memberId: json['memberId'] as String?,
    status: DisputeStatus.values.byName(json['status'] as String),
  );
}
