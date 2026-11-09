import '../models/notification.dart';
import 'repository.dart';

class NotificationService {
  NotificationService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<AppNotification>> getNotifications() async => List.unmodifiable(_repository.notifications);
  Future<void> markAsRead(String id) async {
    final index = _repository.notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _repository.notifications[index] = _repository.notifications[index].copyWith(isRead: true);
    _repository.emitChange();
  }
  Future<void> requestPermission() async {}
}
