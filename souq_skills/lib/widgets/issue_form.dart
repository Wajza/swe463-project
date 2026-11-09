import 'package:flutter/material.dart';

import 'choice_chip_row.dart';
import 'form_section.dart';
import 'souq_button.dart';

/// Shared form for reporting a member, reporting a trade and opening a dispute.
class IssueForm extends StatefulWidget {
  const IssueForm({
    required this.intro,
    required this.reasons,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final String intro;
  final List<String> reasons;
  final String submitLabel;
  final ValueChanged<String> onSubmit;

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  String? _reason;
  bool _showError = false;

  void _submit() {
    final reason = _reason;
    if (reason == null) {
      setState(() => _showError = true);
    } else {
      widget.onSubmit(reason);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.intro),
      FormSection(
        title: 'Reason',
        errorText: _showError && _reason == null ? 'Choose a reason' : null,
        child: ChoiceChipRow<String?>(
          options: widget.reasons,
          selected: _reason,
          onSelected: (value) => setState(() => _reason = value),
        ),
      ),
      const SizedBox(height: 20),
      SouqButton(label: widget.submitLabel, onPressed: _submit),
    ],
  );
}
