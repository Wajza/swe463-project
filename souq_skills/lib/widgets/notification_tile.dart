import 'package:flutter/material.dart';
import 'package:souq_skills/models/notification.dart';
class NotificationTile extends StatelessWidget { const NotificationTile({required this.notification, this.onTap, super.key}); final AppNotification notification; final VoidCallback? onTap; @override Widget build(BuildContext context) => ListTile(onTap: onTap, leading: Icon(notification.isRead ? Icons.notifications_none : Icons.notifications), title: Text(notification.title), subtitle: Text(notification.message)); }
