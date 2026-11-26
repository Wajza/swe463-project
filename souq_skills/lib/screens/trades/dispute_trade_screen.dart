import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/issue_form.dart';

class DisputeTradeScreen extends StatelessWidget {
  const DisputeTradeScreen({required this.tradeId, super.key});

  final String tradeId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Open a dispute',
    children: [
      IssueForm(
        intro: 'Tell us what went wrong. The trade is on hold during review.',
        reasons: AppOptions.tradeIssueReasons,
        submitLabel: 'Submit dispute',
        askDetails: true,
        // Sent online first; the trade is put on hold only once it is saved.
        onSend: (reason, details) async {
          final String caseId;
          try {
            caseId = (await SafetyService().submitTradeDispute(
              tradeId: tradeId,
              reason: reason,
              details: details,
            )).id;
          } on ReportException catch (error) {
            if (context.mounted) context.showMessage(error.message);
            return;
          }
          if (!context.mounted) return;
          context.replaceWith(AppRoutes.disputeCaseDetails, args: caseId);
          context.showMessage('Dispute received');
        },
      ),
    ],
  );
}
