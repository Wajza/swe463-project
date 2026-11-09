import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/trade_proposal.dart';

import 'app_text_field.dart';
import 'choice_chip_row.dart';
import 'souq_button.dart';

class ProposalForm extends StatefulWidget {
  const ProposalForm({
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final TradeProposal initial;
  final String submitLabel;
  final ValueChanged<TradeProposal> onSubmit;

  @override
  State<ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends State<ProposalForm> {
  final _formKey = GlobalKey<FormState>();
  late final _offered = TextEditingController(
    text: widget.initial.offeredSkill,
  );
  late final _requested = TextEditingController(
    text: widget.initial.requestedSkill,
  );
  late final _minutes = TextEditingController(
    text: '${widget.initial.sessionsMinutes}',
  );
  late final _notes = TextEditingController(text: widget.initial.notes);
  late String _method = widget.initial.deliveryMethod;

  @override
  void dispose() {
    _offered.dispose();
    _requested.dispose();
    _minutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      widget.initial.copyWith(
        offeredSkill: _offered.text.trim(),
        requestedSkill: _requested.text.trim(),
        sessionsMinutes: int.parse(_minutes.text.trim()),
        deliveryMethod: _method,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _offered,
          label: 'You offer',
          validator: AppValidators.requiredText,
        ),
        AppTextField(
          controller: _requested,
          label: 'You want',
          validator: AppValidators.requiredText,
        ),
        AppTextField(
          controller: _minutes,
          label: 'Session length (minutes)',
          keyboardType: TextInputType.number,
          validator: AppValidators.positiveMinutes,
        ),
        ChoiceChipRow<String>(
          options: AppOptions.deliveryMethods,
          selected: _method,
          onSelected: (value) => setState(() => _method = value),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _notes,
          label: 'Notes (optional)',
          maxLines: 3,
        ),
        SouqButton(label: widget.submitLabel, onPressed: _submit),
      ],
    ),
  );
}
