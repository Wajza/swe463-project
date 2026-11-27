import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/services/proposal_service.dart';

import 'trade_action.dart';

import 'confirmation_dialog.dart';

abstract final class DeclineProposalDialog {
  static Future<void> show(BuildContext context, String proposalId) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Decline proposal?',
      message: 'The other member will be told in your chat.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final declined = await context.runTradeAction(
      () => ProposalService().decline(proposalId),
    );
    if (declined && context.mounted) context.showMessage('Proposal declined');
  }
}
