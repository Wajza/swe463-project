import 'package:flutter/material.dart';

/// A single-choice set of chips, used for filters and form options.
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelOf,
    super.key,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option)? labelOf;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final option in options)
        ChoiceChip(
          label: Text(labelOf?.call(option) ?? '$option'),
          selected: option == selected,
          onSelected: (_) => onSelected(option),
        ),
    ],
  );
}
