import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'trade_repository.dart';

/// A wallet problem explained in words the member can act on.
class WalletException implements Exception {
  const WalletException(this.message);

  final String message;

  static const sessionExpired = WalletException(
    'Your session has expired. Sign in again.',
  );
  static const offline = WalletException('Check your internet connection.');
  static const notLoaded = WalletException(
    'We could not load your wallet. Try again.',
  );

  @override
  String toString() => message;
}

/// Why a member's credits changed, as stored in their ledger.
enum WalletEntryKind { welcome, tradeReward, tradePayment, tradeIncome }

/// One entry of a member's ledger, `wallets/{uid}/transactions/{id}`.
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.createdAt,
    this.tradeId,
    this.counterpartyId,
  });

  final String id;
  final WalletEntryKind kind;

  /// What it added to the balance; negative for credits paid.
  final int amount;
  final DateTime createdAt;
  final String? tradeId;

  /// The other member of the trade, as a uid.
  final String? counterpartyId;
}

/// What completing a trade pays one of its members: the change to their
/// balance and the ledger entries that explain it, by id.
class WalletSettlement {
  const WalletSettlement({
    required this.uid,
    required this.delta,
    required this.entries,
  });

  final String uid;
  final int delta;
  final Map<String, Map<String, dynamic>> entries;
}

/// Each member's credits, kept online.
///
/// `wallets/{uid}` holds the balance and `wallets/{uid}/transactions` the
/// append-only ledger of why it changed. Only the member can read either.
/// A wallet is opened once with the welcome credits; after that it changes
/// only when one of the member's trades completes, in the same write
/// (see [TradeRepository.confirmCompletion]), as the Firestore rules check.
abstract class WalletRepository {
  /// Opens [uid]'s wallet with the welcome credits, unless it is open
  /// already. Throws a [WalletException].
  Future<void> openWallet(String uid);

  /// [uid]'s balance, or null while their wallet is not open, and again
  /// after every change. Errors are [WalletException]s.
  Stream<int?> watchBalance(String uid);

  /// [uid]'s ledger, newest first, and again after every change. Errors are
  /// [WalletException]s.
  Stream<List<WalletEntry>> watchEntries(String uid);
}

/// What is stored for wallets, and what a trade's completion pays, as the
/// Firestore rules work it out. Keep in step with firestore.rules.
abstract final class WalletDocument {
  static const welcomeCredits = 120;
  static const completionReward = 10;
  static const fetchLimit = 200;

  static const welcomeId = 'welcome';
  static String rewardId(String tradeId) => '${tradeId}_reward';
  static String paymentId(String tradeId) => '${tradeId}_payment';

  static Map<String, dynamic> newWalletData(String uid, Object now) => {
    'uid': uid,
    'balance': welcomeCredits,
    'updatedAt': now,
  };

  static Map<String, dynamic> welcomeEntryData(Object now) => {
    'kind': WalletEntryKind.welcome.name,
    'amount': welcomeCredits,
    'createdAt': now,
  };

  static int _credits(Map<String, dynamic> trade) {
    final credits = trade['creditsOffered'];
    return credits is int && credits > 0 ? credits : 0;
  }

  /// The credits [uid] receives (+) or pays (-) for [trade], besides the
  /// reward: the member whose terms offered credits pays them.
  static int paymentOf(String uid, Map<String, dynamic> trade) {
    final credits = _credits(trade);
    return trade['termsBy'] == uid ? -credits : credits;
  }

  /// What completing stored trade [tradeId] pays each of its two members:
  /// the reward to both, and its credits from the payer to the other.
  static List<WalletSettlement> settle(
    String tradeId,
    Map<String, dynamic> trade,
    Object now,
  ) {
    final ids = trade['participantIds'];
    if (ids is! List || ids.length != 2) throw TradeException.notFound;
    final credits = _credits(trade);
    return [
      for (final uid in ids.cast<String>())
        WalletSettlement(
          uid: uid,
          delta: completionReward + paymentOf(uid, trade),
          entries: {
            rewardId(tradeId): {
              'kind': WalletEntryKind.tradeReward.name,
              'amount': completionReward,
              'tradeId': tradeId,
              'counterpartyId': TradeDocument.otherOf(trade, uid),
              'createdAt': now,
            },
            if (credits > 0)
              paymentId(tradeId): {
                'kind': trade['termsBy'] == uid
                    ? WalletEntryKind.tradePayment.name
                    : WalletEntryKind.tradeIncome.name,
                'amount': paymentOf(uid, trade),
                'tradeId': tradeId,
                'counterpartyId': TradeDocument.otherOf(trade, uid),
                'createdAt': now,
              },
          },
        ),
    ];
  }

  /// Refuses completing [trade] for [uid] when [uid]'s own [wallet] cannot
  /// pay its credits. Only the member's own wallet can be read, so the
  /// rules refuse it when the other member is the one short of credits.
  static void checkCanSettle(
    String uid,
    Map<String, dynamic> trade,
    Map<String, dynamic>? wallet,
  ) {
    final balance = balanceOf(wallet);
    if (balance == null) throw TradeException.notSaved;
    if (balance + completionReward + paymentOf(uid, trade) < 0) {
      throw TradeException.insufficientCredits;
    }
  }

  static int? balanceOf(Map<String, dynamic>? wallet) {
    final balance = wallet?['balance'];
    return balance is int ? balance : null;
  }

  /// Reads stored ledger entry [id], or null if it cannot be understood.
  static WalletEntry? entryFromData(String id, Map<String, dynamic> data) {
    final kind = WalletEntryKind.values.asNameMap()[data['kind']];
    final amount = data['amount'];
    if (kind == null || amount is! int) return null;
    final tradeId = data['tradeId'];
    final counterparty = data['counterpartyId'];
    return WalletEntry(
      id: id,
      kind: kind,
      amount: amount,
      createdAt: TradeDocument.dateOf(data['createdAt']),
      tradeId: tradeId is String ? tradeId : null,
      counterpartyId: counterparty is String ? counterparty : null,
    );
  }

  static List<WalletEntry> newestFirst(Iterable<WalletEntry> items) =>
      items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// Wallets in Cloud Firestore.
class FirebaseWalletRepository implements WalletRepository {
  FirebaseWalletRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> wallet(String uid) {
    if (!TradeDocument.isSafeId(uid)) throw WalletException.sessionExpired;
    return _firestore.collection('wallets').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _entry(String uid, String id) =>
      wallet(uid).collection('transactions').doc(id);

  @override
  Future<void> openWallet(String uid) async {
    final ref = wallet(uid);
    try {
      await _firestore.runTransaction((transaction) async {
        if ((await transaction.get(ref)).exists) return;
        final now = FieldValue.serverTimestamp();
        transaction
          ..set(ref, WalletDocument.newWalletData(uid, now))
          ..set(
            _entry(uid, WalletDocument.welcomeId),
            WalletDocument.welcomeEntryData(now),
          );
      });
    } on FirebaseException catch (error) {
      throw error.code == 'unavailable'
          ? WalletException.offline
          : WalletException.notLoaded;
    }
  }

  /// Adds the writes that pay [settlement] for [tradeId] to [transaction],
  /// which also completes the trade.
  void applySettlement(
    Transaction transaction,
    String tradeId,
    List<WalletSettlement> settlement,
    Object now,
  ) {
    for (final member in settlement) {
      // An increment, so the other member's balance is never read.
      transaction.update(wallet(member.uid), {
        'balance': FieldValue.increment(member.delta),
        'lastTradeId': tradeId,
        'updatedAt': now,
      });
      for (final MapEntry(:key, :value) in member.entries.entries) {
        transaction.set(_entry(member.uid, key), value);
      }
    }
  }

  @override
  Stream<int?> watchBalance(String uid) =>
      wallet(uid)
          .snapshots()
          .map((snapshot) => WalletDocument.balanceOf(snapshot.data()))
          .transform(_errors());

  @override
  Stream<List<WalletEntry>> watchEntries(String uid) =>
      wallet(uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(WalletDocument.fetchLimit)
          .snapshots()
          .map(
            (snapshot) => WalletDocument.newestFirst([
              for (final doc in snapshot.docs)
                ?WalletDocument.entryFromData(doc.id, doc.data()),
            ]),
          )
          .transform(_errors());

  static StreamTransformer<T, T> _errors<T>() => StreamTransformer.fromHandlers(
    handleError: (error, stackTrace, sink) => sink.addError(
      error is FirebaseException && error.code == 'unavailable'
          ? WalletException.offline
          : WalletException.notLoaded,
      stackTrace,
    ),
  );
}

/// Keeps wallets in memory, with the same rules as Firestore. Used with
/// [DemoTradeRepository], which settles completed trades into it, when
/// Firebase has not been set up, such as in tests.
class DemoWalletRepository implements WalletRepository {
  final Map<String, Map<String, dynamic>> _wallets = {};
  final Map<String, Map<String, Map<String, dynamic>>> _entries = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  final _failures = StreamController<WalletException>.broadcast(sync: true);

  /// A copy of [uid]'s wallet as stored, or null.
  Map<String, dynamic>? storedWallet(String uid) =>
      _wallets[uid] == null ? null : {..._wallets[uid]!};

  /// A copy of [uid]'s ledger as stored, by entry id.
  Map<String, Map<String, dynamic>> storedEntries(String uid) => {
    for (final MapEntry(:key, :value) in (_entries[uid] ?? {}).entries)
      key: {...value},
  };

  /// Every stream being listened to fails with [error].
  void failStreams(WalletException error) => _failures.add(error);

  @override
  Future<void> openWallet(String uid) async {
    if (!TradeDocument.isSafeId(uid)) throw WalletException.sessionExpired;
    if (_wallets.containsKey(uid)) return;
    final now = DateTime.now();
    _wallets[uid] = WalletDocument.newWalletData(uid, now);
    _entries[uid] = {
      WalletDocument.welcomeId: WalletDocument.welcomeEntryData(now),
    };
    _changes.add(null);
  }

  /// Pays the members of [tradeId], which [uid] is completing, as the
  /// rules allow; throws a [TradeException] and changes nothing otherwise.
  void settle(
    String uid,
    String tradeId,
    Map<String, dynamic> trade,
    DateTime now,
  ) {
    WalletDocument.checkCanSettle(uid, trade, _wallets[uid]);
    final settlement = WalletDocument.settle(tradeId, trade, now);
    for (final member in settlement) {
      final wallet = _wallets[member.uid];
      final balance = WalletDocument.balanceOf(wallet);
      // As the rules: an open wallet, never paid twice for one trade, never
      // below zero, and each entry written once.
      if (balance == null ||
          wallet!['lastTradeId'] == tradeId ||
          balance + member.delta < 0 ||
          member.entries.keys.any(
            (id) => _entries[member.uid]?.containsKey(id) ?? false,
          )) {
        throw TradeException.notSaved;
      }
    }
    for (final member in settlement) {
      final wallet = _wallets[member.uid]!;
      _wallets[member.uid] = {
        ...wallet,
        'balance': (wallet['balance'] as int) + member.delta,
        'lastTradeId': tradeId,
        'updatedAt': now,
      };
      (_entries[member.uid] ??= {}).addAll(member.entries);
    }
    _changes.add(null);
  }

  @override
  Stream<int?> watchBalance(String uid) =>
      _watch(() => WalletDocument.balanceOf(_wallets[uid]));

  @override
  Stream<List<WalletEntry>> watchEntries(String uid) => _watch(
    () => WalletDocument.newestFirst([
      for (final MapEntry(:key, :value) in (_entries[uid] ?? {}).entries)
        ?WalletDocument.entryFromData(key, value),
    ]),
  );

  /// A stream of [read], now and after every change, like `snapshots()`.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    StreamSubscription<WalletException>? failures;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        changes = _changes.stream.listen((_) => controller.add(read()));
        failures = _failures.stream.listen(controller.addError);
        controller.add(read());
      },
      onCancel: () {
        changes?.cancel();
        failures?.cancel();
      },
    );
    return controller.stream;
  }
}
