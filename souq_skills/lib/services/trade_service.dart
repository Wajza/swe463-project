import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/transaction.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'online_trades.dart';
import 'repository.dart';
import 'wallet_service.dart';

/// Trades kept on this device (demo members and the offline demo) and
/// trades with real members, kept online by [OnlineTrades].
class TradeService {
  static const completionCredits = 10;

  final Repository _repo = Repository.instance;

  Trade? byId(String id) =>
      _repo.find(_repo.trades, id) ?? OnlineTrades.trade(id);

  List<Trade> active() => all().where((trade) => trade.isActive).toList();

  List<Trade> all() => [...OnlineTrades.trades(), ..._repo.trades.reversed];

  int completedCount() => all().where((trade) => trade.isComplete).length;

  /// The current user confirms the exchange happened; returns whether the
  /// trade is now completed. A trade with a real member needs both members
  /// to confirm; a demo member's trade completes straight away, as before.
  /// Throws a [TradeException] if it could not be saved.
  Future<bool> complete(String id) async {
    if (OnlineTrades.trade(id) != null) return _confirmOnline(id);
    final trade = _repo.find(_repo.trades, id);
    if (trade == null || trade.status != TradeStatus.accepted) return false;
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
    recordCompletion(trade, syncBadges: false);
    ChatService().postSystem(trade.otherMemberId, 'Trade marked as complete.');
    askForRating(trade);
    BadgeService().sync();
    return true;
  }

  Future<bool> _confirmOnline(String id) async {
    final trade = OnlineTrades.trade(id)!;
    final (online, uid) = OnlineTrades.signedIn();
    final completed = await online.confirmCompletion(uid, id);
    await OnlineTrades.postToChat(
      trade.otherMemberId,
      completed
          ? 'Trade marked as complete.'
          : 'Marked the trade as complete. Waiting for the other member to '
                'confirm.',
      tradeId: id,
    );
    return completed;
  }

  /// Marks an accepted trade with a real member as disputed online. Trades
  /// on this device are marked by the safety service, as before. Throws a
  /// [TradeException].
  Future<void> markDisputedOnline(String id) async {
    if (OnlineTrades.trade(id) == null) return;
    final (online, uid) = OnlineTrades.signedIn();
    await online.markDisputed(uid, id);
  }

  /// Records the current user's side of completed [trade] in their wallet
  /// on this device, once: the completion reward and any credits paid.
  /// Moving credits between members online is not done yet.
  void recordCompletion(Trade trade, {bool syncBadges = true}) {
    final recorded = _repo.transactions.any(
      (item) => item.tradeId == trade.id && item.title == 'Trade completed',
    );
    if (recorded) return;
    final memberName = MemberService().nameOf(trade.otherMemberId);
    WalletService().record(
      title: 'Trade completed',
      subtitle: trade.title,
      amount: completionCredits,
      tradeId: trade.id,
      participantName: memberName,
    );
    if (trade.creditsPaid > 0) {
      WalletService().record(
        title: 'Credits paid',
        subtitle: trade.title,
        amount: -trade.creditsPaid,
        type: TransactionType.spent,
        tradeId: trade.id,
        participantName: memberName,
      );
    }
    if (syncBadges) BadgeService().sync();
  }

  void askForRating(Trade trade) {
    final memberName = MemberService().nameOf(trade.otherMemberId);
    NotificationService().push(
      title: 'How was your exchange?',
      message: 'Rate your trade with $memberName to share your experience.',
      type: NotificationType.review,
      route: AppRoutes.rateTrade,
      routeArgument: trade.id,
    );
  }
}
