import 'package:flutter/material.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final profile = ProfileService();
      final settings = profile.settings;
      return AppPage(
        title: 'Privacy',
        children: [
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                title: 'Public profile',
                subtitle: 'Let other members view your profile.',
                value: settings.profileVisible,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(profileVisible: value),
                ),
              ),
              SettingsSwitchTile(
                title: 'Show my location',
                subtitle: 'Show your city on your listings.',
                value: settings.locationVisible,
                onChanged: (value) => profile.updateSettings(
                  (current) => current.copyWith(locationVisible: value),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
