import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final user = ProfileService().currentUser;
      return AppPage(
        title: 'Account details',
        footer: [
          SouqButton(
            label: 'Edit profile',
            onPressed: () => context.open(AppRoutes.editProfile),
          ),
        ],
        children: [
          InfoCard(
            tiles: [
              InfoTile(
                label: 'Name',
                value: user.name,
                icon: Icons.person_outline,
              ),
              InfoTile(
                label: 'Username',
                value: '@${user.username}',
                icon: Icons.alternate_email,
              ),
              InfoTile(
                label: 'City',
                value: user.city,
                icon: Icons.location_on_outlined,
              ),
              InfoTile(
                label: user.isVerified ? 'Verified phone' : 'Phone',
                value: '+966 ${user.phone}',
                icon: Icons.phone_outlined,
              ),
            ],
          ),
        ],
      );
    },
  );
}
