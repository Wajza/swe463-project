import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/profile_header.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/skill_chips.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class PublicMemberProfileScreen extends StatelessWidget {
  const PublicMemberProfileScreen({required this.memberId, super.key});

  final String memberId;

  Future<void> _block(BuildContext context, User member) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Block ${member.name}?',
      message: 'You will no longer see their listings or chats.',
      confirmLabel: 'Block',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    SafetyService().blockMember(memberId);
    context.resetTo(AppRoutes.home);
    context.showMessage('${member.name} was blocked');
  }

  @override
  Widget build(BuildContext context) => LiveEntity<User>(
    find: () => MemberService().byId(memberId),
    builder: (context, member) {
      final reviews = ReviewService().receivedBy(memberId).take(3);
      final listings = ListingService().activeByOwner(memberId);
      return AppPage(
        title: 'Member profile',
        actions: [
          IconButton(
            tooltip: 'Message',
            onPressed: () => context.open(AppRoutes.chat, args: memberId),
            icon: const Icon(Icons.chat_outlined),
          ),
          OverflowMenu(
            items: [
              MenuAction(
                'Report member',
                () => context.open(AppRoutes.reportMember, args: memberId),
              ),
              MenuAction('Block member', () => _block(context, member)),
            ],
          ),
        ],
        action: SouqButton(
          label: 'Propose a trade',
          icon: Icons.handshake_outlined,
          onPressed: () => context.open(
            AppRoutes.proposalInsideChat,
            args: ProposalRequest(memberId: memberId),
          ),
        ),
        children: [
          ProfileHeader(user: member),
          const SizedBox(height: 14),
          RatingSummary(memberId: memberId),
          if (listings.isNotEmpty) const SectionHeader(title: 'Listings'),
          ...listings.map((listing) => ListingCard(listing: listing)),
          const SectionHeader(title: 'Wants'),
          SkillChips(skills: member.skillsWanted),
          if (reviews.isNotEmpty) const SectionHeader(title: 'Reviews'),
          ...reviews.map((review) => ReviewCard(review: review)),
        ],
      );
    },
  );
}
