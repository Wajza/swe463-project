import 'package:flutter/material.dart';

class SkillChips extends StatelessWidget {
  const SkillChips({required this.skills, super.key});

  final List<String> skills;

  @override
  Widget build(BuildContext context) => skills.isEmpty
      ? const Text('None added yet')
      : Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [for (final skill in skills) Chip(label: Text(skill))],
        );
}
