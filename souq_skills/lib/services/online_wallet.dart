import 'dart:async';

import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/transaction.dart';

import 'auth_service.dart';
import 'member_service.dart';
import 'online_trades.dart';
import 'repository.dart';

/// The signed-in member's wallet, kept online with their trades and
/// arriving live. Its balance changes only on the server: the welcome
/// credits once, then each completed trade with a real member. The demo
/// account and the offline demo keep their wallet on this device, in
/// [Repository], as before.
class OnlineWallet {
  /// The wallets kept with the online trades; null in the offline demo.
  static WalletRepository? get repository => OnlineTrades.repository?.wallets;

  // What has been loaded, for [_listeningFor] in [_listeningTo] only.
  static WalletRepository? _listeningTo;
  static String? _listeningFor;
  static StreamSubscription<int?>? _balanceWatch;
  static StreamSubscription<List<WalletEntry>>? _entriesWatch;
  static int? _balance;
  static List<WalletEntry> _entries = const [];
  static String? _loadError;

  static String? _wantedUid() {
    final uid = AuthService.repository.uid;
    return repository != null &&
            Repository.instance.isSignedIn &&
            TradeDocument.isSafeId(uid)
        ? uid
        : null;
  }

  /// Whether the signed-in account's wallet is the online one, so its
  /// balance and history are shown instead of those on this device.
  static bool get isActive {
    final uid = _wantedUid();
    return uid != null &&
        uid == _listeningFor &&
        identical(repository, _listeningTo);
  }

  /// The online balance; 0 until it has loaded.
  static int get balance => _balance ?? 0;

  /// What went wrong loading the wallet, until it loads again.
  static String? get loadError => _loadError;

  /// Starts listening to the signed-in account's wallet, opening it once
  /// with the welcome credits; stops when nobody is signed in, offline, or
  /// the account changed.
  static void syncSession() {
    final online = repository;
    final wanted = _wantedUid();
    if (wanted == _listeningFor && identical(online, _listeningTo)) return;
    _stopListening();
    if (wanted == null || online == null) return;
    _listeningFor = wanted;
    _listeningTo = online;
    unawaited(_open(online, wanted));
    _balanceWatch = online
        .watchBalance(wanted)
        .listen(
          (value) => _onBalance(wanted, value),
          onError: (Object error) => _onFailed(wanted, error),
        );
    _entriesWatch = online
        .watchEntries(wanted)
        .listen(
          (items) => _onEntries(wanted, items),
          onError: (Object error) => _onFailed(wanted, error),
        );
  }

  static void _stopListening() {
    _balanceWatch?.cancel();
    _entriesWatch?.cancel();
    _balanceWatch = null;
    _entriesWatch = null;
    _listeningFor = null;
    _listeningTo = null;
    _balance = null;
    _entries = const [];
    _loadError = null;
  }

  static bool _isCurrent(String uid) =>
      uid == _listeningFor && uid == AuthService.repository.uid;

  static Future<void> _open(WalletRepository online, String uid) async {
    try {
      await online.openWallet(uid);
    } on WalletException catch (error) {
      if (!_isCurrent(uid)) return;
      _loadError = error.message;
      Repository.instance.emitChange();
    }
  }

  /// The online ledger as the wallet screen shows it, newest first.
  static List<WalletTransaction> transactions() => [
    for (final entry in _entries) _toTransaction(entry),
  ];

  static WalletTransaction _toTransaction(WalletEntry entry) {
    final memberId = entry.counterpartyId;
    final (title, type) = switch (entry.kind) {
      WalletEntryKind.welcome => ('Welcome credits', TransactionType.earned),
      WalletEntryKind.tradeReward => (
        'Trade completed',
        TransactionType.earned,
      ),
      WalletEntryKind.tradePayment => ('Credits paid', TransactionType.spent),
      WalletEntryKind.tradeIncome => (
        'Credits received',
        TransactionType.earned,
      ),
    };
    return WalletTransaction(
      id: entry.id,
      title: title,
      subtitle: entry.kind == WalletEntryKind.welcome
          ? 'A gift for joining Souq Skills'
          : OnlineTrades.trade(entry.tradeId)?.title ?? '',
      amount: entry.amount,
      date: entry.createdAt,
      type: type,
      tradeId: entry.tradeId,
      participantName: memberId == null
          ? null
          : MemberService().nameOf(memberId),
    );
  }

  static void _onBalance(String uid, int? value) {
    if (!_isCurrent(uid)) return;
    _balance = value;
    if (value != null) _loadError = null;
    Repository.instance.emitChange();
  }

  static void _onEntries(String uid, List<WalletEntry> items) {
    if (!_isCurrent(uid)) return;
    _entries = List.unmodifiable(items);
    _loadError = null;
    unawaited(
      MemberService().loadMembers({
        for (final item in items) ?item.counterpartyId,
      }),
    );
    Repository.instance.emitChange();
  }

  static void _onFailed(String uid, Object error) {
    if (!_isCurrent(uid)) return;
    // What was loaded stays shown.
    _loadError = error is WalletException
        ? error.message
        : WalletException.notLoaded.message;
    Repository.instance.emitChange();
  }
}
