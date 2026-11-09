import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_tile.dart';
import 'package:souq_skills/widgets/souq_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _states = <(String, IconData, String)>[
    ('Loading', Icons.hourglass_empty, AppRoutes.loading),
    ('Error', Icons.error_outline, AppRoutes.error),
    ('Offline', Icons.cloud_off_outlined, AppRoutes.offline),
    ('Not found', Icons.search_off, AppRoutes.notFound),
  ];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'About',
    children: [
      const Center(child: SouqLogo(small: true)),
      const SizedBox(height: 12),
      const Text(
        'Souq Skills 1.0.0\nA community marketplace for trading skills.',
        textAlign: TextAlign.center,
      ),
      SettingsGroup(
        title: 'Preview screen states',
        children: [
          for (final (title, icon, route) in _states)
            SettingsTile(
              title: title,
              icon: icon,
              onTap: () => context.open(route),
            ),
        ],
      ),
    ],
  );
}
