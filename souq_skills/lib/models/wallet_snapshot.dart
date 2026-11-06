enum WalletActivityKind { earned, spent, bonus, group }

class WalletActivity {
  const WalletActivity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateLabel,
    required this.reference,
    required this.kind,
    this.status = 'Completed',
  });

  final String title;
  final String subtitle;
  final int amount;
  final String dateLabel;
  final String reference;
  final WalletActivityKind kind;
  final String status;

  String get amountLabel => amount > 0 ? '+$amount' : '$amount';
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.earned,
    required this.spent,
    required this.transactions,
  });

  final int balance;
  final int earned;
  final int spent;
  final List<WalletActivity> transactions;
}
