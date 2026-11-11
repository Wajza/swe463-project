import 'package:souq_skills/models/trade_session.dart';

import 'chat_service.dart';
import 'online_trades.dart';
import 'repository.dart';
import 'trade_service.dart';

class TradeSessionService {
  final Repository _repo = Repository.instance;

  TradeSession? byId(String? id) =>
      _repo.find(_repo.sessions, id) ?? OnlineTrades.session(id);

  /// Books the trade's session, or reschedules the existing one. For a
  /// trade with a real member this is saved online, where either member
  /// can do it; throws a [TradeException] if that failed.
  Future<void> schedule({
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  }) {
    final online = OnlineTrades.trade(tradeId);
    if (online != null) {
      return _scheduleOnline(
        online.otherMemberId,
        tradeId: tradeId,
        scheduledAt: scheduledAt,
        method: method,
        locationOrLink: locationOrLink,
        notes: notes,
      );
    }
    final trade = TradeService().byId(tradeId);
    if (trade == null) return Future.value();
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
    return Future.value();
  }

  Future<void> _scheduleOnline(
    String memberId, {
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  }) async {
    final (repository, uid) = OnlineTrades.signedIn();
    OnlineTrades.checkNotBlocked(memberId);
    await repository.scheduleSession(
      uid,
      tradeId: tradeId,
      scheduledAt: scheduledAt,
      method: method,
      locationOrLink: locationOrLink,
      notes: notes,
    );
    await OnlineTrades.postToChat(
      memberId,
      'Session scheduled.',
      tradeId: tradeId,
    );
  }
}
