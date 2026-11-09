import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/support_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  String _subject = AppOptions.supportSubjects.first;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    SupportService().contact(subject: _subject, message: _message.text);
    context.replaceWith(AppRoutes.supportMessages);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Contact support',
    footer: [SouqButton(label: 'Send message', onPressed: _send)],
    children: [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Subject'),
            ChoiceChipRow<String>(
              options: AppOptions.supportSubjects,
              selected: _subject,
              onSelected: (value) => setState(() => _subject = value),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _message,
              label: 'How can we help?',
              maxLines: 5,
              validator: AppValidators.requiredText,
            ),
          ],
        ),
      ),
    ],
  );
}
