import 'package:flutter/material.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/skill_chip_editor.dart';

class MySkillsScreen extends StatelessWidget {
  const MySkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService();
    return LiveView(
      builder: (context) => AppPage(
        title: 'My skills',
        children: [
          SkillChipEditor(
            title: 'Skills I offer',
            skills: profile.currentUser.skillsOffered,
            onAdd: profile.addOfferedSkill,
            onRemove: profile.removeOfferedSkill,
          ),
          const SizedBox(height: 16),
          SkillChipEditor(
            title: 'Skills I want',
            skills: profile.currentUser.skillsWanted,
            onAdd: profile.addWantedSkill,
            onRemove: profile.removeWantedSkill,
          ),
        ],
      ),
    );
  }
}
