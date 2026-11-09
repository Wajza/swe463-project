import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade_proposal.dart';

import 'status_chip.dart';

class ProposalCard extends StatelessWidget {
  const ProposalCard({required this.proposal, super.key});

  final TradeProposal proposal;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.open(AppRoutes.proposalDetails, args: proposal.id),
      leading: const Icon(Icons.handshake_outlined),
      title: Text('${proposal.offeredSkill} ⇄ ${proposal.requestedSkill}'),
      subtitle: Text(
        '${proposal.sessionsMinutes} minutes • ${proposal.deliveryMethod}',
      ),
      trailing: StatusChip.proposal(proposal.status),
    ),
  );
}
