import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/issue_form.dart';

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Send a complaint',
    children: [
      IssueForm(
        intro: 'Choose what your complaint is about.',
        reasons: AppOptions.complaintTopics,
        submitLabel: 'Send complaint',
        askDetails: true,
        // Confirmed only once it was saved.
        onSend: (topic, details) async {
          try {
            await SafetyService().fileComplaint(topic, details: details);
          } on ReportException catch (error) {
            if (context.mounted) context.showMessage(error.message);
            return;
          }
          if (!context.mounted) return;
          context.back();
          context.showMessage(SafetyService.complaintReceivedMessage);
        },
      ),
    ],
  );
}
