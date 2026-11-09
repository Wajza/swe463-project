import 'package:flutter/material.dart';

import 'option_sheet.dart';

/// A form field that is filled by picking from a list, not by typing.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelOf,
    this.errorText,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T option)? labelOf;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await OptionSheet.show<T>(
      context,
      title: label,
      options: options,
      labelOf: labelOf,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: current == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: current == null
              ? null
              : Text(labelOf?.call(current) ?? '$current'),
        ),
      ),
    );
  }
}
