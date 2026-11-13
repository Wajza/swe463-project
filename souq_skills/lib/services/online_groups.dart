import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/group_trade_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'repository.dart';
import 'safety_service.dart';

export 'package:souq_skills/data/group_trade_repository.dart'
    show GroupTradeException;

/// Group trades with real members, kept online and arriving live for every
/// member and invitee while signed in, with their group chats. Groups with
/// the built-in demo members and the offline demo stay on this device, in
/// [Repository], as before; [GroupTradeService] reads both.
///
/// When a group completes, each member's own app claims their reward once.
class OnlineGroups {
  static GroupTradeRepository? _online;

  /// Firestore once Firebase has been initialized; null in the offline
  /// demo. Can be replaced, e.g. with a fake; that stops listening to the
  /// previous one.
  static GroupTradeRepository? get repository =>
      _online ??
      (Firebase.apps.isEmpty ? null : _online = FirebaseGroupTradeRepository());
  static set repository(GroupTradeRepository? value) {
    _stopListening();
    _online = value;
  }

  // What has been loaded, for the account in [_listeningFor] only.
  static String? _listeningFor;
  static StreamSubscription<List<GroupTrade>>? _groupsWatch;
  static bool _loaded = false;
  static final Map<String, GroupTrade> _groups = {};
  static final Map<String, StreamSubscription<List<GroupMessage>>>
  _messageWatches = {};
  static final Map<String, List<GroupMessage>> _messages = {};
  static final Set<String> _claimed = {};
  static final Set<String> _claiming = {};
  static String? _loadError;

  static String? _wantedUid() {
    final uid = AuthService.repository.uid;
    return repository != null &&
            Repository.instance.isSignedIn &&
            GroupTradeDocument.isSafeId(uid)
        ? uid
        : null;
  }

  /// Whether new groups are created online: a real account is signed in
  /// and Firebase is set up.
  static bool get isAvailable => _wantedUid() != null;

  /// Whether the signed-in account's groups have arrived.
  static bool get isLoaded => _loaded && _listeningFor == _wantedUid();

  /// What went wrong loading group trades, until they load again.
  static String? get loadError => _loadError;

  /// Starts listening to the signed-in account's groups, or stops when
  /// nobody is signed in, offline, or the account changed.
  static void syncSession() {
    final online = repository;
    final wanted = _wantedUid();
    if (wanted == _listeningFor) return;
    _stopListening();
    if (wanted == null || online == null) return;
    _listeningFor = wanted;
    _groupsWatch = online
        .watchGroups(wanted)
        .listen(
          (items) => _onGroups(wanted, items),
          onError: (Object error) => _onFailed(wanted, error),
        );
  }

  /// Loads the groups again after a failure.
  static void retry() {
    _stopListening();
    syncSession();
    Repository.instance.emitChange();
  }

  static void _stopListening() {
    _groupsWatch?.cancel();
    _groupsWatch = null;
    for (final watch in _messageWatches.values) {
      watch.cancel();
    }
    _messageWatches.clear();
    _messages.clear();
    _listeningFor = null;
    _loaded = false;
    _groups.clear();
    _claimed.clear();
    _claiming.clear();
    _loadError = null;
  }

  static bool _isCurrent(String uid) =>
      uid == _listeningFor && uid == AuthService.repository.uid;

  static GroupTrade? group(String? id) => _groups[id];

  /// The online groups, as their members and invitees see them.
  static List<GroupTrade> groups() => _groups.values.toList();

  /// The online group chat of [groupId], oldest first.
  static List<GroupMessage> messages(String groupId) =>
      _messages[groupId] ?? const [];

  /// The ids of the online groups whose chat has messages.
  static Iterable<String> chatGroupIds() => _messages.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) => entry.key);

  /// The repository and uid to change groups with, or throws when nobody is
  /// signed in.
  static (GroupTradeRepository, String) signedIn() {
    final online = repository;
    final uid = _wantedUid();
    if (online == null || uid == null) {
      throw GroupTradeException.sessionExpired;
    }
    return (online, uid);
  }

  /// Shows a group the current member just created until it arrives.
  static void remember(GroupTrade group) {
    if (_listeningFor == null) return;
    _groups.putIfAbsent(group.id, () => group);
    Repository.instance.emitChange();
  }

  static void _onGroups(String uid, List<GroupTrade> items) {
    if (!_isCurrent(uid)) return;
    final previous = Map.of(_groups);
    final wasLoaded = _loaded;
    _groups
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.id, item)));
    _loaded = true;
    _loadError = null;
    unawaited(
      MemberService().loadMembers({
        for (final group in items) ...[...group.memberIds, ...group.invitedIds],
      }),
    );
    _syncMessageWatches(uid);
    for (final group in items) {
      if (group.isCompleted && group.memberIds.contains(User.currentUserId)) {
        unawaited(_claimReward(uid, group.id));
      }
      // Only what changes while listening; older groups are just shown.
      if (wasLoaded) _notifyChange(uid, previous[group.id], group);
    }
    Repository.instance.emitChange();
  }

  /// Notifies an invitation to the current member, or the group completing,
  /// when another member made that change.
  static void _notifyChange(String uid, GroupTrade? before, GroupTrade after) {
    const me = User.currentUserId;
    final by = after.lastChangedBy;
    if (by.isEmpty || by == me) return;
    if (after.invitedIds.contains(me) &&
        !(before?.invitedIds.contains(me) ?? false)) {
      _notify(
        uid,
        after.ownerId,
        title: 'Group trade invitation',
        message: (name) => '$name invited you to ${after.title}.',
        route: AppRoutes.groupTradeDetails,
        groupId: after.id,
      );
    } else if (after.isCompleted &&
        before != null &&
        !before.isCompleted &&
        after.memberIds.contains(me)) {
      _notify(
        uid,
        by,
        title: 'Group trade completed',
        message: (_) =>
            'Every member confirmed ${after.title}. Each member gets '
            '${WalletDocument.groupReward} credits.',
        route: AppRoutes.groupTradeDetails,
        groupId: after.id,
      );
    }
  }

  /// Notifies the newest message another member sent to [groupId] while
  /// listening, unless its chat is open.
  static void _notifyMessages(
    String uid,
    String groupId,
    List<GroupMessage> before,
    List<GroupMessage> after,
  ) {
    final known = {for (final message in before) message.id};
    final fresh = [
      for (final message in after)
        if (!known.contains(message.id) &&
            message.senderId != User.currentUserId)
          message,
    ];
    if (fresh.isEmpty ||
        ChatService.isOpen(ChatService.groupConversationId(groupId))) {
      return;
    }
    final latest = fresh.last;
    final title = _groups[groupId]?.title ?? 'your group';
    _notify(
      uid,
      latest.senderId,
      title: 'New message in $title',
      message: (name) => '$name: ${latest.text}',
      type: NotificationType.message,
      route: AppRoutes.groupChat,
      groupId: groupId,
    );
  }

  /// Notifies once [memberId]'s name is known; never from a member the
  /// current user blocked, nor once another account has signed in.
  static void _notify(
    String uid,
    String memberId, {
    required String title,
    required String Function(String name) message,
    required String route,
    required String groupId,
    NotificationType type = NotificationType.groupTrade,
  }) {
    if (SafetyService().isBlocked(memberId)) return;
    MemberService().loadMembers([memberId]).then((_) {
      if (!_isCurrent(uid) || SafetyService().isBlocked(memberId)) return;
      NotificationService().push(
        title: title,
        message: message(MemberService().nameOf(memberId)),
        type: type,
        route: route,
        routeArgument: groupId,
      );
    });
  }

  /// Listens to the chat of each group the member belongs to, and stops
  /// for groups they left.
  static void _syncMessageWatches(String uid) {
    final online = repository;
    final wanted = {
      for (final group in _groups.values)
        if (group.memberIds.contains(User.currentUserId) &&
            group.status != GroupTradeStatus.cancelled)
          group.id,
    };
    for (final id in _messageWatches.keys.toList()) {
      if (!wanted.contains(id)) {
        _messageWatches.remove(id)?.cancel();
        _messages.remove(id);
      }
    }
    if (online == null) return;
    for (final id in wanted) {
      if (_messageWatches.containsKey(id)) continue;
      _messageWatches[id] = online.watchMessages(uid, id).listen(
        (items) {
          if (!_isCurrent(uid)) return;
          final before = _messages[id];
          _messages[id] = items;
          // The first messages to arrive are older ones, never notified.
          if (before != null) _notifyMessages(uid, id, before, items);
          Repository.instance.emitChange();
        },
        // A chat that cannot load stays as it was; the group still shows.
        onError: (Object _) {},
      );
    }
  }

  /// Adds this member's reward for completed group [groupId] once. Tried
  /// again with the next change if it fails.
  static Future<void> _claimReward(String uid, String groupId) async {
    final online = repository;
    if (online == null ||
        _claimed.contains(groupId) ||
        !_claiming.add(groupId)) {
      return;
    }
    try {
      await online.claimReward(uid, groupId);
      if (_isCurrent(uid)) _claimed.add(groupId);
    } on WalletException {
      // Tried again later.
    } on GroupTradeException {
      // Tried again later.
    } finally {
      _claiming.remove(groupId);
    }
  }

  static void _onFailed(String uid, Object error) {
    if (!_isCurrent(uid)) return;
    // What was loaded stays shown.
    _loadError = error is GroupTradeException
        ? error.message
        : 'We could not load your group trades. Try again.';
    Repository.instance.emitChange();
  }
}
