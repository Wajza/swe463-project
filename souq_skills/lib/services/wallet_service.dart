import 'package:souq_skills/models/transaction.dart';

import 'repository.dart';

class WalletService {
  final Repository _repo = Repository.instance;

  int get balance =>
      _repo.transactions.fold(0, (sum, item) => sum + item.amount);

  List<WalletTransaction> transactions() =>
      _repo.transactions.toList()..sort((a, b) => b.date.compareTo(a.date));

  WalletTransaction? byId(String id) => _repo.find(_repo.transactions, id);

  void record({
    required String title,
    required String subtitle,
    required int amount,
    String? tradeId,
    String? participantName,
  }) => _repo.insert(
    _repo.transactions,
    WalletTransaction(
      id: _repo.nextId('tx'),
      title: title,
      subtitle: subtitle,
      amount: amount,
      date: DateTime.now(),
      tradeId: tradeId,
      participantName: participantName,
    ),
  );
}
