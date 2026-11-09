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

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'isFromCurrentUser': isFromCurrentUser,
    'isSystem': isSystem,
    'senderName': senderName,
    'isRead': isRead,
    'proposalId': proposalId,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isFromCurrentUser: json['isFromCurrentUser'] as bool,
    isSystem: json['isSystem'] as bool,
    senderName: json['senderName'] as String,
    isRead: json['isRead'] as bool,
    proposalId: json['proposalId'] as String?,
  );
}
