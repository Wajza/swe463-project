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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.name,
    'tradeId': tradeId,
    'participantName': participantName,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: json['amount'] as int,
        date: DateTime.parse(json['date'] as String),
        type: TransactionType.values.byName(json['type'] as String),
        tradeId: json['tradeId'] as String?,
        participantName: json['participantName'] as String?,
      );
}
