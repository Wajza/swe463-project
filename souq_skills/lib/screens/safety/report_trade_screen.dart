import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/issue_form.dart';

class ReportTradeScreen extends StatelessWidget {
  const ReportTradeScreen({required this.tradeId, super.key});

  final String tradeId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Report trade',
    children: [
      IssueForm(
        intro: 'Tell us about the problem with this trade.',
        reasons: AppOptions.tradeIssueReasons,
        submitLabel: 'Submit report',
        onSubmit: (reason, details) {
          final report = SafetyService().reportTrade(
            tradeId: tradeId,
            reason: reason,
            details: details,
          );
          context.replaceWith(AppRoutes.reportReceived, args: report.id);
        },
      ),
    ],
  );
}
