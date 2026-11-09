import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/group_trade.dart';

import 'app_text_field.dart';
import 'souq_button.dart';

class GroupTradeForm extends StatefulWidget {
  const GroupTradeForm({
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final GroupTrade initial;
  final String submitLabel;
  final ValueChanged<GroupTrade> onSubmit;

  @override
  State<GroupTradeForm> createState() => _GroupTradeFormState();
}

class _GroupTradeFormState extends State<GroupTradeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial.title);
  late final _description = TextEditingController(
    text: widget.initial.description,
  );
  late final _skills = TextEditingController(
    text: widget.initial.skills.join(', '),
  );
  late final _minutes = TextEditingController(
    text: '${widget.initial.sessionsMinutes}',
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _skills.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      widget.initial.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
        skills: _skills.text
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList(),
        sessionsMinutes: int.parse(_minutes.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      children: [
        AppTextField(
          controller: _title,
          label: 'Group name',
          validator: AppValidators.listingTitle,
        ),
        AppTextField(
          controller: _description,
          label: 'Description',
          maxLines: 3,
          validator: AppValidators.listingDescription,
        ),
        AppTextField(
          controller: _skills,
          label: 'Skills, separated by commas',
          validator: AppValidators.requiredText,
        ),
        AppTextField(
          controller: _minutes,
          label: 'Session length (minutes)',
          keyboardType: TextInputType.number,
          validator: AppValidators.positiveMinutes,
        ),
        SouqButton(label: widget.submitLabel, onPressed: _submit),
      ],
    ),
  );
}
