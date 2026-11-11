import 'package:souq_skills/models/transaction.dart';

import 'online_trades.dart';
import 'online_wallet.dart';
import 'repository.dart';
import 'trade_service.dart';

/// The current member's credits: online, from the server's ledger, for a
/// signed-in account ([OnlineWallet]); otherwise on this device, as before.
class WalletService {
  final Repository _repo = Repository.instance;

  int get balance => OnlineWallet.isActive
      ? OnlineWallet.balance
      : _repo.transactions.fold(0, (sum, item) => sum + item.amount);

  /// Credits promised to active trades, which are paid when a trade
  /// completes: those paid from this wallet.
  int heldCredits({String? excludingTradeId}) =>
      (OnlineWallet.isActive ? OnlineTrades.trades() : TradeService().all())
          .where((trade) => trade.isActive && trade.id != excludingTradeId)
          .fold(0, (sum, trade) => sum + trade.creditsPaid);

  int availableCredits({String? excludingTradeId}) =>
      balance - heldCredits(excludingTradeId: excludingTradeId);

  List<WalletTransaction> transactions() => OnlineWallet.isActive
      ? OnlineWallet.transactions()
      : (_repo.transactions.toList()..sort((a, b) => b.date.compareTo(a.date)));

  WalletTransaction? byId(String id) => _repo.find(transactions(), id);

  /// Records a change on this device's wallet, such as for a trade with a
  /// demo member. The online wallet only changes on the server.
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
