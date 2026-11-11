import 'package:souq_skills/models/transaction.dart';

import 'repository.dart';
import 'trade_service.dart';

class WalletService {
  final Repository _repo = Repository.instance;

  int get balance =>
      _repo.transactions.fold(0, (sum, item) => sum + item.amount);

  /// Credits promised to active trades, which are paid when a trade completes.
  int heldCredits({String? excludingTradeId}) => TradeService()
      .all()
      .where((trade) => trade.isActive && trade.id != excludingTradeId)
      .fold(0, (sum, trade) => sum + trade.creditsPaid);

  int availableCredits({String? excludingTradeId}) =>
      balance - heldCredits(excludingTradeId: excludingTradeId);

  List<WalletTransaction> transactions() =>
      _repo.transactions.toList()..sort((a, b) => b.date.compareTo(a.date));

  WalletTransaction? byId(String id) => _repo.find(_repo.transactions, id);

  void record({
    required String title,
    required String subtitle,
    required int amount,
    TransactionType type = TransactionType.earned,
    String? tradeId,
    String? participantName,
  }) => _repo.insert(
    _repo.transactions,
    WalletTransaction(
      id: _repo.nextId('tx'),
      title: title,
      subtitle: subtitle,
      amount: amount,
      type: type,
      date: DateTime.now(),
      tradeId: tradeId,
      participantName: participantName,
    ),
  );
}
