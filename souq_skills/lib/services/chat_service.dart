import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/conversation.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/user.dart';

import 'member_simulator.dart';
import 'notification_service.dart';
import 'repository.dart';

class ChatService {
  static const supportConversationId = 'support';
  static const _groupPrefix = 'group:';

  final Repository _repo = Repository.instance;

  static String groupConversationId(String groupId) => '$_groupPrefix$groupId';

  List<Message> messagesIn(String conversationId) => _repo.messages
      .where((message) => message.conversationId == conversationId)
      .toList();

  List<Conversation> conversations() {
    final threads = <String, List<Message>>{};
    for (final message in _repo.messages) {
      threads.putIfAbsent(message.conversationId, () => []).add(message);
    }
    final result = <Conversation>[];
    threads.forEach((id, messages) {
      final conversation = _summarize(id, messages);
      if (conversation != null) result.add(conversation);
    });
    return result..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  }

  int unreadConversationCount() =>
      conversations().where((item) => item.unreadCount > 0).length;

  void sendToMember(String memberId, String text) {
    post(memberId, text);
    MemberSimulator().replyInChat(memberId);
  }

  void sendToGroup(String groupId, String text) =>
      post(groupConversationId(groupId), text);

  /// Adds a message written by the current user.
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
    if (conversationId == supportConversationId) return;
    NotificationService().push(
      title: 'New message from $senderName',
      message: text,
      type: NotificationType.message,
      route: AppRoutes.chat,
      routeArgument: conversationId,
    );
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
    if (changed) _repo.emitChange();
  }

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

  Conversation? _summarize(String id, List<Message> messages) {
    if (id == supportConversationId) return null;
    final last = messages.last;
    final unread = messages.where((message) => !message.isRead).length;
    if (id.startsWith(_groupPrefix)) {
      final groupId = id.substring(_groupPrefix.length);
      final group = _repo.find(_repo.groupTrades, groupId);
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
    final member = _repo.find(_repo.members, id);
    if (member == null || _repo.blockedMemberIds.contains(id)) return null;
    return Conversation(
      id: id,
      title: member.name,
      lastMessage: last.text,
      lastAt: last.createdAt,
      unreadCount: unread,
      memberId: id,
    );
  }
}
