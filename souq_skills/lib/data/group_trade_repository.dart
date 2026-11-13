import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/group_trade.dart';

import 'trade_repository.dart';
import 'wallet_repository.dart';

/// A group trade problem explained in words the member can act on.
class GroupTradeException implements Exception {
  const GroupTradeException(this.message);

  final String message;

  static const sessionExpired = GroupTradeException(
    'Your session has expired. Sign in again.',
  );
  static const offline = GroupTradeException('Check your internet connection.');
  static const notFound = GroupTradeException(
    'This group trade is no longer available.',
  );
  static const notSaved = GroupTradeException(
    'This group trade could not be updated.',
  );
  static const invalidDetails = GroupTradeException('Check the group details.');
  static const unknownUsername = GroupTradeException(
    'No member has that username.',
  );
  static const alreadyInGroup = GroupTradeException(
    'This member is already in the group or invited.',
  );
  static const cannotInvite = GroupTradeException(
    'This member cannot be invited.',
  );
  static const groupFull = GroupTradeException(
    'A group can have up to ${GroupTradeDocument.maxSize} members and '
    'invitations.',
  );
  static const notEnoughMembers = GroupTradeException(
    'A group needs at least two members to complete.',
  );
  static const alreadyConfirmed = GroupTradeException(
    'You already confirmed this group trade.',
  );
  static const messageNotSent = GroupTradeException(
    'Your message was not sent. Try again.',
  );

  @override
  String toString() => message;
}

/// A message in an online group chat, with `'me'` as the sender id for the
/// viewer.
class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
}

/// Invite-only group trades between real members, kept online.
///
/// Each group is `groupTrades/{groupId}` and its chat
/// `groupTrades/{groupId}/messages`. Both are stored by uid only, never
/// `'me'`. Members and invitees can read the group; only members its chat.
/// A group completes once every member has confirmed, and then each member
/// claims their own reward once.
abstract class GroupTradeRepository {
  /// Starts an open group organized by [uid] with [draft]'s details;
  /// returns its id. Throws a [GroupTradeException].
  Future<String> create(String uid, GroupTrade draft);

  /// Saves [draft]'s details over group [groupId] (the organizer).
  Future<void> updateDetails(String uid, String groupId, GroupTrade draft);

  /// The uid of the member with [username], or throws
  /// [GroupTradeException.unknownUsername].
  Future<String> findMember(String username);

  /// Invites [memberUid] to [groupId] (the organizer).
  Future<void> invite(String uid, String groupId, String memberUid);

  /// [uid] accepts or declines their invitation to [groupId].
  Future<void> respondToInvitation(
    String uid,
    String groupId, {
    required bool accept,
  });

  /// [memberUid] leaves [groupId] when it is [uid], or the organizer [uid]
  /// removes them.
  Future<void> removeMember(String uid, String groupId, String memberUid);

  /// [uid] confirms the exchange happened; returns whether the group is now
  /// completed, which happens once every member has.
  Future<bool> confirmCompletion(String uid, String groupId);

  /// Cancels open group [groupId] (the organizer).
  Future<void> cancel(String uid, String groupId);

  /// Adds [uid]'s reward for completed group [groupId] to their wallet,
  /// once. Throws a [WalletException].
  Future<void> claimReward(String uid, String groupId);

  /// Sends [text] to [groupId]'s chat as [uid].
  Future<void> sendMessage(String uid, String groupId, String text);

  /// The groups [uid] belongs to or is invited to, as they see them, and
  /// again after every change. Errors are [GroupTradeException]s.
  Stream<List<GroupTrade>> watchGroups(String uid);

  /// [groupId]'s chat, oldest first, and again after every change.
  Stream<List<GroupMessage>> watchMessages(String uid, String groupId);
}

/// Converts between [GroupTrade] and what is stored online, and decides
/// which changes are allowed, as the Firestore rules do.
abstract final class GroupTradeDocument {
  static const maxSize = 20;
  static const maxSkills = 10;
  static const maxTitleLength = 100;
  static const maxDescriptionLength = 500;
  static const maxMessageLength = 1000;
  static const fetchLimit = 200;

  static final _username = RegExp(r'^[a-z0-9_]{3,20}$');

  static bool isSafeId(String? id) => TradeDocument.isSafeId(id);

  /// The details of [draft] as stored, after checking them.
  static Map<String, dynamic> detailsOf(GroupTrade draft) {
    final title = draft.title.trim();
    final description = draft.description.trim();
    final skills = [
      for (final skill in draft.skills)
        if (skill.trim().isNotEmpty) skill.trim(),
    ];
    if (title.isEmpty ||
        title.length > maxTitleLength ||
        description.length > maxDescriptionLength ||
        skills.isEmpty ||
        skills.length > maxSkills ||
        draft.sessionsMinutes < TradeDocument.minMinutes ||
        draft.sessionsMinutes > TradeDocument.maxMinutes) {
      throw GroupTradeException.invalidDetails;
    }
    return {
      'title': title,
      'description': description,
      'skills': skills,
      'sessionsMinutes': draft.sessionsMinutes,
    };
  }

  static Map<String, dynamic> newGroupData(
    String uid,
    GroupTrade draft,
    Object now,
  ) => {
    'ownerId': uid,
    'memberIds': [uid],
    'invitedIds': <String>[],
    ...detailsOf(draft),
    'status': GroupTradeStatus.open.name,
    'completedBy': <String, dynamic>{},
    'createdAt': now,
    'updatedAt': now,
    'updatedBy': uid,
  };

  /// The key of [username]'s claim in `usernames`, or throws if it cannot
  /// be a username.
  static String usernameKey(String username) {
    final key = username.trim().replaceFirst('@', '').toLowerCase();
    if (!_username.hasMatch(key)) throw GroupTradeException.unknownUsername;
    return key;
  }

  static List<String> _ids(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is String) item,
  ];

  static Map<String, dynamic> _confirmations(Object? value) => {
    if (value is Map)
      for (final MapEntry(:key, :value) in value.entries) '$key': value,
  };

  static void _checkOpen(Map<String, dynamic> group) {
    if (group['status'] != GroupTradeStatus.open.name) {
      throw GroupTradeException.notSaved;
    }
  }

  static Map<String, dynamic> _stamp(String uid, Object now) => {
    'updatedAt': now,
    'updatedBy': uid,
  };

  static Map<String, dynamic> edit(
    String uid, {
    required Map<String, dynamic> group,
    required GroupTrade draft,
    required Object now,
  }) {
    _checkOpen(group);
    if (group['ownerId'] != uid) throw GroupTradeException.notSaved;
    return {...detailsOf(draft), ..._stamp(uid, now)};
  }

  static Map<String, dynamic> invite(
    String uid, {
    required Map<String, dynamic> group,
    required String memberUid,
    required Object now,
  }) {
    _checkOpen(group);
    if (group['ownerId'] != uid) throw GroupTradeException.notSaved;
    final members = _ids(group['memberIds']);
    final invited = _ids(group['invitedIds']);
    if (!isSafeId(memberUid) || memberUid == uid) {
      throw GroupTradeException.cannotInvite;
    }
    if (members.contains(memberUid) || invited.contains(memberUid)) {
      throw GroupTradeException.alreadyInGroup;
    }
    if (members.length + invited.length + 1 > maxSize) {
      throw GroupTradeException.groupFull;
    }
    return {
      'invitedIds': [...invited, memberUid],
      ..._stamp(uid, now),
    };
  }

  static Map<String, dynamic> respond(
    String uid, {
    required Map<String, dynamic> group,
    required bool accept,
    required Object now,
  }) {
    _checkOpen(group);
    final invited = _ids(group['invitedIds']);
    if (!invited.contains(uid)) throw GroupTradeException.notFound;
    return {
      if (accept) 'memberIds': [..._ids(group['memberIds']), uid],
      'invitedIds': [...invited]..remove(uid),
      ..._stamp(uid, now),
    };
  }

  /// [memberUid] leaves, or the organizer [uid] removes them. The stored
  /// confirmations without them are [remainingConfirmations]; Firestore
  /// deletes the one key instead.
  static ({Map<String, dynamic> change, Map<String, dynamic> confirmations})
  remove(
    String uid, {
    required Map<String, dynamic> group,
    required String memberUid,
    required Object now,
  }) {
    _checkOpen(group);
    final owner = group['ownerId'];
    final members = _ids(group['memberIds']);
    if (!members.contains(memberUid) ||
        memberUid == owner ||
        (uid != memberUid && uid != owner)) {
      throw GroupTradeException.notSaved;
    }
    return (
      change: {
        'memberIds': [...members]..remove(memberUid),
        ..._stamp(uid, now),
      },
      confirmations: _confirmations(group['completedBy'])..remove(memberUid),
    );
  }

  /// [uid] confirms; the group is completed in the same change once every
  /// member has. A member who confirmed can also complete a group whose
  /// last unconfirmed member has left since.
  static ({Map<String, dynamic> change, bool completed}) confirm(
    String uid, {
    required Map<String, dynamic> group,
    required Object now,
  }) {
    _checkOpen(group);
    final members = _ids(group['memberIds']);
    if (!members.contains(uid)) throw GroupTradeException.notFound;
    if (members.length < 2) throw GroupTradeException.notEnoughMembers;
    final confirmed = _confirmations(group['completedBy']);
    final hadConfirmed = confirmed.containsKey(uid);
    if (!hadConfirmed) confirmed[uid] = now;
    final completed = members.every(confirmed.containsKey);
    if (hadConfirmed && !completed) throw GroupTradeException.alreadyConfirmed;
    return (
      change: {
        if (!hadConfirmed) 'completedBy': confirmed,
        if (completed) 'status': GroupTradeStatus.completed.name,
        ..._stamp(uid, now),
      },
      completed: completed,
    );
  }

  static Map<String, dynamic> cancel(
    String uid, {
    required Map<String, dynamic> group,
    required Object now,
  }) {
    _checkOpen(group);
    if (group['ownerId'] != uid) throw GroupTradeException.notSaved;
    return {'status': GroupTradeStatus.cancelled.name, ..._stamp(uid, now)};
  }

  /// The trimmed text of a message, after checking it.
  static String messageText(String text) {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > maxMessageLength) {
      throw GroupTradeException.messageNotSent;
    }
    return clean;
  }

  /// Whether [viewerUid] belongs to or is invited to stored [group].
  static bool canSee(Map<String, dynamic> group, String viewerUid) =>
      _ids(group['memberIds']).contains(viewerUid) ||
      _ids(group['invitedIds']).contains(viewerUid);

  static String _localId(String id, String viewerUid) =>
      TradeDocument.localIdOf(id, viewerUid);

  /// Reads stored group [id] as [viewerUid] sees it, with `'me'` for their
  /// own uid, or null if it is not theirs or cannot be understood.
  static GroupTrade? groupFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) {
    final owner = data['ownerId'];
    final status = GroupTradeStatus.values.asNameMap()[data['status']];
    final title = data['title'];
    if (owner is! String ||
        status == null ||
        title is! String ||
        !canSee(data, viewerUid)) {
      return null;
    }
    final description = data['description'];
    final minutes = data['sessionsMinutes'];
    final updatedBy = data['updatedBy'];
    return GroupTrade(
      id: id,
      title: title,
      ownerId: _localId(owner, viewerUid),
      memberIds: [
        for (final item in _ids(data['memberIds'])) _localId(item, viewerUid),
      ],
      invitedIds: [
        for (final item in _ids(data['invitedIds'])) _localId(item, viewerUid),
      ],
      skills: _ids(data['skills']),
      status: status,
      description: description is String ? description : '',
      sessionsMinutes: minutes is int ? minutes : 60,
      confirmedIds: [
        for (final item in _confirmations(data['completedBy']).keys)
          _localId(item, viewerUid),
      ],
      lastChangedBy: updatedBy is String ? _localId(updatedBy, viewerUid) : '',
    );
  }

  static GroupMessage? messageFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) {
    final sender = data['senderId'];
    final text = data['text'];
    if (sender is! String || text is! String) return null;
    return GroupMessage(
      id: id,
      senderId: _localId(sender, viewerUid),
      text: text,
      createdAt: TradeDocument.dateOf(data['createdAt']),
    );
  }

  static List<GroupMessage> oldestFirst(Iterable<GroupMessage> items) =>
      items.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

/// Group trades in Cloud Firestore.
class FirebaseGroupTradeRepository implements GroupTradeRepository {
  FirebaseGroupTradeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  late final FirebaseWalletRepository _wallets = FirebaseWalletRepository(
    firestore: _firestore,
  );

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groupTrades');

  DocumentReference<Map<String, dynamic>> _group(String id) {
    if (!GroupTradeDocument.isSafeId(id)) throw GroupTradeException.notFound;
    return _groups.doc(id);
  }

  static Object get _now => FieldValue.serverTimestamp();

  static void _checkUid(String uid) {
    if (!GroupTradeDocument.isSafeId(uid)) {
      throw GroupTradeException.sessionExpired;
    }
  }

  @override
  Future<String> create(String uid, GroupTrade draft) async {
    _checkUid(uid);
    final ref = _groups.doc();
    final data = GroupTradeDocument.newGroupData(uid, draft, _now);
    await _guard(() => ref.set(data));
    return ref.id;
  }

  @override
  Future<void> updateDetails(String uid, String groupId, GroupTrade draft) =>
      _change(
        groupId,
        (group) =>
            GroupTradeDocument.edit(uid, group: group, draft: draft, now: _now),
      );

  @override
  Future<String> findMember(String username) async {
    final key = GroupTradeDocument.usernameKey(username);
    final snapshot = await _guard(
      () => _firestore.collection('usernames').doc(key).get(),
    );
    final uid = snapshot.data()?['uid'];
    if (uid is! String || !GroupTradeDocument.isSafeId(uid)) {
      throw GroupTradeException.unknownUsername;
    }
    return uid;
  }

  @override
  Future<void> invite(String uid, String groupId, String memberUid) => _change(
    groupId,
    (group) => GroupTradeDocument.invite(
      uid,
      group: group,
      memberUid: memberUid,
      now: _now,
    ),
  );

  @override
  Future<void> respondToInvitation(
    String uid,
    String groupId, {
    required bool accept,
  }) => _change(
    groupId,
    (group) => GroupTradeDocument.respond(
      uid,
      group: group,
      accept: accept,
      now: _now,
    ),
  );

  @override
  Future<void> removeMember(String uid, String groupId, String memberUid) =>
      _change(
        groupId,
        (group) => {
          ...GroupTradeDocument.remove(
            uid,
            group: group,
            memberUid: memberUid,
            now: _now,
          ).change,
          // Only their confirmation goes, if they had given one.
          'completedBy.$memberUid': FieldValue.delete(),
        },
      );

  @override
  Future<bool> confirmCompletion(String uid, String groupId) async {
    var completed = false;
    await _change(groupId, (group) {
      final result = GroupTradeDocument.confirm(uid, group: group, now: _now);
      completed = result.completed;
      final change = {...result.change};
      // Only the caller's own time is written.
      if (change.remove('completedBy') != null) {
        change['completedBy.$uid'] = _now;
      }
      return change;
    });
    return completed;
  }

  @override
  Future<void> cancel(String uid, String groupId) => _change(
    groupId,
    (group) => GroupTradeDocument.cancel(uid, group: group, now: _now),
  );

  @override
  Future<void> claimReward(String uid, String groupId) {
    if (!GroupTradeDocument.isSafeId(groupId)) {
      throw GroupTradeException.notFound;
    }
    return _wallets.claimGroupReward(uid, groupId);
  }

  @override
  Future<void> sendMessage(String uid, String groupId, String text) async {
    _checkUid(uid);
    final clean = GroupTradeDocument.messageText(text);
    try {
      await _group(groupId)
          .collection('messages')
          .add({'senderId': uid, 'text': clean, 'createdAt': _now});
    } on FirebaseException catch (error) {
      throw error.code == 'unavailable'
          ? GroupTradeException.offline
          : GroupTradeException.messageNotSent;
    }
  }

  @override
  Stream<List<GroupTrade>> watchGroups(String uid) {
    List<GroupTrade> read(QuerySnapshot<Map<String, dynamic>> snapshot) => [
      for (final doc in snapshot.docs)
        ?GroupTradeDocument.groupFromData(doc.id, doc.data(), viewerUid: uid),
    ];
    return _combine(
      _groups
          .where('memberIds', arrayContains: uid)
          .limit(GroupTradeDocument.fetchLimit)
          .snapshots()
          .map(read),
      _groups
          .where('invitedIds', arrayContains: uid)
          .limit(GroupTradeDocument.fetchLimit)
          .snapshots()
          .map(read),
    ).transform(_errors('We could not load your group trades.'));
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String uid, String groupId) =>
      _group(groupId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(GroupTradeDocument.fetchLimit)
          .snapshots()
          .map(
            (snapshot) => GroupTradeDocument.oldestFirst([
              for (final doc in snapshot.docs)
                ?GroupTradeDocument.messageFromData(
                  doc.id,
                  doc.data(),
                  viewerUid: uid,
                ),
            ]),
          )
          .transform(_errors('We could not load this group chat.'));

  /// The groups of both queries, once each has arrived, by id.
  static Stream<List<GroupTrade>> _combine(
    Stream<List<GroupTrade>> members,
    Stream<List<GroupTrade>> invited,
  ) {
    late final StreamController<List<GroupTrade>> controller;
    List<GroupTrade>? latestMembers;
    List<GroupTrade>? latestInvited;
    final subscriptions = <StreamSubscription<List<GroupTrade>>>[];
    void emit() {
      if (latestMembers == null || latestInvited == null) return;
      controller.add(
        {
          for (final group in [...latestInvited!, ...latestMembers!])
            group.id: group,
        }.values.toList(),
      );
    }

    controller = StreamController<List<GroupTrade>>(
      onListen: () {
        subscriptions
          ..add(
            members.listen((items) {
              latestMembers = items;
              emit();
            }, onError: controller.addError),
          )
          ..add(
            invited.listen((items) {
              latestInvited = items;
              emit();
            }, onError: controller.addError),
          );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Runs [change] on the stored group in a transaction, so it is decided
  /// from the latest state.
  Future<void> _change(
    String groupId,
    Map<String, dynamic> Function(Map<String, dynamic> group) change,
  ) {
    final ref = _group(groupId);
    return _guard(
      () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) throw GroupTradeException.notFound;
        transaction.update(ref, change(data));
      }),
    );
  }

  static StreamTransformer<T, T> _errors<T>(String fallback) =>
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) => sink.addError(
          error is FirebaseException && error.code == 'unavailable'
              ? GroupTradeException.offline
              : GroupTradeException('$fallback Try again.'),
          stackTrace,
        ),
      );

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GroupTradeException {
      rethrow;
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'unavailable' => GroupTradeException.offline,
        'not-found' => GroupTradeException.notFound,
        // Also when a block or a deleted account stops it.
        _ => GroupTradeException.notSaved,
      };
    } catch (_) {
      throw GroupTradeException.notSaved;
    }
  }
}

/// Keeps group trades in memory, with the same rules as Firestore. Used
/// when Firebase has not been set up, such as in tests, where one instance
/// plays the server for every member.
class DemoGroupTradeRepository implements GroupTradeRepository {
  /// [isRealMember] says whether a uid has an account, [hasBlocked] whether
  /// the first member blocked the second, and [uidOfUsername] who holds a
  /// username, as the rules and the `usernames` claims tell. Rewards are
  /// paid into [wallets].
  DemoGroupTradeRepository({
    bool Function(String uid)? isRealMember,
    bool Function(String uid, String otherUid)? hasBlocked,
    String? Function(String usernameKey)? uidOfUsername,
    DemoWalletRepository? wallets,
  }) : _isRealMember = isRealMember ?? ((_) => true),
       _hasBlocked = hasBlocked ?? ((_, _) => false),
       _uidOfUsername = uidOfUsername ?? ((_) => null),
       wallets = wallets ?? DemoWalletRepository();

  final bool Function(String uid) _isRealMember;
  final bool Function(String uid, String otherUid) _hasBlocked;
  final String? Function(String usernameKey) _uidOfUsername;
  final DemoWalletRepository wallets;

  final Map<String, Map<String, dynamic>> _groups = {};
  final Map<String, List<Map<String, dynamic>>> _messages = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  final _failures = StreamController<GroupTradeException>.broadcast(sync: true);
  DateTime _lastTime = DateTime(2000);
  int _nextId = 0;

  /// A copy of group [id] as stored, or null.
  Map<String, dynamic>? storedGroup(String id) =>
      _groups[id] == null ? null : {..._groups[id]!};

  /// A copy of [groupId]'s stored messages.
  List<Map<String, dynamic>> storedMessages(String groupId) => [
    for (final message in _messages[groupId] ?? const []) {...message},
  ];

  /// Every stream being listened to fails with [error].
  void failStreams(GroupTradeException error) => _failures.add(error);

  DateTime _now() {
    final now = DateTime.now();
    return _lastTime = now.isAfter(_lastTime)
        ? now
        : _lastTime.add(const Duration(milliseconds: 1));
  }

  Map<String, dynamic> _group(String id) =>
      _groups[id] ?? (throw GroupTradeException.notFound);

  void _apply(String groupId, Map<String, dynamic> change) {
    _groups[groupId] = {..._group(groupId), ...change};
    _changes.add(null);
  }

  static void _checkUid(String uid) {
    if (!GroupTradeDocument.isSafeId(uid)) {
      throw GroupTradeException.sessionExpired;
    }
  }

  @override
  Future<String> create(String uid, GroupTrade draft) async {
    _checkUid(uid);
    if (!_isRealMember(uid)) throw GroupTradeException.notSaved;
    final id = 'group${++_nextId}';
    _groups[id] = GroupTradeDocument.newGroupData(uid, draft, _now());
    _changes.add(null);
    return id;
  }

  @override
  Future<void> updateDetails(
    String uid,
    String groupId,
    GroupTrade draft,
  ) async => _apply(
    groupId,
    GroupTradeDocument.edit(
      uid,
      group: _group(groupId),
      draft: draft,
      now: _now(),
    ),
  );

  @override
  Future<String> findMember(String username) async {
    final uid = _uidOfUsername(GroupTradeDocument.usernameKey(username));
    if (uid == null || !GroupTradeDocument.isSafeId(uid)) {
      throw GroupTradeException.unknownUsername;
    }
    return uid;
  }

  @override
  Future<void> invite(String uid, String groupId, String memberUid) async {
    final change = GroupTradeDocument.invite(
      uid,
      group: _group(groupId),
      memberUid: memberUid,
      now: _now(),
    );
    // As the rules: a real account, and no block either way.
    if (!_isRealMember(memberUid) ||
        _hasBlocked(uid, memberUid) ||
        _hasBlocked(memberUid, uid)) {
      throw GroupTradeException.notSaved;
    }
    _apply(groupId, change);
  }

  @override
  Future<void> respondToInvitation(
    String uid,
    String groupId, {
    required bool accept,
  }) async => _apply(
    groupId,
    GroupTradeDocument.respond(
      uid,
      group: _group(groupId),
      accept: accept,
      now: _now(),
    ),
  );

  @override
  Future<void> removeMember(
    String uid,
    String groupId,
    String memberUid,
  ) async {
    final result = GroupTradeDocument.remove(
      uid,
      group: _group(groupId),
      memberUid: memberUid,
      now: _now(),
    );
    _apply(groupId, {...result.change, 'completedBy': result.confirmations});
  }

  @override
  Future<bool> confirmCompletion(String uid, String groupId) async {
    final result = GroupTradeDocument.confirm(
      uid,
      group: _group(groupId),
      now: _now(),
    );
    _apply(groupId, result.change);
    return result.completed;
  }

  @override
  Future<void> cancel(String uid, String groupId) async => _apply(
    groupId,
    GroupTradeDocument.cancel(uid, group: _group(groupId), now: _now()),
  );

  @override
  Future<void> claimReward(String uid, String groupId) {
    final group = _groups[groupId];
    return wallets.claimGroupReward(
      uid,
      groupId,
      isCompletedMember:
          group != null &&
          group['status'] == GroupTradeStatus.completed.name &&
          GroupTradeDocument._ids(group['memberIds']).contains(uid),
    );
  }

  @override
  Future<void> sendMessage(String uid, String groupId, String text) async {
    _checkUid(uid);
    final group = _group(groupId);
    final clean = GroupTradeDocument.messageText(text);
    if (!GroupTradeDocument._ids(group['memberIds']).contains(uid) ||
        group['status'] == GroupTradeStatus.cancelled.name) {
      throw GroupTradeException.messageNotSent;
    }
    (_messages[groupId] ??= []).add({
      'id': 'message${++_nextId}',
      'senderId': uid,
      'text': clean,
      'createdAt': _now(),
    });
    _changes.add(null);
  }

  @override
  Stream<List<GroupTrade>> watchGroups(String uid) => _watch(
    () => [
      for (final MapEntry(:key, :value) in _groups.entries)
        ?GroupTradeDocument.groupFromData(key, value, viewerUid: uid),
    ],
  );

  @override
  Stream<List<GroupMessage>> watchMessages(String uid, String groupId) =>
      _watch(() {
        final group = _groups[groupId];
        // As the rules: members only.
        if (group == null ||
            !GroupTradeDocument._ids(group['memberIds']).contains(uid)) {
          return const <GroupMessage>[];
        }
        return GroupTradeDocument.oldestFirst([
          for (final message in _messages[groupId] ?? const [])
            ?GroupTradeDocument.messageFromData(
              message['id'] as String,
              message,
              viewerUid: uid,
            ),
        ]);
      });

  /// A stream of [read], now and after every change, like `snapshots()`.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    StreamSubscription<GroupTradeException>? failures;
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
