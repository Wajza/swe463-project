import 'identifiable.dart';

class Message implements Identifiable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.createdAt,
    this.isFromCurrentUser = false,
    this.isSystem = false,
    this.senderName = '',
    this.isRead = true,
    this.proposalId,
  });

  @override
  final String id;
  final String conversationId;
  final String text;
  final DateTime createdAt;
  final bool isFromCurrentUser;
  final bool isSystem;
  final String senderName;
  final bool isRead;
  final String? proposalId;

  Message markedRead() => Message(
    id: id,
    conversationId: conversationId,
    text: text,
    createdAt: createdAt,
    isFromCurrentUser: isFromCurrentUser,
    isSystem: isSystem,
    senderName: senderName,
    isRead: true,
    proposalId: proposalId,
  );
}
