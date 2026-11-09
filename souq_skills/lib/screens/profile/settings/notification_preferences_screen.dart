import 'package:flutter/material.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final profile = ProfileService();
      final settings = profile.settings;
      return AppPage(
        title: 'Notifications',
        children: [
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                title: 'Messages',
                value: settings.messageNotifications,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(messageNotifications: value),
                ),
              ),
              SettingsSwitchTile(
                title: 'Trades and ratings',
                value: settings.tradeNotifications,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(tradeNotifications: value),
                ),
              ),
              SettingsSwitchTile(
                title: 'Group trades',
                value: settings.groupNotifications,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(groupNotifications: value),
                ),
              ),
              SettingsSwitchTile(
                title: 'Search alerts',
                value: settings.searchAlerts,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(searchAlerts: value),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
