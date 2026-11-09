import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

import 'section_header.dart';

/// A titled group of selection controls with an optional validation message.
class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.child,
    this.errorText,
    super.key,
  });

  final String title;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: title),
      child,
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            errorText!,
            style: TextStyle(color: context.colors.error, fontSize: 12),
          ),
        ),
    ],
  );
}
