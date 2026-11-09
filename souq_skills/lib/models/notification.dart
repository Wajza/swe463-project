enum NotificationType { message, trade, groupTrade, review, searchAlert, system }

class AppNotification {
  const AppNotification({
    required this.title,
    required this.message,
    this.id = '',
    this.type = NotificationType.system,
    this.isRead = false,
    this.createdAt,
    this.route,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? createdAt;
  final String? route;

  AppNotification copyWith({
    String? id, String? title, String? message, NotificationType? type,
    bool? isRead, DateTime? createdAt, String? route,
  }) => AppNotification(
    id: id ?? this.id, title: title ?? this.title, message: message ?? this.message,
    type: type ?? this.type, isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt, route: route ?? this.route,
  );
}
