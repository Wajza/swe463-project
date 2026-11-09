import 'identifiable.dart';

/// A chat thread summary derived from the stored messages.
class Conversation implements Identifiable {
  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastAt,
    this.unreadCount = 0,
    this.memberId,
    this.groupId,
  });

  @override
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastAt;
  final int unreadCount;
  final String? memberId;
  final String? groupId;

  bool get isGroup => groupId != null;
}
