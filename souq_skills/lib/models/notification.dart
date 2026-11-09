import 'identifiable.dart';

enum NotificationType { message, trade, groupTrade, review, system }

class AppNotification implements Identifiable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type = NotificationType.system,
    this.isRead = false,
    this.route,
    this.routeArgument,
  });

  @override
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? route;
  final String? routeArgument;

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    message: message,
    createdAt: createdAt,
    type: type,
    isRead: true,
    route: route,
    routeArgument: routeArgument,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'type': type.name,
    'isRead': isRead,
    'route': route,
    'routeArgument': routeArgument,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        type: NotificationType.values.byName(json['type'] as String),
        isRead: json['isRead'] as bool,
        route: json['route'] as String?,
        routeArgument: json['routeArgument'] as String?,
      );
}
