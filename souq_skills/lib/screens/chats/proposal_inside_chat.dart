import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/proposal_form.dart';

class ProposalInsideChat extends StatelessWidget {
  const ProposalInsideChat({required this.request, super.key});

  final ProposalRequest request;

  void _send(BuildContext context, TradeProposal proposal) {
    ProposalService().send(proposal);
    // A proposal started from a listing continues in that member's chat.
    if (request.listingId != null) {
      context.replaceWith(AppRoutes.chat, args: request.memberId);
    } else {
      context.back();
    }
    context.showMessage('Proposal sent');
  }

  @override
  Widget build(BuildContext context) {
    final listingId = request.listingId;
    final listing = listingId == null ? null : ListingService().byId(listingId);
    final mySkills = ProfileService().currentUser.skillsOffered;
    final theirSkills =
        MemberService().byId(request.memberId)?.skillsOffered ?? const [];
    return AppPage(
      title: 'Propose a trade',
      children: [
        Text('Send a proposal to ${MemberService().nameOf(request.memberId)}.'),
        const SizedBox(height: 16),
        ProposalForm(
          initial: TradeProposal(
            senderId: User.currentUserId,
            receiverId: request.memberId,
            offeredSkill: mySkills.firstOrNull ?? '',
            requestedSkill: listing?.offers ?? (theirSkills.firstOrNull ?? ''),
            sessionsMinutes: listing?.sessionsMinutes ?? 60,
          ),
          mySkills: mySkills,
          theirSkills: theirSkills,
          submitLabel: 'Send proposal',
          onSubmit: (proposal) => _send(context, proposal),
        ),
      ],
    );
  }
}
