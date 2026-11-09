import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';

import 'user_avatar.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    required this.memberId,
    this.caption,
    this.trailing,
    super.key,
  });

  final String memberId;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final members = MemberService();
    final member = members.byId(memberId);
    final rating = ReviewService().averageRatingOf(memberId);
    return Card(
      child: ListTile(
        onTap: members.isCurrentUser(memberId)
            ? () => context.resetTo(AppRoutes.profile)
            : () => context.open(AppRoutes.memberProfile, args: memberId),
        leading: UserAvatar(initials: member?.initials ?? '?'),
        title: Text(members.nameOf(memberId)),
        subtitle: Text(caption ?? '★ ${AppFormatters.rating(rating)}'),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
