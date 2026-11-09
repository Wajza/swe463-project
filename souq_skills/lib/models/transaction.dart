import 'identifiable.dart';

enum TransactionType {
  earned('Earned'),
  spent('Spent'),
  refund('Refund'),
  adjustment('Adjustment');

  const TransactionType(this.label);
  final String label;
}

class WalletTransaction implements Identifiable {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.subtitle = '',
    this.type = TransactionType.earned,
    this.tradeId,
    this.participantName,
  });

  @override
  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime date;
  final TransactionType type;
  final String? tradeId;
  final String? participantName;
}
