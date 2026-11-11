import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/proposal_service.dart';

import 'trade_action.dart';

import 'counteroffer_sheet.dart';
import 'decline_proposal_dialog.dart';
import 'status_chip.dart';

/// A proposal with its actions on the card itself.
class ProposalCard extends StatelessWidget {
  const ProposalCard({required this.proposal, super.key});

  final TradeProposal proposal;

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
          onPressed: () =>
              context.runTradeAction(() => service.cancel(proposal.id)),
          child: const Text('Cancel'),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () =>
            context.runTradeAction(() => service.accept(proposal.id)),
        child: const Text('Accept'),
      ),
      counter,
      TextButton(
        onPressed: () => DeclineProposalDialog.show(context, proposal.id),
        child: const Text('Decline'),
      ),
    ];
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
            trailing: StatusChip.proposal(proposal.status),
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
