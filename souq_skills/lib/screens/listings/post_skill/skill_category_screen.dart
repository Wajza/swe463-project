import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/category_icon.dart';
import 'package:souq_skills/widgets/step_progress.dart';

class SkillCategoryScreen extends StatelessWidget {
  const SkillCategoryScreen({super.key});

  void _select(BuildContext context, String category) {
    final user = ProfileService().currentUser;
    context.open(
      AppRoutes.skillDetails,
      args: SkillListing(
        ownerId: User.currentUserId,
        category: category,
        city: user.city,
        availability: user.availability,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Post a skill',
    children: [
      const StepProgress(step: 1, total: 4),
      const Text('Which category fits your skill best?'),
      const SizedBox(height: 14),
      for (final category in CategoryConfig.names)
        Card(
          child: ListTile(
            leading: CategoryIcon(category: category, size: 40),
            title: Text(category),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(context, category),
          ),
        ),
    ],
  );
}
