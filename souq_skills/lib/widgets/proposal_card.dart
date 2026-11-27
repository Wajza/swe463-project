import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/trade_service.dart';

import 'trade_action.dart';

import 'counteroffer_sheet.dart';
import 'decline_proposal_dialog.dart';
import 'status_chip.dart';

/// A proposal with its actions on the card itself.
class ProposalCard extends StatelessWidget {
  const ProposalCard({required this.proposal, super.key});

  final TradeProposal proposal;

  /// Runs an answer to the proposal and confirms it once saved; a failure
  /// is explained by [TradeActionFeedback.runTradeAction].
  static Future<void> _respond(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    if (await context.runTradeAction(action) && context.mounted) {
      context.showMessage(done);
    }
  }

  List<Widget> _actions(BuildContext context) {
    final service = ProposalService();
    if (proposal.status == ProposalStatus.accepted) {
      return [
        TextButton(
          onPressed: () =>
              context.open(AppRoutes.tradeDetails, args: proposal.tradeId),
          child: const Text('View trade'),
        ),
      ];
    }
    if (!proposal.isPending) return const [];
    final counter = TextButton(
      onPressed: () => CounterofferSheet.show(context, proposal),
      child: const Text('Counter'),
    );
    if (!service.isIncoming(proposal)) {
      return [
        counter,
        TextButton(
          onPressed: () => _respond(
            context,
            () => service.cancel(proposal.id),
            'Proposal cancelled',
          ),
          child: const Text('Cancel'),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () => _respond(
          context,
          () => service.accept(proposal.id),
          'Proposal accepted. Schedule a session next.',
        ),
        child: const Text('Accept'),
      ),
      counter,
      TextButton(
        onPressed: () => DeclineProposalDialog.show(context, proposal.id),
        child: const Text('Decline'),
      ),
    ];
  }

  /// A proposal stays Accepted once accepted, so an accepted one shows how
  /// its trade has moved on since: Completed or Disputed. Otherwise, and
  /// while the trade is still accepted or not loaded yet, the proposal's
  /// own status.
  StatusChip _statusChip() {
    if (proposal.status == ProposalStatus.accepted) {
      final trade = TradeService().byId(proposal.tradeId);
      if (trade != null &&
          (trade.status == TradeStatus.completed ||
              trade.status == TradeStatus.disputed)) {
        return StatusChip.trade(trade.status);
      }
    }
    return StatusChip.proposal(proposal.status);
  }

  @override
  Widget build(BuildContext context) {
    final service = ProposalService();
    final actions = _actions(context);
    final direction = service.isIncoming(proposal)
        ? 'From ${MemberService().nameOf(proposal.senderId)}'
        : 'Your proposal';
    return Card(
      child: Column(
        children: [
          ListTile(
            onTap: () =>
                context.open(AppRoutes.proposalDetails, args: proposal.id),
            leading: const Icon(Icons.handshake_outlined),
            title: Text('${proposal.offerLabel} ⇄ ${proposal.requestedSkill}'),
            subtitle: Text(
              '$direction • ${proposal.sessionsMinutes} min • '
              '${proposal.deliveryMethod}',
            ),
            trailing: _statusChip(),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }
}
