import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_tile.dart';

import 'sign_out_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _link(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) => SettingsTile(title: title, icon: icon, onTap: () => context.open(route));

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Settings',
    children: [
      SettingsGroup(
        title: 'Account',
        children: [
          _link(
            context,
            'Account details',
            Icons.person_outline,
            AppRoutes.accountDetails,
          ),
          _link(
            context,
            'Edit profile',
            Icons.edit_outlined,
            AppRoutes.editProfile,
          ),
        ],
      ),
      SettingsGroup(
        title: 'Preferences',
        children: [
          _link(
            context,
            'App preferences',
            Icons.tune,
            AppRoutes.appPreferences,
          ),
          _link(
            context,
            'Notifications',
            Icons.notifications_none,
            AppRoutes.notificationPreferences,
          ),
          _link(
            context,
            'Privacy',
            Icons.lock_outline,
            AppRoutes.privacySettings,
          ),
          _link(
            context,
            'Location',
            Icons.location_on_outlined,
            AppRoutes.locationPermission,
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
        title: 'Support',
        children: [
          _link(context, 'Help center', Icons.help_outline, AppRoutes.help),
          _link(
            context,
            'Contact support',
            Icons.support_agent,
            AppRoutes.contactSupport,
          ),
          _link(
            context,
            'Support messages',
            Icons.forum_outlined,
            AppRoutes.supportMessages,
          ),
          _link(
            context,
            'Safety centre',
            Icons.shield_outlined,
            AppRoutes.safety,
          ),
        ],
      ),
      SettingsGroup(
        title: 'About',
        children: [
          _link(context, 'Terms', Icons.description_outlined, AppRoutes.terms),
          _link(
            context,
            'Privacy policy',
            Icons.privacy_tip_outlined,
            AppRoutes.privacyPolicy,
          ),
          _link(
            context,
            'Community guidelines',
            Icons.groups_outlined,
            AppRoutes.communityGuidelines,
          ),
          _link(
            context,
            'About Souq Skills',
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
            onTap: () => context.open(AppRoutes.deleteAccount),
          ),
        ],
      ),
    ],
  );
}
