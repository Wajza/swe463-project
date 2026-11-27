import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.hint,
    this.prefixText,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final String? prefixText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;

  /// The keyboard's action key, e.g. next to move to the following field
  /// or done on the last one.
  final TextInputAction? textInputAction;

  /// Called when the action key (Enter on a hardware keyboard) is pressed,
  /// such as to submit the form from its last field.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
      ),
    ),
  );
}
