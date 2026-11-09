import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';

import 'app_text_field.dart';
import 'choice_chip_row.dart';
import 'section_header.dart';
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
  final void Function(String reason, String details) onSubmit;

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  late String _reason = widget.reasons.first;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_reason, _details.text);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.intro),
        const SectionHeader(title: 'Reason'),
        ChoiceChipRow<String>(
          options: widget.reasons,
          selected: _reason,
          onSelected: (value) => setState(() => _reason = value),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _details,
          label: 'What happened?',
          maxLines: 4,
          validator: AppValidators.requiredText,
        ),
        SouqButton(label: widget.submitLabel, onPressed: _submit),
      ],
    ),
  );
}
