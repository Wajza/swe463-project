import 'package:flutter/material.dart';
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
    await context.runTradeAction(() => ProposalService().decline(proposalId));
  }
}
