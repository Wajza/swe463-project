import 'package:flutter/material.dart';

/// A multiple-choice set of chips.
class MultiChoiceChipRow extends StatelessWidget {
  const MultiChoiceChipRow({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String option) => onChanged(
    selected.contains(option)
        ? selected.where((item) => item != option).toList()
        : [...selected, option],
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final option in options)
        FilterChip(
          label: Text(option),
          selected: selected.contains(option),
          onSelected: (_) => _toggle(option),
        ),
    ],
  );
}
