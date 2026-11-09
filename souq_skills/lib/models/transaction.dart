enum TransactionType { earned, spent, refund, adjustment }

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.amount,
    this.id = '',
    this.subtitle = '',
    this.date,
    this.type = TransactionType.earned,
    this.tradeId,
    this.participantName,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime? date;
  final TransactionType type;
  final String? tradeId;
  final String? participantName;
}
