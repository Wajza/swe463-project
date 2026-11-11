import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/issue_form.dart';

class ReportMemberScreen extends StatelessWidget {
  const ReportMemberScreen({required this.memberId, super.key});

  final String memberId;

  /// Sends the report first; only once it is saved is it shown as received,
  /// and blocking is offered, never done without asking.
  Future<void> _send(
    BuildContext context,
    String reason,
    String details,
  ) async {
    final name = MemberService().nameOf(memberId);
    final String reportId;
    try {
      reportId = (await SafetyService().reportMember(
        memberId: memberId,
        reason: reason,
        details: details,
      )).id;
    } on ReportException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (!context.mounted) return;
    var message = 'Report received';
    if (!SafetyService().isBlocked(memberId) &&
        await ConfirmationDialog.confirm(
          context,
          title: 'Report received',
          message: 'Would you also like to block $name?',
          confirmLabel: 'Block',
          destructive: true,
        )) {
      try {
        await SafetyService().blockMember(memberId);
        message = 'Report received. $name was blocked.';
      } on BlockingException catch (error) {
        // The report itself was sent.
        message =
            'Report received, but $name could not be blocked. '
            '${error.message}';
      }
    }
    if (!context.mounted) return;
    context.replaceWith(AppRoutes.disputeCaseDetails, args: reportId);
    context.showMessage(message);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Report member',
    children: [
      IssueForm(
        intro:
            'Tell us about your concern with ${MemberService().nameOf(memberId)}.',
        reasons: AppOptions.memberReportReasons,
        submitLabel: 'Submit report',
        askDetails: true,
        onSend: (reason, details) => _send(context, reason, details),
      ),
    ],
  );
}
