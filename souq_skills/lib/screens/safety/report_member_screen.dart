import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/issue_form.dart';

class ReportMemberScreen extends StatelessWidget {
  const ReportMemberScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Report member',
    children: [
      IssueForm(
        intro:
            'Tell us about your concern with ${MemberService().nameOf(memberId)}.',
        reasons: AppOptions.memberReportReasons,
        submitLabel: 'Submit report',
        onSubmit: (reason, details) {
          final report = SafetyService().reportMember(
            memberId: memberId,
            reason: reason,
            details: details,
          );
          context.replaceWith(AppRoutes.reportReceived, args: report.id);
        },
      ),
    ],
  );
}
