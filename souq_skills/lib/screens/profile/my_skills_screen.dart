import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/skill_chip_editor.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  final _profile = ProfileService();
  bool _saving = false;

  /// Saves one skill change. On failure the skills stay as they were, so
  /// the member can simply make the change again.
  Future<void> _save(
    Future<void> Function(String skill) change,
    String skill,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await change(skill);
    } on ProfileException catch (error) {
      if (mounted) context.showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'My skills',
      children: [
        if (_saving) const LinearProgressIndicator(),
        SkillChipEditor(
          title: 'Skills I offer',
          skills: _profile.currentUser.skillsOffered,
          enabled: !_saving,
          onAdd: (skill) => _save(_profile.addOfferedSkill, skill),
          onRemove: (skill) => _save(_profile.removeOfferedSkill, skill),
        ),
        const SizedBox(height: 16),
        SkillChipEditor(
          title: 'Skills I want',
          skills: _profile.currentUser.skillsWanted,
          enabled: !_saving,
          onAdd: (skill) => _save(_profile.addWantedSkill, skill),
          onRemove: (skill) => _save(_profile.removeWantedSkill, skill),
        ),
      ],
    ),
  );
}
