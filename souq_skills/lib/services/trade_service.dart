import '../models/trade.dart';
import '../models/trade_proposal.dart';
import 'repository.dart';

class TradeService {
  TradeService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<Trade>> getTrades() async => List.unmodifiable(_repository.trades);
  Future<Trade> createTrade(TradeProposal proposal) async {
    final trade = Trade(offeredSkill: proposal.offeredSkill, requestedSkill: proposal.requestedSkill, status: TradeStatus.pending);
    _repository.trades.add(trade);
    _repository.emitChange();
    return trade;
  }
  Future<void> updateStatus(Trade trade, TradeStatus status) async {
    final index = _repository.trades.indexWhere((item) => item.id == trade.id);
    if (index < 0) return;
    _repository.trades[index] = trade.copyWith(status: status, isComplete: status == TradeStatus.completed);
    _repository.emitChange();
  }
}
