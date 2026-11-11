import 'package:flutter/material.dart';
import 'package:souq_skills/core/category_config.dart';

import 'option_sheet.dart';
import 'section_header.dart';

class SkillChipEditor extends StatelessWidget {
  const SkillChipEditor({
    required this.title,
    required this.skills,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
    super.key,
  });

  final String title;
  final List<String> skills;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  /// False while a change is being saved, so it cannot be made twice.
  final bool enabled;

  Future<void> _add(BuildContext context) async {
    final skill = await OptionSheet.show<String>(
      context,
      title: 'Add a skill',
      options: CategoryConfig.allSkills
          .where((item) => !skills.contains(item))
          .toList(),
    );
    if (skill != null) onAdd(skill);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: title),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final skill in skills)
            InputChip(
              label: Text(skill),
              isEnabled: enabled,
              onDeleted: enabled ? () => onRemove(skill) : null,
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            onPressed: enabled ? () => _add(context) : null,
          ),
        ],
      ),
    ],
  );
}
