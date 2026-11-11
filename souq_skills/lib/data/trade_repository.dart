import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/user.dart';

/// A trade problem explained in words the member can act on.
class TradeException implements Exception {
  const TradeException(this.message);

  final String message;

  static const sessionExpired = TradeException(
    'Your session has expired. Sign in again.',
  );
  static const notFound = TradeException('This trade is no longer available.');
  static const notSaved = TradeException('This trade could not be updated.');
  static const alreadyAnswered = TradeException(
    'This proposal has already been answered.',
  );
  static const blocked = TradeException(
    'Unblock this member to continue this trade.',
  );
  static const invalidTerms = TradeException('Check the proposal details.');
  static const pastSession = TradeException('Choose a time in the future');
  static const alreadyConfirmed = TradeException(
    'You already confirmed this trade.',
  );

  @override
  String toString() => message;
}

/// A trade shared online, as one of its two members sees it.
class OnlineTrade {
  const OnlineTrade({
    required this.trade,
    required this.createdAt,
    this.session,
    this.lastChangedByOther = false,
  });

  /// From the viewer's side, with the other member's uid as
  /// [Trade.otherMemberId].
  final Trade trade;
  final TradeSession? session;
  final DateTime createdAt;

  /// Whether the latest change was made by the other member.
  final bool lastChangedByOther;
}

/// What sending a proposal created.
typedef SentProposal = ({String tradeId, String proposalId});

/// Changes to a stored trade, worked out by [TradeDocument] from what is
/// stored, so Firestore and the in-memory server apply the same rules.
class TradeChange {
  const TradeChange({
    required this.trade,
    this.proposals = const {},
    this.newProposal,
  });

  /// The trade fields to change.
  final Map<String, dynamic> trade;

  /// The fields to change in existing proposals, by id.
  final Map<String, Map<String, dynamic>> proposals;

  /// A proposal to create, when countering.
  final Map<String, dynamic>? newProposal;
}

/// One-to-one trades between two real members, kept online.
///
/// Each trade is `trades/{tradeId}`, holding its current terms, status,
/// session and who confirmed completion; each proposal or counteroffer is
/// `proposals/{proposalId}`. Both are stored by uid only, never `'me'`, and
/// only the two members can read them. A trade becomes completed only
/// once both members confirmed it.
abstract class TradeRepository {
  /// Starts a pending trade from [draft], written by [uid] to
  /// [TradeProposal.receiverId]. Throws a [TradeException].
  Future<SentProposal> sendProposal(String uid, TradeProposal draft);

  /// Replaces pending proposal [proposalId] of [tradeId] with [uid]'s new
  /// terms; returns the new proposal's id. Throws a [TradeException].
  Future<String> counterProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required TradeProposal draft,
  });

  /// Accepts or declines (the receiver) or cancels (the sender) pending
  /// proposal [proposalId], closing or starting [tradeId] with it. Throws a
  /// [TradeException].
  Future<void> respondToProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required ProposalStatus response,
  });

  /// Books, or reschedules, the session of accepted trade [tradeId].
  /// Throws a [TradeException].
  Future<void> scheduleSession(
    String uid, {
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  });

  /// Records that [uid] confirmed [tradeId] is complete; returns whether
  /// both members have now, which completes it. Throws a [TradeException].
  Future<bool> confirmCompletion(String uid, String tradeId);

  /// Marks accepted trade [tradeId] as disputed. Throws a [TradeException].
  Future<void> markDisputed(String uid, String tradeId);

  /// [uid]'s trades, newest first, and again after every change. Errors
  /// are [TradeException]s.
  Stream<List<OnlineTrade>> watchTrades(String uid);

  /// The proposals of [uid]'s trades, as [uid] sees them, and again after
  /// every change. Errors are [TradeException]s.
  Stream<List<TradeProposal>> watchProposals(String uid);
}

/// Converts between the app's trade models and what is stored online, and
/// decides which changes are allowed, as the Firestore rules do.
abstract final class TradeDocument {
  static const fetchLimit = 200;
  static const maxSkillLength = 60;
  static const maxNotesLength = 500;
  static const maxMethodLength = 40;
  static const maxPlaceLength = 200;
  static const maxCredits = 10000;
  static const minMinutes = 15;
  static const maxMinutes = 480;

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// A uid or document id that may be stored: never the local `'me'`.
  static bool isSafeId(String? id) =>
      id != null && id != User.currentUserId && _safeId.hasMatch(id);

  /// The uid to store for the app's [id]: [uid] for the current user's
  /// local id `'me'`.
  static String uidOf(String id, String uid) =>
      id == User.currentUserId ? uid : id;

  /// The app's id for stored [id]: `'me'` for the viewer's own uid.
  static String localIdOf(String id, String viewerUid) =>
      id == viewerUid ? User.currentUserId : id;

  static List<String> participantsOf(String uid, String memberId) =>
      uid.compareTo(memberId) < 0 ? [uid, memberId] : [memberId, uid];

  /// The id the app gives the session of trade [tradeId].
  static String sessionIdFor(String tradeId) => '${tradeId}_session';

  /// The other member of [trade], or throws if [uid] is not one of them.
  static String otherOf(Map<String, dynamic> trade, String uid) {
    final ids = trade['participantIds'];
    if (ids is! List || ids.length != 2 || !ids.contains(uid)) {
      throw TradeException.notFound;
    }
    final other = ids[0] == uid ? ids[1] : ids[0];
    if (other is! String || other == uid || !isSafeId(other)) {
      throw TradeException.notFound;
    }
    return other;
  }

  /// The terms of [draft] as stored, after checking them.
  static Map<String, dynamic> termsOf(TradeProposal draft) {
    final offered = draft.offeredSkill.trim();
    final requested = draft.requestedSkill.trim();
    final method = draft.deliveryMethod.trim();
    if (requested.isEmpty ||
        requested.length > maxSkillLength ||
        offered.length > maxSkillLength ||
        method.isEmpty ||
        method.length > maxMethodLength ||
        draft.notes.trim().length > maxNotesLength ||
        draft.sessionsMinutes < minMinutes ||
        draft.sessionsMinutes > maxMinutes ||
        draft.creditsOffered < 0 ||
        draft.creditsOffered > maxCredits ||
        (offered.isEmpty && draft.creditsOffered == 0)) {
      throw TradeException.invalidTerms;
    }
    return {
      'offeredSkill': offered,
      'requestedSkill': requested,
      'sessionsMinutes': draft.sessionsMinutes,
      'deliveryMethod': method,
      'creditsOffered': draft.creditsOffered,
    };
  }

  /// The member [draft] by [uid] goes to, as a uid, after checking that
  /// [uid] wrote it to someone else.
  static String receiverOf(String uid, TradeProposal draft) {
    if (!isSafeId(uid)) throw TradeException.sessionExpired;
    if (uidOf(draft.senderId, uid) != uid) throw TradeException.invalidTerms;
    final receiver = draft.receiverId;
    if (!isSafeId(receiver) || receiver == uid) {
      throw TradeException.invalidTerms;
    }
    return receiver;
  }

  static Map<String, dynamic> proposalData(
    String uid,
    String receiverId,
    String tradeId,
    TradeProposal draft,
    Object now,
  ) => {
    'tradeId': tradeId,
    'participantIds': participantsOf(uid, receiverId),
    'senderId': uid,
    'receiverId': receiverId,
    ...termsOf(draft),
    'notes': draft.notes.trim(),
    'status': ProposalStatus.pending.name,
    'createdAt': now,
    'updatedAt': now,
  };

  /// A new pending trade started by [uid]'s proposal [proposalId].
  static Map<String, dynamic> newTradeData(
    String uid,
    String receiverId,
    String proposalId,
    TradeProposal draft,
    Object now,
  ) => {
    'participantIds': participantsOf(uid, receiverId),
    'proposerId': uid,
    'termsBy': uid,
    'proposalId': proposalId,
    'status': TradeStatus.pending.name,
    ...termsOf(draft),
    'completedBy': <String, dynamic>{},
    'createdAt': now,
    'updatedAt': now,
    'updatedBy': uid,
  };

  static void _checkCurrentPending(
    Map<String, dynamic> trade,
    String proposalId,
    Map<String, dynamic> proposal,
  ) {
    if (trade['status'] != TradeStatus.pending.name ||
        trade['proposalId'] != proposalId ||
        proposal['status'] != ProposalStatus.pending.name ||
        proposal['tradeId'] == null) {
      throw TradeException.alreadyAnswered;
    }
  }

  /// [uid] replaces the trade's current proposal with [draft].
  static TradeChange counter(
    String uid, {
    required String tradeId,
    required Map<String, dynamic> trade,
    required String proposalId,
    required Map<String, dynamic> proposal,
    required String newProposalId,
    required TradeProposal draft,
    required Object now,
  }) {
    final other = otherOf(trade, uid);
    _checkCurrentPending(trade, proposalId, proposal);
    if (proposal['tradeId'] != tradeId) throw TradeException.notFound;
    final counterDraft = draft.copyWith(senderId: uid, receiverId: other);
    final terms = termsOf(counterDraft);
    return TradeChange(
      trade: {
        ...terms,
        'termsBy': uid,
        'proposalId': newProposalId,
        'updatedAt': now,
        'updatedBy': uid,
      },
      proposals: {
        proposalId: {'status': ProposalStatus.countered.name, 'updatedAt': now},
      },
      newProposal: proposalData(uid, other, tradeId, counterDraft, now),
    );
  }

  /// What [response] to the current proposal makes of the trade.
  static TradeStatus tradeStatusAfter(ProposalStatus response) =>
      switch (response) {
        ProposalStatus.accepted => TradeStatus.accepted,
        ProposalStatus.declined => TradeStatus.declined,
        ProposalStatus.cancelled => TradeStatus.cancelled,
        _ => throw TradeException.notSaved,
      };

  /// [uid] accepts, declines or cancels the trade's current proposal: the
  /// receiver accepts or declines, the sender cancels.
  static TradeChange respond(
    String uid, {
    required Map<String, dynamic> trade,
    required String proposalId,
    required Map<String, dynamic> proposal,
    required ProposalStatus response,
    required Object now,
  }) {
    otherOf(trade, uid);
    final status = tradeStatusAfter(response);
    _checkCurrentPending(trade, proposalId, proposal);
    final responder = response == ProposalStatus.cancelled
        ? proposal['senderId']
        : proposal['receiverId'];
    if (responder != uid) throw TradeException.notSaved;
    return TradeChange(
      trade: {'status': status.name, 'updatedAt': now, 'updatedBy': uid},
      proposals: {
        proposalId: {'status': response.name, 'updatedAt': now},
      },
    );
  }

  static TradeChange schedule(
    String uid, {
    required Map<String, dynamic> trade,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
    required Object now,
  }) {
    otherOf(trade, uid);
    if (trade['status'] != TradeStatus.accepted.name) {
      throw TradeException.notSaved;
    }
    if (!scheduledAt.isAfter(DateTime.now())) throw TradeException.pastSession;
    final cleanMethod = method.trim();
    if (cleanMethod.isEmpty ||
        cleanMethod.length > maxMethodLength ||
        locationOrLink.trim().length > maxPlaceLength ||
        notes.trim().length > maxNotesLength) {
      throw TradeException.invalidTerms;
    }
    return TradeChange(
      trade: {
        'session': {
          'scheduledAt': scheduledAt,
          'method': cleanMethod,
          'locationOrLink': locationOrLink.trim(),
          'notes': notes.trim(),
        },
        'updatedAt': now,
        'updatedBy': uid,
      },
    );
  }

  /// [uid] confirms the exchange happened. The trade is completed in the
  /// same change once both members have.
  static ({TradeChange change, bool completed}) confirm(
    String uid, {
    required Map<String, dynamic> trade,
    required Object now,
  }) {
    final other = otherOf(trade, uid);
    if (trade['status'] != TradeStatus.accepted.name ||
        trade['session'] is! Map) {
      throw TradeException.notSaved;
    }
    final before = trade['completedBy'];
    final confirmed = <String, dynamic>{
      if (before is Map)
        for (final MapEntry(:key, :value) in before.entries) '$key': value,
    };
    if (confirmed.containsKey(uid)) throw TradeException.alreadyConfirmed;
    confirmed[uid] = now;
    final completed = confirmed.containsKey(other);
    return (
      change: TradeChange(
        trade: {
          'completedBy': confirmed,
          if (completed) 'status': TradeStatus.completed.name,
          'updatedAt': now,
          'updatedBy': uid,
        },
      ),
      completed: completed,
    );
  }

  static TradeChange dispute(
    String uid, {
    required Map<String, dynamic> trade,
    required Object now,
  }) {
    otherOf(trade, uid);
    if (trade['status'] != TradeStatus.accepted.name) {
      throw TradeException.notSaved;
    }
    return TradeChange(
      trade: {
        'status': TradeStatus.disputed.name,
        'updatedAt': now,
        'updatedBy': uid,
      },
    );
  }

  static String _text(Object? value) => value is String ? value : '';

  static int _int(Object? value, int fallback) =>
      value is int ? value : fallback;

  /// Reads stored trade [id] as [viewerUid] sees it, or null if it is not
  /// one of theirs or cannot be understood.
  static OnlineTrade? tradeFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) {
    final String other;
    try {
      other = otherOf(data, viewerUid);
    } on TradeException {
      return null;
    }
    final status = TradeStatus.values.asNameMap()[data['status']];
    final proposalId = data['proposalId'];
    if (status == null || proposalId is! String) return null;
    final offered = _text(data['offeredSkill']);
    final requested = _text(data['requestedSkill']);
    final credits = _int(data['creditsOffered'], 0);
    final mine = data['termsBy'] == viewerUid;
    final confirmed = data['completedBy'];
    final session = data['session'];
    final hasSession = session is Map;
    return OnlineTrade(
      trade: Trade(
        id: id,
        proposalId: proposalId,
        otherMemberId: other,
        // Terms are stored from the side of whoever wrote them.
        offeredSkill: mine ? offered : requested,
        requestedSkill: mine
            ? requested
            : (offered.isEmpty && credits > 0 ? '$credits credits' : offered),
        sessionsMinutes: _int(data['sessionsMinutes'], 60),
        creditsPaid: mine ? credits : 0,
        status: status,
        sessionId: hasSession ? sessionIdFor(id) : null,
        confirmedByMe: confirmed is Map && confirmed.containsKey(viewerUid),
        confirmedByOther: confirmed is Map && confirmed.containsKey(other),
      ),
      session: hasSession
          ? TradeSession(
              id: sessionIdFor(id),
              tradeId: id,
              scheduledAt: dateOf(session['scheduledAt']),
              method: _text(session['method']),
              locationOrLink: _text(session['locationOrLink']),
              notes: _text(session['notes']),
              isCompleted: status == TradeStatus.completed,
            )
          : null,
      createdAt: dateOf(data['createdAt']),
      lastChangedByOther: data['updatedBy'] == other,
    );
  }

  /// Reads stored proposal [id] as [viewerUid] sees it, with `'me'` for
  /// their own uid, or null if it is not theirs or cannot be understood.
  static TradeProposal? proposalFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) {
    final sender = data['senderId'];
    final receiver = data['receiverId'];
    final tradeId = data['tradeId'];
    final status = ProposalStatus.values.asNameMap()[data['status']];
    if (sender is! String ||
        receiver is! String ||
        tradeId is! String ||
        status == null ||
        (sender != viewerUid && receiver != viewerUid)) {
      return null;
    }
    return TradeProposal(
      id: id,
      tradeId: tradeId,
      senderId: localIdOf(sender, viewerUid),
      receiverId: localIdOf(receiver, viewerUid),
      offeredSkill: _text(data['offeredSkill']),
      requestedSkill: _text(data['requestedSkill']),
      sessionsMinutes: _int(data['sessionsMinutes'], 60),
      deliveryMethod: _text(data['deliveryMethod']),
      notes: _text(data['notes']),
      creditsOffered: _int(data['creditsOffered'], 0),
      status: status,
    );
  }

  /// A stored time, or now for one the server has not set yet.
  static DateTime dateOf(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    _ => DateTime.now(),
  };

  static List<OnlineTrade> newestFirst(Iterable<OnlineTrade> items) =>
      items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// Trades in Cloud Firestore.
class FirebaseTradeRepository implements TradeRepository {
  FirebaseTradeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _trades =>
      _firestore.collection('trades');

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _firestore.collection('proposals');

  DocumentReference<Map<String, dynamic>> _trade(String id) {
    if (!TradeDocument.isSafeId(id)) throw TradeException.notFound;
    return _trades.doc(id);
  }

  DocumentReference<Map<String, dynamic>> _proposal(String id) {
    if (!TradeDocument.isSafeId(id)) throw TradeException.notFound;
    return _proposals.doc(id);
  }

  static Object get _now => FieldValue.serverTimestamp();

  @override
  Future<SentProposal> sendProposal(String uid, TradeProposal draft) async {
    final receiver = TradeDocument.receiverOf(uid, draft);
    final trade = _trades.doc();
    final proposal = _proposals.doc();
    // Checked before anything is sent.
    TradeDocument.termsOf(draft);
    await _guard(
      () =>
          (_firestore.batch()
                ..set(
                  trade,
                  TradeDocument.newTradeData(
                    uid,
                    receiver,
                    proposal.id,
                    draft,
                    _now,
                  ),
                )
                ..set(
                  proposal,
                  TradeDocument.proposalData(
                    uid,
                    receiver,
                    trade.id,
                    draft,
                    _now,
                  ),
                ))
              .commit(),
    );
    return (tradeId: trade.id, proposalId: proposal.id);
  }

  @override
  Future<String> counterProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required TradeProposal draft,
  }) async {
    final tradeRef = _trade(tradeId);
    final proposalRef = _proposal(proposalId);
    final next = _proposals.doc();
    await _change(tradeRef, (transaction, trade) async {
      final proposal = await _read(transaction, proposalRef);
      final change = TradeDocument.counter(
        uid,
        tradeId: tradeId,
        trade: trade,
        proposalId: proposalId,
        proposal: proposal,
        newProposalId: next.id,
        draft: draft,
        now: _now,
      );
      _apply(transaction, tradeRef, change);
      transaction.set(next, change.newProposal!);
    });
    return next.id;
  }

  @override
  Future<void> respondToProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required ProposalStatus response,
  }) {
    final tradeRef = _trade(tradeId);
    final proposalRef = _proposal(proposalId);
    return _change(tradeRef, (transaction, trade) async {
      final proposal = await _read(transaction, proposalRef);
      _apply(
        transaction,
        tradeRef,
        TradeDocument.respond(
          uid,
          trade: trade,
          proposalId: proposalId,
          proposal: proposal,
          response: response,
          now: _now,
        ),
      );
    });
  }

  @override
  Future<void> scheduleSession(
    String uid, {
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  }) {
    final tradeRef = _trade(tradeId);
    return _change(
      tradeRef,
      (transaction, trade) async => _apply(
        transaction,
        tradeRef,
        TradeDocument.schedule(
          uid,
          trade: trade,
          scheduledAt: scheduledAt,
          method: method,
          locationOrLink: locationOrLink,
          notes: notes,
          now: _now,
        ),
      ),
    );
  }

  @override
  Future<bool> confirmCompletion(String uid, String tradeId) async {
    final tradeRef = _trade(tradeId);
    var completed = false;
    await _change(tradeRef, (transaction, trade) async {
      final result = TradeDocument.confirm(uid, trade: trade, now: _now);
      completed = result.completed;
      _apply(transaction, tradeRef, result.change);
    });
    return completed;
  }

  @override
  Future<void> markDisputed(String uid, String tradeId) {
    final tradeRef = _trade(tradeId);
    return _change(
      tradeRef,
      (transaction, trade) async => _apply(
        transaction,
        tradeRef,
        TradeDocument.dispute(uid, trade: trade, now: _now),
      ),
    );
  }

  @override
  Stream<List<OnlineTrade>> watchTrades(String uid) => _trades
      .where('participantIds', arrayContains: uid)
      .limit(TradeDocument.fetchLimit)
      .snapshots()
      .map(
        (snapshot) => TradeDocument.newestFirst([
          for (final doc in snapshot.docs)
            ?TradeDocument.tradeFromData(doc.id, doc.data(), viewerUid: uid),
        ]),
      )
      .transform(_errors('We could not load your trades.'));

  @override
  Stream<List<TradeProposal>> watchProposals(String uid) => _proposals
      .where('participantIds', arrayContains: uid)
      .limit(TradeDocument.fetchLimit)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ?TradeDocument.proposalFromData(doc.id, doc.data(), viewerUid: uid),
        ],
      )
      .transform(_errors('We could not load your proposals.'));

  /// Runs [change] on the stored trade in a transaction, so it is decided
  /// from the latest state.
  Future<void> _change(
    DocumentReference<Map<String, dynamic>> tradeRef,
    Future<void> Function(Transaction, Map<String, dynamic> trade) change,
  ) => _guard(
    () => _firestore.runTransaction((transaction) async {
      final trade = await _read(transaction, tradeRef);
      await change(transaction, trade);
    }),
  );

  static Future<Map<String, dynamic>> _read(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await transaction.get(ref);
    final data = snapshot.data();
    if (data == null) throw TradeException.notFound;
    return data;
  }

  void _apply(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> tradeRef,
    TradeChange change,
  ) {
    transaction.update(tradeRef, change.trade);
    for (final MapEntry(:key, :value) in change.proposals.entries) {
      transaction.update(_proposal(key), value);
    }
  }

  static StreamTransformer<T, T> _errors<T>(String fallback) =>
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) => sink.addError(
          TradeException(
            error is FirebaseException && error.code == 'unavailable'
                ? 'Check your internet connection.'
                : '$fallback Try again.',
          ),
          stackTrace,
        ),
      );

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TradeException {
      rethrow;
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'unavailable' => const TradeException(
          'Check your internet connection.',
        ),
        'not-found' => TradeException.notFound,
        // Also when a block stops it; the member is not told why.
        _ => TradeException.notSaved,
      };
    } catch (_) {
      throw TradeException.notSaved;
    }
  }
}

/// Keeps trades in memory, with the same rules as Firestore. Used when
/// Firebase has not been set up, such as in tests, where one instance plays
/// the server for every member.
class DemoTradeRepository implements TradeRepository {
  /// [isRealMember] says whether a uid has an account, and [hasBlocked]
  /// whether the first member blocked the second, as the rules check them.
  DemoTradeRepository({
    bool Function(String uid)? isRealMember,
    bool Function(String uid, String otherUid)? hasBlocked,
  }) : _isRealMember = isRealMember ?? ((_) => true),
       _hasBlocked = hasBlocked ?? ((_, _) => false);

  final bool Function(String uid) _isRealMember;
  final bool Function(String uid, String otherUid) _hasBlocked;

  final Map<String, Map<String, dynamic>> _trades = {};
  final Map<String, Map<String, dynamic>> _proposals = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  final _failures = StreamController<TradeException>.broadcast(sync: true);
  DateTime _lastTime = DateTime(2000);
  int _nextId = 0;

  /// A copy of trade [id] as stored, or null.
  Map<String, dynamic>? storedTrade(String id) =>
      _trades[id] == null ? null : {..._trades[id]!};

  /// A copy of proposal [id] as stored, or null.
  Map<String, dynamic>? storedProposal(String id) =>
      _proposals[id] == null ? null : {..._proposals[id]!};

  /// Every stream being listened to fails with [error].
  void failStreams(TradeException error) => _failures.add(error);

  DateTime _now() {
    final now = DateTime.now();
    return _lastTime = now.isAfter(_lastTime)
        ? now
        : _lastTime.add(const Duration(milliseconds: 1));
  }

  /// As the rules: both accounts exist and neither blocked the other.
  void _checkCanTrade(String uid, String other) {
    if (!_isRealMember(uid) ||
        !_isRealMember(other) ||
        _hasBlocked(uid, other) ||
        _hasBlocked(other, uid)) {
      throw TradeException.notSaved;
    }
  }

  Map<String, dynamic> _trade(String id) =>
      _trades[id] ?? (throw TradeException.notFound);

  Map<String, dynamic> _proposal(String id) =>
      _proposals[id] ?? (throw TradeException.notFound);

  void _apply(String tradeId, TradeChange change) {
    _trades[tradeId] = {..._trade(tradeId), ...change.trade};
    for (final MapEntry(:key, :value) in change.proposals.entries) {
      _proposals[key] = {..._proposal(key), ...value};
    }
  }

  @override
  Future<SentProposal> sendProposal(String uid, TradeProposal draft) async {
    final receiver = TradeDocument.receiverOf(uid, draft);
    TradeDocument.termsOf(draft);
    _checkCanTrade(uid, receiver);
    final tradeId = 'trade${++_nextId}';
    final proposalId = 'proposal${++_nextId}';
    final now = _now();
    _trades[tradeId] = TradeDocument.newTradeData(
      uid,
      receiver,
      proposalId,
      draft,
      now,
    );
    _proposals[proposalId] = TradeDocument.proposalData(
      uid,
      receiver,
      tradeId,
      draft,
      now,
    );
    _changes.add(null);
    return (tradeId: tradeId, proposalId: proposalId);
  }

  @override
  Future<String> counterProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required TradeProposal draft,
  }) async {
    final trade = _trade(tradeId);
    final newId = 'proposal${++_nextId}';
    final change = TradeDocument.counter(
      uid,
      tradeId: tradeId,
      trade: trade,
      proposalId: proposalId,
      proposal: _proposal(proposalId),
      newProposalId: newId,
      draft: draft,
      now: _now(),
    );
    _checkCanTrade(uid, TradeDocument.otherOf(trade, uid));
    _apply(tradeId, change);
    _proposals[newId] = change.newProposal!;
    _changes.add(null);
    return newId;
  }

  @override
  Future<void> respondToProposal(
    String uid, {
    required String tradeId,
    required String proposalId,
    required ProposalStatus response,
  }) async {
    final trade = _trade(tradeId);
    final change = TradeDocument.respond(
      uid,
      trade: trade,
      proposalId: proposalId,
      proposal: _proposal(proposalId),
      response: response,
      now: _now(),
    );
    if (response == ProposalStatus.accepted) {
      _checkCanTrade(uid, TradeDocument.otherOf(trade, uid));
    }
    _apply(tradeId, change);
    _changes.add(null);
  }

  @override
  Future<void> scheduleSession(
    String uid, {
    required String tradeId,
    required DateTime scheduledAt,
    required String method,
    required String locationOrLink,
    required String notes,
  }) async {
    final trade = _trade(tradeId);
    final change = TradeDocument.schedule(
      uid,
      trade: trade,
      scheduledAt: scheduledAt,
      method: method,
      locationOrLink: locationOrLink,
      notes: notes,
      now: _now(),
    );
    _checkCanTrade(uid, TradeDocument.otherOf(trade, uid));
    _apply(tradeId, change);
    _changes.add(null);
  }

  @override
  Future<bool> confirmCompletion(String uid, String tradeId) async {
    final result = TradeDocument.confirm(
      uid,
      trade: _trade(tradeId),
      now: _now(),
    );
    _apply(tradeId, result.change);
    _changes.add(null);
    return result.completed;
  }

  @override
  Future<void> markDisputed(String uid, String tradeId) async {
    _apply(
      tradeId,
      TradeDocument.dispute(uid, trade: _trade(tradeId), now: _now()),
    );
    _changes.add(null);
  }

  @override
  Stream<List<OnlineTrade>> watchTrades(String uid) => _watch(
    () => TradeDocument.newestFirst([
      for (final MapEntry(:key, :value) in _trades.entries)
        ?TradeDocument.tradeFromData(key, value, viewerUid: uid),
    ]),
  );

  @override
  Stream<List<TradeProposal>> watchProposals(String uid) => _watch(
    () => [
      for (final MapEntry(:key, :value) in _proposals.entries)
        ?TradeDocument.proposalFromData(key, value, viewerUid: uid),
    ],
  );

  /// A stream of [read], now and after every change, like `snapshots()`.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    StreamSubscription<TradeException>? failures;
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
