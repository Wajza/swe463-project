import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/profile_header.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/skill_chips.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class PublicMemberProfileScreen extends StatelessWidget {
  const PublicMemberProfileScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) => LiveEntity<User>(
    find: () => MemberService().byId(memberId),
    builder: (context, member) {
      final reviews = ReviewService().receivedBy(memberId).take(3);
      return AppPage(
        title: 'Member profile',
        actions: [
          PopupMenuButton<String>(
            onSelected: (route) => context.open(route, args: memberId),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: AppRoutes.reportMember,
                child: Text('Report member'),
              ),
              PopupMenuItem(
                value: AppRoutes.blockMember,
                child: Text('Block member'),
              ),
            ],
          ),
        ],
        footer: [
          SouqButton(
            label: 'Propose a trade',
            icon: Icons.handshake_outlined,
            onPressed: () => context.open(
              AppRoutes.proposalInsideChat,
              args: ProposalRequest(memberId: memberId),
            ),
          ),
          SouqButton(
            label: 'Message',
            outlined: true,
            onPressed: () => context.open(AppRoutes.chat, args: memberId),
          ),
        ],
        children: [
          ProfileHeader(user: member),
          const SizedBox(height: 14),
          RatingSummary(memberId: memberId),
          SectionHeader(
            title: 'Offers',
            actionLabel: 'View listings',
            onAction: () =>
                context.open(AppRoutes.publicSkillList, args: memberId),
          ),
          SkillChips(skills: member.skillsOffered),
          const SectionHeader(title: 'Wants'),
          SkillChips(skills: member.skillsWanted),
          if (reviews.isNotEmpty) const SectionHeader(title: 'Reviews'),
          ...reviews.map((review) => ReviewCard(review: review)),
        ],
      );
    },
  );
}
