import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/member_service.dart';

import 'app_text_field.dart';

/// Checks the format of a username and that nobody else has it.
class UsernameField extends StatelessWidget {
  const UsernameField({
    required this.controller,
    this.isEditingOwn = false,
    super.key,
  });

  final TextEditingController controller;
  final bool isEditingOwn;

  String? _validate(String? value) {
    final formatError = AppValidators.username(value);
    if (formatError != null) return formatError;
    final isTaken = MemberService().isUsernameTaken(
      value!.trim(),
      isEditingOwn: isEditingOwn,
    );
    return isTaken ? 'That username is already taken' : null;
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    label: 'Username',
    prefixText: '@',
    validator: _validate,
  );
}
