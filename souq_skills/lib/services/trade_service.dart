import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/transaction.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'repository.dart';
import 'wallet_service.dart';

class TradeService {
  static const completionCredits = 10;

  final Repository _repo = Repository.instance;

  Trade? byId(String id) => _repo.find(_repo.trades, id);

  List<Trade> active() =>
      _repo.trades.reversed.where((trade) => trade.isActive).toList();

  List<Trade> all() => _repo.trades.reversed.toList();

  int completedCount() =>
      _repo.trades.where((trade) => trade.isComplete).length;

  /// Finishes a trade: closes its session, pays credits and asks for a rating.
  void complete(String id) {
    final trade = byId(id);
    if (trade == null || trade.status != TradeStatus.accepted) return;
    _repo.update(
      _repo.trades,
      id,
      (current) => current.copyWith(status: TradeStatus.completed),
    );
    final sessionId = trade.sessionId;
    if (sessionId != null) {
      _repo.update(
        _repo.sessions,
        sessionId,
        (session) => session.copyWith(isCompleted: true),
      );
    }
    final memberName = MemberService().nameOf(trade.otherMemberId);
    WalletService().record(
      title: 'Trade completed',
      subtitle: trade.title,
      amount: completionCredits,
      tradeId: id,
      participantName: memberName,
    );
    if (trade.creditsPaid > 0) {
      WalletService().record(
        title: 'Credits paid',
        subtitle: trade.title,
        amount: -trade.creditsPaid,
        type: TransactionType.spent,
        tradeId: id,
        participantName: memberName,
      );
    }
    ChatService().postSystem(trade.otherMemberId, 'Trade marked as complete.');
    NotificationService().push(
      title: 'How was your exchange?',
      message: 'Rate your trade with $memberName to share your experience.',
      type: NotificationType.review,
      route: AppRoutes.rateTrade,
      routeArgument: id,
    );
    BadgeService().sync();
  }
}
