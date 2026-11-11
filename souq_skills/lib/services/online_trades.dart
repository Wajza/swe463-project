import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'badge_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'repository.dart';
import 'safety_service.dart';
import 'trade_service.dart';

export 'package:souq_skills/data/trade_repository.dart' show TradeException;

/// Trades with real members, kept online and arriving live for both
/// members while signed in. Trades with the built-in demo members and the
/// offline demo stay on this device, in [Repository], as before. The trade,
/// proposal and session services read both.
class OnlineTrades {
  static TradeRepository? _online;

  /// Firestore once Firebase has been initialized; null in the offline
  /// demo. Can be replaced, e.g. with a fake; that stops listening to the
  /// previous one.
  static TradeRepository? get repository =>
      _online ??
      (Firebase.apps.isEmpty ? null : _online = FirebaseTradeRepository());
  static set repository(TradeRepository? value) {
    _stopListening();
    _online = value;
  }

  // What has been loaded, for the account in [_listeningFor] only.
  static String? _listeningFor;
  static StreamSubscription<List<OnlineTrade>>? _tradesWatch;
  static StreamSubscription<List<TradeProposal>>? _proposalsWatch;
  static bool _tradesLoaded = false;
  static final Map<String, OnlineTrade> _trades = {};
  static final Map<String, TradeProposal> _proposals = {};
  static String? _loadError;

  /// What went wrong loading trades, until they load again.
  static String? get loadError => _loadError;

  /// Starts listening to the signed-in account's trades, or stops when
  /// nobody is signed in, offline, or the account changed.
  static void syncSession() {
    final online = repository;
    final uid = AuthService.repository.uid;
    final wanted =
        online != null &&
            Repository.instance.isSignedIn &&
            TradeDocument.isSafeId(uid)
        ? uid
        : null;
    if (wanted == _listeningFor) return;
    _stopListening();
    if (wanted == null || online == null) return;
    _listeningFor = wanted;
    _tradesWatch = online
        .watchTrades(wanted)
        .listen(
          (items) => _onTrades(wanted, items),
          onError: (Object error) => _onFailed(wanted, error),
        );
    _proposalsWatch = online
        .watchProposals(wanted)
        .listen(
          (items) => _onProposals(wanted, items),
          onError: (Object error) => _onFailed(wanted, error),
        );
  }

  static void _stopListening() {
    _tradesWatch?.cancel();
    _proposalsWatch?.cancel();
    _tradesWatch = null;
    _proposalsWatch = null;
    _listeningFor = null;
    _tradesLoaded = false;
    _trades.clear();
    _proposals.clear();
    _loadError = null;
  }

  static bool _isCurrent(String uid) =>
      uid == _listeningFor && uid == AuthService.repository.uid;

  /// Whether a trade with [memberId] is kept online: a real member, not a
  /// demo member or the current user.
  static bool isOnlineMember(String memberId) =>
      repository != null &&
      memberId != User.currentUserId &&
      !SafetyService.isDemoMember(memberId) &&
      TradeDocument.isSafeId(memberId);

  static Trade? trade(String? id) => _trades[id]?.trade;

  static TradeSession? session(String? id) {
    for (final item in _trades.values) {
      if (item.session?.id == id) return item.session;
    }
    return null;
  }

  static TradeProposal? proposal(String? id) => _proposals[id];

  /// The online trades, newest first.
  static List<Trade> trades() => [
    for (final item in TradeDocument.newestFirst(_trades.values)) item.trade,
  ];

  /// The repository and uid to change trades with, or throws when nobody
  /// is signed in.
  static (TradeRepository, String) signedIn() {
    final online = repository;
    final uid = AuthService.repository.uid;
    if (online == null ||
        !Repository.instance.isSignedIn ||
        !TradeDocument.isSafeId(uid)) {
      throw TradeException.sessionExpired;
    }
    return (online, uid!);
  }

  /// Refuses starting or continuing a trade with a member the current user
  /// blocked; the rules also refuse it when the other member blocked them.
  static void checkNotBlocked(String memberId) {
    if (SafetyService().isBlocked(memberId)) throw TradeException.blocked;
  }

  /// Shows a trade step in the online chat with [memberId]. The trade is
  /// already saved, so a note that cannot be sent (such as after a block)
  /// is left out.
  static Future<void> postToChat(
    String memberId,
    String text, {
    required String tradeId,
    String? proposalId,
  }) async {
    try {
      await ChatService().postTradeUpdate(
        memberId,
        text,
        tradeId: tradeId,
        proposalId: proposalId,
      );
    } on ChatException {
      // Best effort; the trade itself shows the step.
    }
  }

  static void _onTrades(String uid, List<OnlineTrade> items) {
    if (!_isCurrent(uid)) return;
    final previous = Map.of(_trades);
    final wasLoaded = _tradesLoaded;
    _trades
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.trade.id, item)));
    _tradesLoaded = true;
    _loadError = null;
    unawaited(
      MemberService().loadMembers({
        for (final item in items) item.trade.otherMemberId,
      }),
    );
    // Credits for completed trades are paid online, into both wallets.
    if (items.any((item) => item.trade.isComplete)) BadgeService().sync();
    for (final item in items) {
      final before = previous[item.trade.id]?.trade;
      final trade = item.trade;
      // Only what changes while listening; older trades are just shown.
      if (!wasLoaded || before == null) continue;
      if (trade.isComplete && !before.isComplete) {
        TradeService().askForRating(trade);
      } else if (item.lastChangedByOther) {
        _notifyChange(before, trade);
      }
    }
    Repository.instance.emitChange();
  }

  static void _notifyChange(Trade before, Trade after) {
    final memberId = after.otherMemberId;
    if (SafetyService().isBlocked(memberId)) return;
    final name = MemberService().nameOf(memberId);
    final (title, message) = switch ((before.status, after.status)) {
      (TradeStatus.pending, TradeStatus.accepted) => (
        'Proposal accepted',
        '$name accepted your proposal.',
      ),
      (TradeStatus.accepted, TradeStatus.accepted)
          when after.confirmedByOther && !before.confirmedByOther =>
        (
          '$name marked the trade as complete',
          'Confirm it too to complete the trade.',
        ),
      _ => (null, null),
    };
    if (title == null || message == null) return;
    NotificationService().push(
      title: title,
      message: message,
      type: NotificationType.trade,
      route: AppRoutes.tradeDetails,
      routeArgument: after.id,
    );
  }

  static void _onProposals(String uid, List<TradeProposal> items) {
    if (!_isCurrent(uid)) return;
    _proposals
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.id, item)));
    Repository.instance.emitChange();
  }

  static void _onFailed(String uid, Object error) {
    if (!_isCurrent(uid)) return;
    // What was loaded stays shown.
    _loadError = error is TradeException
        ? error.message
        : 'We could not load your trades. Try again.';
    Repository.instance.emitChange();
  }
}
