import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/proposal_form.dart';

class CounterofferScreen extends StatelessWidget {
  const CounterofferScreen({required this.proposalId, super.key});

  final String proposalId;

  void _send(BuildContext context, TradeProposal draft) {
    ProposalService().counter(proposalId, draft);
    context.back();
    context.showMessage('Counteroffer sent');
  }

  @override
  Widget build(BuildContext context) {
    final original = ProposalService().byId(proposalId);
    if (original == null) return const NotFoundScreen();
    return AppPage(
      title: 'Counteroffer',
      children: [
        const Text('Change the terms and send them back.'),
        const SizedBox(height: 16),
        ProposalForm(
          // The counteroffer is written from the current user's side.
          initial: original.copyWith(
            offeredSkill: original.requestedSkill,
            requestedSkill: original.offeredSkill,
          ),
          submitLabel: 'Send counteroffer',
          onSubmit: (draft) => _send(context, draft),
        ),
      ],
    );
  }
}
