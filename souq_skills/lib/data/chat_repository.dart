import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/user.dart';

/// A chat problem explained in words the member can act on.
class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  static const empty = ChatException('Write a message first.');
  static const tooLong = ChatException(
    'Messages can be up to ${ChatDocument.maxTextLength} characters.',
  );
  static const cannotMessageYourself = ChatException(
    'You cannot message yourself.',
  );
  static const notSent = ChatException('Your message could not be sent.');
  static const sessionExpired = ChatException(
    'Your session has expired. Sign in again.',
  );

  @override
  String toString() => message;
}

/// What a stored message is: written by a member, a note about a trade
/// step, or a trade proposal card.
enum ChatMessageKind { text, system, proposal }

/// A direct message before it is sent.
class ChatMessageDraft {
  const ChatMessageDraft({
    required this.memberId,
    required this.text,
    this.kind = ChatMessageKind.text,
    this.proposalId,
    this.tradeId,
  });

  /// The other member's Firebase uid.
  final String memberId;
  final String text;
  final ChatMessageKind kind;

  /// The proposal a [ChatMessageKind.proposal] message shows.
  final String? proposalId;

  /// The trade a system or proposal message is about.
  final String? tradeId;
}

/// A direct conversation as one of its two members sees it.
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.memberId,
    required this.lastMessage,
    required this.lastMessageId,
    required this.lastSenderId,
    required this.lastAt,
    this.readAt,
  });

  /// The stored id, `dm_{smallerUid}_{largerUid}`.
  final String id;

  /// The other member's uid, which is also the conversation's id in the
  /// app, as for every direct chat.
  final String memberId;
  final String lastMessage;
  final String lastMessageId;

  /// [User.currentUserId] when the viewer sent the last message.
  final String lastSenderId;
  final DateTime lastAt;

  /// When the viewer last read the conversation, or null if never.
  final DateTime? readAt;

  /// Whether the other member wrote something the viewer has not read.
  bool get isUnread =>
      lastSenderId != User.currentUserId &&
      (readAt == null || lastAt.isAfter(readAt!));
}

/// Direct chats between two real members, kept online.
///
/// Each pair of members has one conversation at
/// `conversations/{dm_smallerUid_largerUid}`, so both find the same one,
/// with its messages in `conversations/{id}/messages/{messageId}`. Only
/// the two members can read them. Messages are stored by uid only, never
/// with names or phone numbers, and are never changed after sending: read
/// state is each member's `lastReadAt` time on the conversation.
abstract class ChatRepository {
  /// Sends [draft] as [uid]'s message, starting the conversation if it is
  /// the first, and returns it as [uid] sees it. Throws a [ChatException].
  Future<Message> sendMessage(String uid, ChatMessageDraft draft);

  /// [uid]'s conversations, newest first, and again after every change.
  /// Errors are [ChatException]s.
  Stream<List<ChatConversation>> watchConversations(String uid);

  /// The messages [uid] and [memberId] exchanged, oldest first, and again
  /// after every change. Each is marked read; the caller decides what is
  /// unread from the conversation's [ChatConversation.readAt]. Errors are
  /// [ChatException]s.
  Stream<List<Message>> watchMessages(String uid, String memberId);

  /// Records that [uid] has read everything with [memberId] so far. Does
  /// nothing if they never wrote to each other. Throws a [ChatException].
  Future<void> markConversationRead(String uid, String memberId);

  /// Whether message [messageId] with [memberId] is a trade step's note or
  /// proposal card rather than something a member typed. Those steps are
  /// notified by the trade itself, so the chat does not notify them again.
  /// Throws a [ChatException].
  Future<bool> isTradeUpdate(String uid, String memberId, String messageId);
}

/// Converts between the app's chat models and what is stored online.
abstract final class ChatDocument {
  static const maxTextLength = 1000;

  /// The most messages kept in view per conversation, and conversations
  /// per member.
  static const fetchLimit = 200;

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static bool isSafeId(String? id) =>
      id != null && id != User.currentUserId && _safeId.hasMatch(id);

  /// The one conversation id both members use: `dm_` and their uids in
  /// sorted order.
  static String conversationIdFor(String uid, String memberId) {
    if (!isSafeId(uid) || !isSafeId(memberId)) {
      throw const ChatException('This member cannot be messaged.');
    }
    if (uid == memberId) throw ChatException.cannotMessageYourself;
    final ids = participantsOf(uid, memberId);
    return 'dm_${ids[0]}_${ids[1]}';
  }

  /// [uid] and [memberId], smaller first, as stored and checked by the
  /// rules.
  static List<String> participantsOf(String uid, String memberId) =>
      uid.compareTo(memberId) < 0 ? [uid, memberId] : [memberId, uid];

  /// Checks [draft] by [uid] before anything is sent.
  static void validate(String uid, ChatMessageDraft draft) {
    if (!isSafeId(uid)) throw ChatException.sessionExpired;
    conversationIdFor(uid, draft.memberId);
    final text = draft.text.trim();
    if (text.isEmpty) throw ChatException.empty;
    if (text.length > maxTextLength) throw ChatException.tooLong;
    final isProposal = draft.kind == ChatMessageKind.proposal;
    if (isProposal != (draft.proposalId != null) ||
        (draft.proposalId != null && !isSafeId(draft.proposalId)) ||
        (draft.tradeId != null &&
            (draft.kind == ChatMessageKind.text || !isSafeId(draft.tradeId)))) {
      throw ChatException.notSent;
    }
  }

  /// The message fields stored for [draft] by [uid]; `createdAt` is added
  /// by the server.
  static Map<String, dynamic> messageData(String uid, ChatMessageDraft draft) =>
      {
        'senderId': uid,
        'text': draft.text.trim(),
        'kind': draft.kind.name,
        if (draft.proposalId != null) 'proposalId': draft.proposalId,
        if (draft.tradeId != null) 'tradeId': draft.tradeId,
      };

  /// The conversation fields written with message [messageId]; `lastAt`
  /// and the sender's `lastReadAt` are added by the server. Merged into an
  /// existing conversation, this changes only the latest message and the
  /// sender's own read time.
  static Map<String, dynamic> conversationData(
    String uid,
    ChatMessageDraft draft,
    String messageId,
  ) => {
    'kind': 'direct',
    'participantIds': participantsOf(uid, draft.memberId),
    'lastMessage': draft.text.trim(),
    'lastMessageId': messageId,
    'lastSenderId': uid,
  };

  /// Reads a stored message as [viewerUid] sees it, in the conversation
  /// with [memberId]. Names are not stored; the caller fills them in.
  static Message messageFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
    required String memberId,
  }) {
    final proposalId = data['proposalId'];
    return Message(
      id: id,
      conversationId: memberId,
      text: data['text'] is String ? data['text'] as String : '',
      createdAt: dateOf(data['createdAt']),
      isFromCurrentUser: data['senderId'] == viewerUid,
      isSystem: data['kind'] == ChatMessageKind.system.name,
      proposalId: proposalId is String ? proposalId : null,
    );
  }

  /// Reads a stored conversation as [viewerUid] sees it, or null if it is
  /// not a direct conversation of theirs.
  static ChatConversation? conversationFromData(
    String id,
    Map<String, dynamic> data, {
    required String viewerUid,
  }) {
    final ids = data['participantIds'];
    if (ids is! List || ids.length != 2 || !ids.contains(viewerUid)) {
      return null;
    }
    final other = ids.firstWhere((item) => item != viewerUid, orElse: () => '');
    if (other is! String || !isSafeId(other)) return null;
    final sender = data['lastSenderId'];
    final readAt = data['lastReadAt'];
    final viewerRead = readAt is Map ? readAt[viewerUid] : null;
    return ChatConversation(
      id: id,
      memberId: other,
      lastMessage: data['lastMessage'] is String
          ? data['lastMessage'] as String
          : '',
      lastMessageId: data['lastMessageId'] is String
          ? data['lastMessageId'] as String
          : '',
      lastSenderId: sender == viewerUid
          ? User.currentUserId
          : (sender is String ? sender : ''),
      lastAt: dateOf(data['lastAt']),
      readAt: viewerRead == null ? null : dateOf(viewerRead),
    );
  }

  /// A stored time, or now for one the server has not set yet: listeners
  /// see a write of this device before the server has timed it.
  static DateTime dateOf(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    _ => DateTime.now(),
  };

  static List<ChatConversation> newestFirst(Iterable<ChatConversation> items) =>
      items.toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  static List<Message> oldestFirst(Iterable<Message> items) =>
      items.toList()..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
}

/// Direct chats in Cloud Firestore.
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  DocumentReference<Map<String, dynamic>> _conversation(
    String uid,
    String memberId,
  ) => _conversations.doc(ChatDocument.conversationIdFor(uid, memberId));

  @override
  Future<Message> sendMessage(String uid, ChatMessageDraft draft) async {
    ChatDocument.validate(uid, draft);
    final conversation = _conversation(uid, draft.memberId);
    final message = conversation.collection('messages').doc();
    final data = ChatDocument.messageData(uid, draft);
    await _guard(() async {
      // One write: the message, and the conversation showing it as the
      // latest. The rules check that the two match.
      final batch = _firestore.batch()
        ..set(message, {...data, 'createdAt': FieldValue.serverTimestamp()})
        ..set(conversation, {
          ...ChatDocument.conversationData(uid, draft, message.id),
          'lastAt': FieldValue.serverTimestamp(),
          'lastReadAt': {uid: FieldValue.serverTimestamp()},
        }, SetOptions(merge: true));
      await batch.commit();
    });
    return ChatDocument.messageFromData(
      message.id,
      {...data, 'createdAt': DateTime.now()},
      viewerUid: uid,
      memberId: draft.memberId,
    );
  }

  @override
  Stream<List<ChatConversation>> watchConversations(String uid) =>
      _conversations
          .where('participantIds', arrayContains: uid)
          .limit(ChatDocument.fetchLimit)
          .snapshots()
          .map(
            (snapshot) => ChatDocument.newestFirst([
              for (final doc in snapshot.docs)
                ?ChatDocument.conversationFromData(
                  doc.id,
                  doc.data(),
                  viewerUid: uid,
                ),
            ]),
          )
          .transform(_errors('We could not load your chats.'));

  @override
  Stream<List<Message>> watchMessages(String uid, String memberId) =>
      _conversation(uid, memberId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(ChatDocument.fetchLimit)
          .snapshots()
          .map(
            (snapshot) => ChatDocument.oldestFirst([
              for (final doc in snapshot.docs)
                ChatDocument.messageFromData(
                  doc.id,
                  doc.data(),
                  viewerUid: uid,
                  memberId: memberId,
                ),
            ]),
          )
          .transform(_errors('We could not load these messages.'));

  @override
  Future<bool> isTradeUpdate(String uid, String memberId, String messageId) =>
      _guard(() async {
        if (!ChatDocument.isSafeId(messageId)) return false;
        final snapshot = await _conversation(
          uid,
          memberId,
        ).collection('messages').doc(messageId).get();
        final kind = snapshot.data()?['kind'];
        return kind is String && kind != ChatMessageKind.text.name;
      });

  @override
  Future<void> markConversationRead(String uid, String memberId) =>
      _guard(() async {
        try {
          await _conversation(
            uid,
            memberId,
          ).update({'lastReadAt.$uid': FieldValue.serverTimestamp()});
        } on FirebaseException catch (error) {
          // Nothing was ever written, so there is nothing to read.
          if (error.code != 'not-found') rethrow;
        }
      });

  static ChatException _describe(FirebaseException error, String fallback) =>
      ChatException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        // Also when a block stops the message; the member is not told why.
        'permission-denied' => ChatException.notSent.message,
        _ => fallback,
      });

  /// Loading errors: never "could not be sent", which is about sending.
  static StreamTransformer<T, T> _errors<T>(String fallback) =>
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) => sink.addError(
          ChatException(
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
    } on ChatException {
      rethrow;
    } on FirebaseException catch (error) {
      throw _describe(error, 'We could not reach your chats. Try again.');
    } catch (_) {
      throw const ChatException('We could not reach your chats. Try again.');
    }
  }
}

/// Keeps chats in memory, with the same rules as Firestore. Used when
/// Firebase has not been set up, such as in tests, where one instance
/// plays the server for every member.
class DemoChatRepository implements ChatRepository {
  /// [isRealMember] says whether a uid has an account, and [hasBlocked]
  /// whether the first member blocked the second, as the rules check them.
  DemoChatRepository({
    bool Function(String uid)? isRealMember,
    bool Function(String uid, String otherUid)? hasBlocked,
  }) : _isRealMember = isRealMember ?? ((_) => true),
       _hasBlocked = hasBlocked ?? ((_, _) => false);

  final bool Function(String uid) _isRealMember;
  final bool Function(String uid, String otherUid) _hasBlocked;

  final Map<String, Map<String, dynamic>> _conversations = {};
  final Map<String, Map<String, Map<String, dynamic>>> _messages = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  final _failures = StreamController<ChatException>.broadcast(sync: true);
  DateTime _lastTime = DateTime(2000);
  int _nextId = 0;

  /// How many streams are being listened to right now.
  int get activeWatchers => _activeWatchers;
  int _activeWatchers = 0;

  /// Copies of the messages stored in [conversationId], in no order.
  List<Map<String, dynamic>> storedMessages(String conversationId) => [
    for (final data in (_messages[conversationId] ?? const {}).values)
      {...data},
  ];

  /// A copy of conversation [conversationId] as stored, or null.
  Map<String, dynamic>? storedConversation(String conversationId) {
    final data = _conversations[conversationId];
    return data == null ? null : {...data};
  }

  /// Every stream being listened to fails with [error], as when the
  /// connection drops.
  void failStreams(ChatException error) => _failures.add(error);

  /// A server time later than any before it.
  DateTime _now() {
    final now = DateTime.now();
    return _lastTime = now.isAfter(_lastTime)
        ? now
        : _lastTime.add(const Duration(milliseconds: 1));
  }

  @override
  Future<bool> isTradeUpdate(
    String uid,
    String memberId,
    String messageId,
  ) async {
    final id = ChatDocument.conversationIdFor(uid, memberId);
    final kind = _messages[id]?[messageId]?['kind'];
    return kind is String && kind != ChatMessageKind.text.name;
  }

  @override
  Future<Message> sendMessage(String uid, ChatMessageDraft draft) async {
    ChatDocument.validate(uid, draft);
    final other = draft.memberId;
    if (!_isRealMember(uid) ||
        !_isRealMember(other) ||
        _hasBlocked(uid, other) ||
        _hasBlocked(other, uid)) {
      throw ChatException.notSent;
    }
    final id = ChatDocument.conversationIdFor(uid, other);
    final messageId = 'm${++_nextId}';
    final now = _now();
    final data = {...ChatDocument.messageData(uid, draft), 'createdAt': now};
    (_messages[id] ??= {})[messageId] = data;
    final existing = _conversations[id];
    _conversations[id] = {
      ...?existing,
      ...ChatDocument.conversationData(uid, draft, messageId),
      'lastAt': now,
      'lastReadAt': {...?(existing?['lastReadAt'] as Map?), uid: now},
    };
    _changes.add(null);
    return ChatDocument.messageFromData(
      messageId,
      data,
      viewerUid: uid,
      memberId: other,
    );
  }

  @override
  Stream<List<ChatConversation>> watchConversations(String uid) => _watch(
    () => ChatDocument.newestFirst([
      for (final MapEntry(:key, :value) in _conversations.entries)
        ?ChatDocument.conversationFromData(key, value, viewerUid: uid),
    ]),
  );

  @override
  Stream<List<Message>> watchMessages(String uid, String memberId) {
    final id = ChatDocument.conversationIdFor(uid, memberId);
    return _watch(() {
      final conversation = _conversations[id];
      // As the rules: only the two members, once the conversation exists.
      if (conversation == null ||
          !(conversation['participantIds'] as List).contains(uid)) {
        throw ChatException.notSent;
      }
      return ChatDocument.oldestFirst([
        for (final MapEntry(:key, :value) in (_messages[id] ?? {}).entries)
          ChatDocument.messageFromData(
            key,
            value,
            viewerUid: uid,
            memberId: memberId,
          ),
      ]);
    });
  }

  @override
  Future<void> markConversationRead(String uid, String memberId) async {
    final id = ChatDocument.conversationIdFor(uid, memberId);
    final conversation = _conversations[id];
    if (conversation == null) return;
    _conversations[id] = {
      ...conversation,
      'lastReadAt': {...conversation['lastReadAt'] as Map, uid: _now()},
    };
    _changes.add(null);
  }

  /// A stream of [read], now and after every change, like `snapshots()`.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    StreamSubscription<ChatException>? failures;
    late final StreamController<T> controller;
    void emit() {
      try {
        controller.add(read());
      } on ChatException catch (error) {
        controller.addError(error);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        _activeWatchers++;
        changes = _changes.stream.listen((_) => emit());
        failures = _failures.stream.listen(controller.addError);
        emit();
      },
      onCancel: () {
        _activeWatchers--;
        changes?.cancel();
        failures?.cancel();
      },
    );
    return controller.stream;
  }
}
