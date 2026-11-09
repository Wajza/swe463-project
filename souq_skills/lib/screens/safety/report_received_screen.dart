import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class ReportReceivedScreen extends StatelessWidget {
  const ReportReceivedScreen({required this.caseId, super.key});

  final String caseId;

  @override
  Widget build(BuildContext context) => LiveEntity<DisputeCase>(
    find: () => SafetyService().caseById(caseId),
    builder: (context, report) => StatusPage(
      showBackButton: false,
      title: 'Report received',
      message: 'Your case number is ${report.caseNumber}. We will review it.',
      actions: [
        SouqButton(
          label: 'View case',
          onPressed: () =>
              context.replaceWith(AppRoutes.disputeCaseDetails, args: caseId),
        ),
        SouqButton(
          label: 'Done',
          outlined: true,
          onPressed: () => context.back(),
        ),
      ],
    ),
  );
}
