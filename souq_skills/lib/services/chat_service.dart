import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/models/conversation.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'notification_service.dart';
import 'online_groups.dart';
import 'repository.dart';
import 'safety_service.dart';

export 'package:souq_skills/data/chat_repository.dart' show ChatException;

enum ChatLoadStatus { notLoaded, loading, loaded, failed }

/// How far loading a conversation, or the list of them, has got.
class ChatLoadState {
  const ChatLoadState(this.status, [this.error]);

  final ChatLoadStatus status;

  /// What went wrong, when [status] is [ChatLoadStatus.failed].
  final String? error;

  bool get isLoading => status == ChatLoadStatus.loading;
  bool get isFailed => status == ChatLoadStatus.failed;
}

/// Chats with real members are kept online and arrive live while the
/// member is signed in, and so do the chats of online group trades
/// ([OnlineGroups]); chats with the built-in demo members, their group
/// chats and the offline demo stay on this device, as before. A conversation's
/// id in the app is the other member's id, or [groupConversationId].
class ChatService {
  static const _groupPrefix = 'group:';

  /// The key of the conversation list in [loadStateOf].
  static const conversationList = '';

  final Repository _repo = Repository.instance;

  static String groupConversationId(String groupId) => '$_groupPrefix$groupId';

  static ChatRepository? _online;

  /// Where real members' chats are kept: Firestore once Firebase has been
  /// initialized. Null in the offline demo, where every chat stays on this
  /// device. Can be replaced, e.g. with a fake; that stops listening to the
  /// previous one.
  static ChatRepository? get repository =>
      _online ??
      (Firebase.apps.isEmpty ? null : _online = FirebaseChatRepository());
  static set repository(ChatRepository? value) {
    _stopListening();
    _online = value;
  }

  // What has been loaded online, for the account in [_listeningFor] only.
  static String? _listeningFor;
  static StreamSubscription<List<ChatConversation>>? _conversationsWatch;
  static bool _conversationsLoaded = false;
  static final Map<String, ChatConversation> _conversations = {};
  static final Map<String, List<Message>> _messages = {};
  static final Map<String, StreamSubscription<List<Message>>> _messageWatches =
      {};
  static final Map<String, ChatLoadState> _states = {};
  static final Set<String> _markingRead = {};
  static final Map<String, Future<void>> _sending = {};

  /// How many screens show each conversation right now.
  static final Map<String, int> _openCounts = {};

  /// Starts listening to the signed-in account's chats, or stops when
  /// nobody is signed in, offline, or the account changed. Called whenever
  /// signing in or out may have changed; does nothing if it did not.
  static void syncSession() {
    final online = repository;
    final uid = AuthService.repository.uid;
    final wanted =
        online != null &&
            Repository.instance.isSignedIn &&
            ChatDocument.isSafeId(uid)
        ? uid
        : null;
    if (wanted == _listeningFor) return;
    _stopListening();
    if (wanted == null || online == null) return;
    _listeningFor = wanted;
    _states[conversationList] = const ChatLoadState(ChatLoadStatus.loading);
    _conversationsWatch = online
        .watchConversations(wanted)
        .listen(
          (items) => _onConversations(wanted, items),
          onError: (Object error) => _onFailed(wanted, conversationList, error),
        );
  }

  /// Forgets everything loaded online, so no account sees another's chats.
  static void _stopListening() {
    _conversationsWatch?.cancel();
    _conversationsWatch = null;
    for (final watch in _messageWatches.values) {
      watch.cancel();
    }
    _messageWatches.clear();
    _listeningFor = null;
    _conversationsLoaded = false;
    _conversations.clear();
    _messages.clear();
    _states.clear();
    _markingRead.clear();
    _sending.clear();
  }

  /// Whether a listener result for [uid] is still wanted.
  static bool _isCurrent(String uid) =>
      uid == _listeningFor && uid == AuthService.repository.uid;

  /// Whether the chat with [memberId] is kept online.
  static bool isOnlineChat(String memberId) =>
      repository != null &&
      !memberId.startsWith(_groupPrefix) &&
      memberId != User.currentUserId &&
      !SafetyService.isDemoMember(memberId) &&
      ChatDocument.isSafeId(memberId);

  /// How loading [conversationId] (or [conversationList]) has got.
  ChatLoadState loadStateOf(String conversationId) {
    final known = _states[conversationId];
    if (known != null) return known;
    if (conversationId != conversationList && !isOnlineChat(conversationId)) {
      return const ChatLoadState(ChatLoadStatus.loaded);
    }
    if (_listeningFor == null) {
      return const ChatLoadState(ChatLoadStatus.notLoaded);
    }
    if (conversationId == conversationList) {
      return const ChatLoadState(ChatLoadStatus.loading);
    }
    // A chat's messages wait for the list, and fail with it.
    final list = _states[conversationList];
    if (list != null && list.isFailed) return list;
    // No message was ever sent: there is nothing to load.
    if (_conversationsLoaded && !_conversations.containsKey(conversationId)) {
      return const ChatLoadState(ChatLoadStatus.loaded);
    }
    return const ChatLoadState(ChatLoadStatus.loading);
  }

  /// The messages in [conversationId], oldest first: those online and any
  /// kept on this device, such as trade notes and proposal cards.
  List<Message> messagesIn(String conversationId) {
    final local = _repo.messages
        .where((message) => message.conversationId == conversationId)
        .toList();
    final online = conversationId.startsWith(_groupPrefix)
        ? _onlineGroupMessages(conversationId)
        : _onlineMessages(conversationId);
    if (online.isEmpty) return local;
    return ChatDocument.oldestFirst([...online, ...local]);
  }

  List<Conversation> conversations() {
    final threads = <String, List<Message>>{};
    for (final message in _repo.messages) {
      threads.putIfAbsent(message.conversationId, () => []).add(message);
    }
    final result = <Conversation>[];
    for (final id in {
      ...threads.keys,
      ..._conversations.keys,
      ...OnlineGroups.chatGroupIds().map(groupConversationId),
    }) {
      final conversation = _summarize(id, threads[id] ?? const []);
      if (conversation != null) result.add(conversation);
    }
    return result..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  }

  int unreadConversationCount() =>
      conversations().where((item) => item.unreadCount > 0).length;

  /// Sends [text] to [memberId]: online to a real member, who answers from
  /// their own device; on this device to a demo member, who replies soon.
  /// Throws a [ChatException] and sends nothing if it fails.
  Future<void> sendToMember(String memberId, String text) {
    if (isOnlineChat(memberId)) return _sendOnline(memberId, text);
    post(memberId, text);
    MemberSimulator().replyInChat(memberId);
    return Future.value();
  }

  /// Sends [text] to [memberId] without asking for a reply, such as a
  /// shared listing. Online for a real member. Throws a [ChatException].
  Future<void> postToMember(String memberId, String text) {
    if (isOnlineChat(memberId)) return _sendOnline(memberId, text);
    post(memberId, text);
    return Future.value();
  }

  /// Shows a step of trade [tradeId] in the online chat with real member
  /// [memberId]: the card of [proposalId] when given, otherwise a note.
  /// Throws a [ChatException].
  Future<void> postTradeUpdate(
    String memberId,
    String text, {
    required String tradeId,
    String? proposalId,
  }) => _send(
    memberId,
    text,
    kind: proposalId == null
        ? ChatMessageKind.system
        : ChatMessageKind.proposal,
    proposalId: proposalId,
    tradeId: tradeId,
  );

  /// Sends [text] to group [groupId]'s chat: online for an online group,
  /// throwing a [ChatException] if it was not sent.
  Future<void> sendToGroup(String groupId, String text) async {
    if (OnlineGroups.group(groupId) == null) {
      return post(groupConversationId(groupId), text);
    }
    try {
      final (online, uid) = OnlineGroups.signedIn();
      await online.sendMessage(uid, groupId, text);
    } on GroupTradeException catch (error) {
      throw ChatException(error.message);
    }
  }

  /// Adds a message written by the current user on this device.
  void post(String conversationId, String text, {String? proposalId}) =>
      _insert(
        conversationId: conversationId,
        text: text,
        isFromCurrentUser: true,
        senderName: _repo.currentUser.name,
        proposalId: proposalId,
      );

  void postSystem(String conversationId, String text) =>
      _insert(conversationId: conversationId, text: text, isSystem: true);

  /// Adds a message written by someone else and notifies the current user.
  void receive(
    String conversationId,
    String senderName,
    String text, {
    String? proposalId,
  }) {
    _insert(
      conversationId: conversationId,
      text: text,
      senderName: senderName,
      isRead: false,
      proposalId: proposalId,
    );
    _notifyMessage(conversationId, senderName, text);
  }

  void markRead(String conversationId) {
    var changed = false;
    for (var i = 0; i < _repo.messages.length; i++) {
      final message = _repo.messages[i];
      if (message.conversationId == conversationId && !message.isRead) {
        _repo.messages[i] = message.markedRead();
        changed = true;
      }
    }
    _markReadOnline(conversationId);
    if (changed) _repo.emitChange();
  }

  /// A screen started showing [conversationId]; its messages are loaded
  /// and kept up to date until every screen showing it has [close]d it.
  void open(String conversationId) {
    _openCounts[conversationId] = (_openCounts[conversationId] ?? 0) + 1;
    _syncMessageWatches();
  }

  void close(String conversationId) {
    final count = (_openCounts[conversationId] ?? 1) - 1;
    count > 0
        ? _openCounts[conversationId] = count
        : _openCounts.remove(conversationId);
    _syncMessageWatches();
  }

  /// Tries loading [conversationId] (or [conversationList]) again.
  void retry(String conversationId) {
    if (conversationId == conversationList) {
      _stopListening();
      syncSession();
    } else {
      _messageWatches.remove(conversationId)?.cancel();
      _states.remove(conversationId);
      _syncMessageWatches();
    }
    _repo.emitChange();
  }

  Future<void> _sendOnline(String memberId, String text) {
    // The same message tapped twice while the first is on its way is sent
    // once.
    final key = '$memberId\n${text.trim()}';
    final pending = _sending[key];
    if (pending != null) return pending;
    final sending = _send(memberId, text);
    _sending[key] = sending;
    return sending.whenComplete(() {
      if (identical(_sending[key], sending)) _sending.remove(key);
    });
  }

  Future<void> _send(
    String memberId,
    String text, {
    ChatMessageKind kind = ChatMessageKind.text,
    String? proposalId,
    String? tradeId,
  }) async {
    final online = repository;
    final uid = AuthService.repository.uid;
    if (online == null || uid == null || !_repo.isSignedIn) {
      throw ChatException.sessionExpired;
    }
    if (SafetyService().isBlocked(memberId)) {
      throw const ChatException('Unblock this member to send a message.');
    }
    final message = await online.sendMessage(
      uid,
      ChatMessageDraft(
        memberId: memberId,
        text: text,
        kind: kind,
        proposalId: proposalId,
        tradeId: tradeId,
      ),
    );
    // Another account signed in meanwhile: not its message to show.
    if (!_isCurrent(uid)) return;
    // Shown straight away; the listener brings the same message by id.
    final messages = _messages[memberId];
    if (messages != null && !messages.any((item) => item.id == message.id)) {
      _messages[memberId] = [...messages, message];
    }
    _repo.emitChange();
  }

  static void _onConversations(String uid, List<ChatConversation> items) {
    if (!_isCurrent(uid)) return;
    final previous = Map.of(_conversations);
    final wasLoaded = _conversationsLoaded;
    _conversations
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.memberId, item)));
    _conversationsLoaded = true;
    _states[conversationList] = const ChatLoadState(ChatLoadStatus.loaded);
    unawaited(MemberService().loadMembers(_conversations.keys));
    // Only what arrives while listening; older messages are just unread.
    if (wasLoaded) {
      for (final item in items) {
        final before = previous[item.memberId];
        if (item.isUnread &&
            item.lastMessageId != before?.lastMessageId &&
            !_openCounts.containsKey(item.memberId)) {
          _notifyOnlineMessage(uid, item);
        }
      }
    }
    _syncMessageWatches();
    Repository.instance.emitChange();
  }

  static void _onMessages(String uid, String memberId, List<Message> items) {
    if (!_isCurrent(uid)) return;
    _messages[memberId] = items;
    _states[memberId] = const ChatLoadState(ChatLoadStatus.loaded);
    Repository.instance.emitChange();
  }

  static void _onFailed(String uid, String key, Object error) {
    if (!_isCurrent(uid)) return;
    _states[key] = ChatLoadState(
      ChatLoadStatus.failed,
      error is ChatException
          ? error.message
          : 'We could not load your chats. Try again.',
    );
    Repository.instance.emitChange();
  }

  /// Listens to the messages of each open conversation that exists online,
  /// and stops for those no longer open.
  static void _syncMessageWatches() {
    final online = repository;
    final uid = _listeningFor;
    for (final id in _messageWatches.keys.toList()) {
      if (!_openCounts.containsKey(id) || uid == null) {
        _messageWatches.remove(id)?.cancel();
        _messages.remove(id);
        _states.remove(id);
      }
    }
    if (online == null || uid == null) return;
    for (final id in _openCounts.keys) {
      // Until the first message, there is nothing online to read.
      if (_messageWatches.containsKey(id) || !_conversations.containsKey(id)) {
        continue;
      }
      _states[id] = const ChatLoadState(ChatLoadStatus.loading);
      _messageWatches[id] = online
          .watchMessages(uid, id)
          .listen(
            (items) => _onMessages(uid, id, items),
            onError: (Object error) => _onFailed(uid, id, error),
          );
    }
  }

  /// The messages of an online group's chat [conversationId], with each
  /// sender's name. Group chats have no read times, so they count as read.
  List<Message> _onlineGroupMessages(String conversationId) => [
    for (final message in OnlineGroups.messages(
      conversationId.substring(_groupPrefix.length),
    ))
      Message(
        id: message.id,
        conversationId: conversationId,
        text: message.text,
        createdAt: message.createdAt,
        isFromCurrentUser: message.senderId == User.currentUserId,
        senderName: MemberService().nameOf(message.senderId),
      ),
  ];

  /// The online messages in [memberId]'s chat, read up to the time the
  /// current member last read it, with the sender's name filled in.
  List<Message> _onlineMessages(String memberId) {
    final messages = _messages[memberId];
    if (messages == null || messages.isEmpty) return const [];
    final readAt = _conversations[memberId]?.readAt;
    final name = MemberService().nameOf(memberId);
    return [
      for (final message in messages)
        Message(
          id: message.id,
          conversationId: message.conversationId,
          text: message.text,
          createdAt: message.createdAt,
          isFromCurrentUser: message.isFromCurrentUser,
          isSystem: message.isSystem,
          senderName: message.isFromCurrentUser ? _repo.currentUser.name : name,
          isRead:
              message.isFromCurrentUser ||
              (readAt != null && !message.createdAt.isAfter(readAt)),
          proposalId: message.proposalId,
        ),
    ];
  }

  void _markReadOnline(String memberId) {
    final online = repository;
    final uid = _listeningFor;
    final conversation = _conversations[memberId];
    if (online == null ||
        uid == null ||
        conversation == null ||
        !conversation.isUnread ||
        !_markingRead.add(memberId)) {
      return;
    }
    // Tried again the next time the chat is shown if it fails.
    online
        .markConversationRead(uid, memberId)
        .then((_) {}, onError: (Object _) {})
        .whenComplete(() => _markingRead.remove(memberId));
  }

  static void _notifyOnlineMessage(String uid, ChatConversation item) {
    final memberId = item.memberId;
    if (SafetyService().isBlocked(memberId)) return;
    // Waits for the sender's name, which may not be known yet.
    MemberService().loadMembers([memberId]).then((_) {
      if (!_isCurrent(uid)) return;
      _notifyMessage(
        memberId,
        MemberService().nameOf(memberId),
        item.lastMessage,
      );
    });
  }

  static void _notifyMessage(
    String conversationId,
    String senderName,
    String text,
  ) => NotificationService().push(
    title: 'New message from $senderName',
    message: text,
    type: NotificationType.message,
    route: AppRoutes.chat,
    routeArgument: conversationId,
  );

  void _insert({
    required String conversationId,
    required String text,
    bool isFromCurrentUser = false,
    bool isSystem = false,
    String senderName = '',
    bool isRead = true,
    String? proposalId,
  }) => _repo.insert(
    _repo.messages,
    Message(
      id: _repo.nextId('msg'),
      conversationId: conversationId,
      text: text,
      createdAt: DateTime.now(),
      isFromCurrentUser: isFromCurrentUser,
      isSystem: isSystem,
      senderName: senderName,
      isRead: isRead,
      proposalId: proposalId,
    ),
  );

  Conversation? _summarize(String id, List<Message> local) {
    final messages = local.isEmpty && _messages[id] == null
        ? local
        : messagesIn(id);
    if (id.startsWith(_groupPrefix)) {
      final groupId = id.substring(_groupPrefix.length);
      final all = OnlineGroups.group(groupId) == null
          ? messages
          : messagesIn(id);
      if (all.isEmpty) return null;
      final last = all.last;
      final unread = all.where((message) => !message.isRead).length;
      final group =
          _repo.find(_repo.groupTrades, groupId) ?? OnlineGroups.group(groupId);
      if (group == null || !group.memberIds.contains(User.currentUserId)) {
        return null;
      }
      return Conversation(
        id: id,
        title: group.title,
        lastMessage: last.text,
        lastAt: last.createdAt,
        unreadCount: unread,
        groupId: groupId,
      );
    }
    if (_repo.blockedMemberIds.contains(id)) return null;
    final online = _conversations[id];
    final member = _repo.find(_repo.members, id);
    // Real members' names may still be loading; demo chats need the member.
    if (member == null && online == null) return null;
    var lastMessage = messages.isEmpty ? '' : messages.last.text;
    var lastAt = messages.isEmpty ? DateTime(0) : messages.last.createdAt;
    if (online != null && online.lastAt.isAfter(lastAt)) {
      lastMessage = online.lastMessage;
      lastAt = online.lastAt;
    }
    var unread = messages.where((message) => !message.isRead).length;
    // Messages not loaded yet: at least the latest is unread.
    if (online != null && _messages[id] == null && online.isUnread) unread++;
    return Conversation(
      id: id,
      title: member?.name ?? 'Member',
      lastMessage: lastMessage,
      lastAt: lastAt,
      unreadCount: unread,
      memberId: id,
    );
  }
}
