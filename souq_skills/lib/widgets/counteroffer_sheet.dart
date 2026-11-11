import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/proposal_service.dart';

import 'trade_action.dart';

import 'proposal_form.dart';

/// Lets a member change a proposal's terms without leaving the current screen.
class CounterofferSheet extends StatelessWidget {
  const CounterofferSheet({required this.proposal, super.key});

  final TradeProposal proposal;

  static Future<void> show(BuildContext context, TradeProposal proposal) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => CounterofferSheet(proposal: proposal),
      );

  @override
  Widget build(BuildContext context) {
    final service = ProposalService();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ProposalForm(
          initial: service.counterDraft(proposal),
          mySkills: ProfileService().currentUser.skillsOffered,
          theirSkills:
              MemberService()
                  .byId(service.otherMemberId(proposal))
                  ?.skillsOffered ??
              const [],
          submitLabel: 'Send counteroffer',
          onSubmit: (draft) async {
            final sent = await context.runTradeAction(
              () => service.counter(proposal.id, draft),
            );
            if (!sent || !context.mounted) return;
            Navigator.pop(context);
            context.showMessage('Counteroffer sent');
          },
        ),
      ),
    );
  }
}
