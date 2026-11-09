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
  tradeDispute('Trade dispute');

  const CaseKind(this.label);
  final String label;
}

class DisputeCase implements Identifiable {
  const DisputeCase({
    required this.id,
    required this.caseNumber,
    required this.kind,
    required this.reason,
    required this.details,
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
  final String details;
  final DateTime createdAt;
  final String? tradeId;
  final String? memberId;
  final DisputeStatus status;
}
