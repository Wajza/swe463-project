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
        onSubmit: (topic) {
          SafetyService().fileComplaint(topic);
          context.back();
          context.showMessage(SafetyService.complaintReceivedMessage);
        },
      ),
    ],
  );
}
