import 'package:flutter/material.dart';

import 'section_header.dart';

class SkillChipEditor extends StatefulWidget {
  const SkillChipEditor({
    required this.title,
    required this.skills,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final String title;
  final List<String> skills;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<SkillChipEditor> createState() => _SkillChipEditorState();
}

class _SkillChipEditorState extends State<SkillChipEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final skill = _controller.text.trim();
    if (skill.isEmpty) return;
    widget.onAdd(skill);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: widget.title),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final skill in widget.skills)
            InputChip(
              label: Text(skill),
              onDeleted: () => widget.onRemove(skill),
            ),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _controller,
        onSubmitted: (_) => _add(),
        decoration: InputDecoration(
          labelText: 'Add a skill',
          suffixIcon: IconButton(
            tooltip: 'Add',
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    ],
  );
}
