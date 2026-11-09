import 'identifiable.dart';

enum NotificationType {
  message,
  trade,
  groupTrade,
  review,
  searchAlert,
  system,
}

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
}
