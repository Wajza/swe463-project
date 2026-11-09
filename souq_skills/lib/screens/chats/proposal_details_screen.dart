import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class ProposalDetailsScreen extends StatelessWidget {
  const ProposalDetailsScreen({required this.proposalId, super.key});

  final String proposalId;

  Future<void> _decline(BuildContext context) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Decline proposal?',
      message: 'The other member will be told in your chat.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (confirmed) ProposalService().decline(proposalId);
  }

  void _accept(BuildContext context, TradeProposal proposal) {
    ProposalService().accept(proposalId);
    context.replaceWith(AppRoutes.tradeDetails, args: proposal.tradeId);
  }

  List<Widget> _actions(BuildContext context, TradeProposal proposal) {
    if (proposal.status == ProposalStatus.accepted) {
      return [
        SouqButton(
          label: 'View trade',
          onPressed: () => context.replaceWith(
            AppRoutes.tradeDetails,
            args: proposal.tradeId,
          ),
        ),
      ];
    }
    if (!proposal.isPending) return const [];
    if (!ProposalService().isIncoming(proposal)) {
      return [
        SouqButton(
          label: 'Cancel proposal',
          outlined: true,
          destructive: true,
          onPressed: () => ProposalService().cancel(proposalId),
        ),
      ];
    }
    return [
      SouqButton(label: 'Accept', onPressed: () => _accept(context, proposal)),
      SouqButton(
        label: 'Counteroffer',
        outlined: true,
        onPressed: () => context.open(AppRoutes.counteroffer, args: proposalId),
      ),
      SouqButton(
        label: 'Decline',
        outlined: true,
        destructive: true,
        onPressed: () => _decline(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveEntity<TradeProposal>(
    find: () => ProposalService().byId(proposalId),
    builder: (context, proposal) {
      final sender = MemberService().nameOf(proposal.senderId);
      final isIncoming = ProposalService().isIncoming(proposal);
      return AppPage(
        title: 'Proposal details',
        actions: [
          Center(child: StatusChip.proposal(proposal.status)),
          const SizedBox(width: 16),
        ],
        footer: _actions(context, proposal),
        children: [
          InfoCard(
            tiles: [
              InfoTile(
                label: isIncoming ? '$sender offers' : 'You offer',
                value: proposal.offeredSkill,
                icon: Icons.volunteer_activism_outlined,
              ),
              InfoTile(
                label: isIncoming ? '$sender wants' : 'You want',
                value: proposal.requestedSkill,
                icon: Icons.swap_horiz,
              ),
              InfoTile(
                label: 'Session length',
                value: '${proposal.sessionsMinutes} minutes',
                icon: Icons.timer_outlined,
              ),
              InfoTile(
                label: 'Delivery',
                value: proposal.deliveryMethod,
                icon: Icons.place_outlined,
              ),
              if (proposal.notes.isNotEmpty)
                InfoTile(
                  label: 'Notes',
                  value: proposal.notes,
                  icon: Icons.notes,
                ),
            ],
          ),
          const SectionHeader(title: 'Trading with'),
          MemberTile(memberId: ProposalService().otherMemberId(proposal)),
        ],
      );
    },
  );
}
