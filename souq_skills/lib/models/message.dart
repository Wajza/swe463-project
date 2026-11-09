class Message {
  const Message({
    required this.text,
    required this.isFromCurrentUser,
    this.id = '',
    this.senderName = '',
    this.createdAt,
    this.isRead = true,
  });

  final String id;
  final String text;
  final String senderName;
  final bool isFromCurrentUser;
  final DateTime? createdAt;
  final bool isRead;
}
