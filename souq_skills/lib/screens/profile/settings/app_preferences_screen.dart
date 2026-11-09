import 'package:flutter/material.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final profile = ProfileService();
      final settings = profile.settings;
      return AppPage(
        title: 'App preferences',
        children: [
          SettingsGroup(
            title: 'Appearance',
            children: [
              SettingsSwitchTile(
                title: 'Dark mode',
                value: settings.darkMode,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(darkMode: value),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Skills shown on Home',
            children: [
              SettingsSwitchTile(
                title: 'Online only',
                value: settings.onlineOnly,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(onlineOnly: value),
                ),
              ),
              SettingsSwitchTile(
                title: 'Women only',
                value: settings.womenOnly,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(womenOnly: value),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
