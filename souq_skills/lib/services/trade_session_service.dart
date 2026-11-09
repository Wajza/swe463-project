import '../models/trade_session.dart';
import 'repository.dart';

class TradeSessionService {
  TradeSessionService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<TradeSession>> getSessions(String tradeId) async => _repository.sessions.where((item) => item.tradeId == tradeId).toList();
  Future<TradeSession> schedule(TradeSession session) async { _repository.sessions.add(session); _repository.emitChange(); return session; }
  Future<void> complete(TradeSession session) async {
    final index = _repository.sessions.indexWhere((item) => item.id == session.id);
    if (index < 0) return;
    _repository.sessions[index] = session.copyWith(isCompleted: true);
    _repository.emitChange();
  }
}
