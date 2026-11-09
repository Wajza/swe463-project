import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/counteroffer_sheet.dart';
import 'package:souq_skills/widgets/decline_proposal_dialog.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class ProposalDetailsScreen extends StatelessWidget {
  const ProposalDetailsScreen({required this.proposalId, super.key});

  final String proposalId;

  void _accept(BuildContext context, TradeProposal proposal) {
    ProposalService().accept(proposalId);
    context.replaceWith(AppRoutes.tradeDetails, args: proposal.tradeId);
  }

  Widget? _mainAction(BuildContext context, TradeProposal proposal) {
    if (proposal.status == ProposalStatus.accepted) {
      return SouqButton(
        label: 'View trade',
        onPressed: () =>
            context.replaceWith(AppRoutes.tradeDetails, args: proposal.tradeId),
      );
    }
    if (proposal.isPending && ProposalService().isIncoming(proposal)) {
      return SouqButton(
        label: 'Accept',
        onPressed: () => _accept(context, proposal),
      );
    }
    return null;
  }

  List<MenuAction> _menu(BuildContext context, TradeProposal proposal) {
    if (!proposal.isPending) return const [];
    if (!ProposalService().isIncoming(proposal)) {
      return [
        MenuAction(
          'Counteroffer',
          () => CounterofferSheet.show(context, proposal),
        ),
        MenuAction(
          'Cancel proposal',
          () => ProposalService().cancel(proposalId),
        ),
      ];
    }
    return [
      MenuAction(
        'Counteroffer',
        () => CounterofferSheet.show(context, proposal),
      ),
      MenuAction(
        'Decline',
        () => DeclineProposalDialog.show(context, proposalId),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveEntity<TradeProposal>(
    find: () => ProposalService().byId(proposalId),
    builder: (context, proposal) {
      final sender = MemberService().nameOf(proposal.senderId);
      final isIncoming = ProposalService().isIncoming(proposal);
      final menu = _menu(context, proposal);
      return AppPage(
        title: 'Proposal details',
        actions: [if (menu.isNotEmpty) OverflowMenu(items: menu)],
        action: _mainAction(context, proposal),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.proposal(proposal.status),
          ),
          const SizedBox(height: 12),
          InfoCard(
            tiles: [
              InfoTile(
                label: isIncoming ? '$sender offers' : 'You offer',
                value: proposal.offerLabel,
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
