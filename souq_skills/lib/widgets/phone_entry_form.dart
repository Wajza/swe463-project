import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';

import 'app_text_field.dart';
import 'souq_button.dart';

class PhoneEntryForm extends StatefulWidget {
  const PhoneEntryForm({required this.onSubmit, this.helpText, super.key});

  /// Receives a valid phone number and returns an error message, if any.
  final String? Function(String phone) onSubmit;
  final String? helpText;

  @override
  State<PhoneEntryForm> createState() => _PhoneEntryFormState();
}

class _PhoneEntryFormState extends State<PhoneEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = widget.onSubmit(_phone.text.trim()));
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _phone,
            label: 'Phone number',
            hint: '5XXXXXXXX',
            prefixText: '+966 ',
            keyboardType: TextInputType.phone,
            validator: AppValidators.phone,
          ),
          if (widget.helpText != null) Text(widget.helpText!),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Spacer(),
          SouqButton(label: 'Continue', onPressed: _submit),
        ],
      ),
    ),
  );
}
