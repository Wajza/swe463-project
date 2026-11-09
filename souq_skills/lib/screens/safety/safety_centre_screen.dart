import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_tile.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final cases = SafetyService().cases();
      return AppPage(
        title: 'Safety centre',
        children: [
          const InfoCard(
            tiles: [
              InfoTile(
                label: 'Meet safely',
                value: 'Choose public places for in-person sessions.',
                icon: Icons.place_outlined,
              ),
              InfoTile(
                label: 'Protect your details',
                value: 'Keep personal information inside the app.',
                icon: Icons.lock_outline,
              ),
              InfoTile(
                label: 'Speak up',
                value: 'Report a member from their profile menu.',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          SettingsGroup(
            title: 'Get help',
            children: [
              SettingsTile(
                title: 'Community guidelines',
                icon: Icons.groups_outlined,
                onTap: () => context.open(AppRoutes.communityGuidelines),
              ),
              SettingsTile(
                title: 'Blocked members',
                icon: Icons.block,
                onTap: () => context.open(AppRoutes.blockedMembers),
              ),
              SettingsTile(
                title: 'Support messages',
                icon: Icons.forum_outlined,
                onTap: () => context.open(AppRoutes.supportMessages),
              ),
            ],
          ),
          if (cases.isNotEmpty) const SectionHeader(title: 'My cases'),
          for (final item in cases)
            Card(
              child: ListTile(
                onTap: () =>
                    context.open(AppRoutes.disputeCaseDetails, args: item.id),
                title: Text(item.caseNumber),
                subtitle: Text('${item.kind.label} • ${item.reason}'),
                trailing: StatusChip.dispute(item.status),
              ),
            ),
        ],
      );
    },
  );
}
