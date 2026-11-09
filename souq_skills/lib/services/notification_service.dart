import 'package:souq_skills/models/notification.dart';

import 'repository.dart';

class NotificationService {
  final Repository _repo = Repository.instance;

  List<AppNotification> all() =>
      _repo.notifications.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  AppNotification? byId(String id) => _repo.find(_repo.notifications, id);

  int unreadCount() => _repo.notifications.where((item) => !item.isRead).length;

  /// Adds a notification unless the user has switched off that type.
  void push({
    required String title,
    required String message,
    required NotificationType type,
    String? route,
    String? routeArgument,
  }) {
    if (!_isEnabled(type)) return;
    _repo.insert(
      _repo.notifications,
      AppNotification(
        id: _repo.nextId('n'),
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        route: route,
        routeArgument: routeArgument,
      ),
    );
  }

  void markRead(String id) =>
      _repo.update(_repo.notifications, id, (item) => item.markedRead());

  void markAllRead() {
    for (var i = 0; i < _repo.notifications.length; i++) {
      _repo.notifications[i] = _repo.notifications[i].markedRead();
    }
    _repo.emitChange();
  }

  void setAllEnabled(bool enabled) => _repo.updateSettings(
    _repo.settings.copyWith(
      messageNotifications: enabled,
      tradeNotifications: enabled,
      groupNotifications: enabled,
      searchAlerts: enabled,
    ),
  );

  bool _isEnabled(NotificationType type) => switch (type) {
    NotificationType.message => _repo.settings.messageNotifications,
    NotificationType.trade => _repo.settings.tradeNotifications,
    NotificationType.review => _repo.settings.tradeNotifications,
    NotificationType.groupTrade => _repo.settings.groupNotifications,
    NotificationType.searchAlert => _repo.settings.searchAlerts,
    NotificationType.system => true,
  };
}
