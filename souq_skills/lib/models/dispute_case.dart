enum DisputeStatus { submitted, underReview, awaitingResponse, resolved, closed }

class DisputeCase {
  const DisputeCase({
    required this.reason,
    required this.details,
    this.id = '',
    this.tradeId,
    this.memberId,
    this.status = DisputeStatus.submitted,
    this.caseNumber = '',
    this.createdAt,
  });

  final String id;
  final String caseNumber;
  final String reason;
  final String details;
  final String? tradeId;
  final String? memberId;
  final DisputeStatus status;
  final DateTime? createdAt;
}
