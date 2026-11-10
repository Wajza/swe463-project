import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';
import 'package:souq_skills/widgets/settings_tile.dart';

import 'sign_out_dialog.dart';

/// Every preference on one page, changed directly with a switch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _toggle(
    String title,
    bool value,
    AppSettings Function(AppSettings current, bool value) change,
  ) => SettingsSwitchTile(
    title: title,
    value: value,
    onChanged: (next) =>
        ProfileService().updateSettings((current) => change(current, next)),
  );

  Widget _link(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) => SettingsTile(title: title, icon: icon, onTap: () => context.open(route));

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Delete your account?',
      message: 'This removes your profile, listings, credits and ratings.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await AuthService().deleteAccount();
    } on AuthException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (context.mounted) context.resetTo(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final settings = ProfileService().settings;
      return AppPage(
        title: 'Settings',
        children: [
          SettingsGroup(
            title: 'Account',
            children: [
              _link(
                context,
                'Edit profile',
                Icons.edit_outlined,
                AppRoutes.editProfile,
              ),
            ],
          ),
          SettingsGroup(
            title: 'Appearance',
            children: [
              _toggle(
                'Dark mode',
                settings.darkMode,
                (s, v) => s.copyWith(darkMode: v),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Notifications',
            children: [
              _toggle(
                'Messages',
                settings.messageNotifications,
                (s, v) => s.copyWith(messageNotifications: v),
              ),
              _toggle(
                'Trades and ratings',
                settings.tradeNotifications,
                (s, v) => s.copyWith(tradeNotifications: v),
              ),
              _toggle(
                'Group trades',
                settings.groupNotifications,
                (s, v) => s.copyWith(groupNotifications: v),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Privacy',
            children: [
              _toggle(
                'Public profile',
                settings.profileVisible,
                (s, v) => s.copyWith(profileVisible: v),
              ),
              _link(
                context,
                'Blocked members',
                Icons.block,
                AppRoutes.blockedMembers,
              ),
            ],
          ),
          SettingsGroup(
            title: 'Help',
            children: [
              _link(
                context,
                'Help and support',
                Icons.help_outline,
                AppRoutes.help,
              ),
              _link(
                context,
                'Safety centre',
                Icons.shield_outlined,
                AppRoutes.safety,
              ),
              _link(
                context,
                'About and policies',
                Icons.info_outline,
                AppRoutes.about,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsGroup(
            children: [
              SettingsTile(
                title: 'Sign out',
                icon: Icons.logout,
                destructive: true,
                onTap: () => SignOutDialog.show(context),
              ),
              SettingsTile(
                title: 'Delete account',
                icon: Icons.delete_outline,
                destructive: true,
                onTap: () => _deleteAccount(context),
              ),
            ],
          ),
        ],
      );
    },
  );
}
