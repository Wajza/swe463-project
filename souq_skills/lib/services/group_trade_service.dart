import '../models/group_trade.dart';
import 'repository.dart';

class GroupTradeService {
  GroupTradeService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<GroupTrade>> getGroupTrades() async => List.unmodifiable(_repository.groupTrades);
  Future<GroupTrade> create(GroupTrade trade) async { _repository.groupTrades.add(trade); _repository.emitChange(); return trade; }
  Future<GroupTrade?> update(GroupTrade trade) async {
    final index = _repository.groupTrades.indexWhere((item) => item.id == trade.id);
    if (index < 0) return null;
    _repository.groupTrades[index] = trade;
    _repository.emitChange();
    return trade;
  }
  Future<void> delete(String id) async { _repository.groupTrades.removeWhere((trade) => trade.id == id); _repository.emitChange(); }
}
