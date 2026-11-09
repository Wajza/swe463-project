import 'package:souq_skills/models/trade_session.dart';

import 'chat_service.dart';
import 'repository.dart';
import 'trade_service.dart';

class TradeSessionService {
  final Repository _repo = Repository.instance;

  TradeSession? byId(String? id) => _repo.find(_repo.sessions, id);

  /// Books the trade's session, or reschedules the existing one.
  void schedule({
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  }) {
    final trade = TradeService().byId(tradeId);
    if (trade == null) return;
    final existingId = trade.sessionId;
    if (existingId != null) {
      _repo.update(
        _repo.sessions,
        existingId,
        (session) => session.copyWith(
          scheduledAt: scheduledAt,
          method: method,
          locationOrLink: locationOrLink,
          notes: notes,
        ),
      );
    } else {
      final session = TradeSession(
        id: _repo.nextId('s'),
        tradeId: tradeId,
        scheduledAt: scheduledAt,
        method: method,
        locationOrLink: locationOrLink,
        notes: notes,
      );
      _repo.insert(_repo.sessions, session);
      _repo.update(
        _repo.trades,
        tradeId,
        (current) => current.copyWith(sessionId: session.id),
      );
    }
    ChatService().postSystem(trade.otherMemberId, 'Session scheduled.');
  }
}
