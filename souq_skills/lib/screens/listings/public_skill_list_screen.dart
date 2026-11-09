import 'package:flutter/material.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';

class PublicSkillListScreen extends StatelessWidget {
  const PublicSkillListScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) => LiveEntity<User>(
    find: () => MemberService().byId(memberId),
    builder: (context, member) {
      final title = '${member.name.split(' ').first}’s skills';
      final listings = ListingService().activeByOwner(memberId);
      return AppPage(
        emptyState: const EmptyState(
          title: 'No active listings',
          message: 'This member has no skills on offer right now.',
        ),
        title: title,
        children: [for (final item in listings) ListingCard(listing: item)],
      );
    },
  );
}
