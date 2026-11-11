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
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class PublicMemberProfileScreen extends StatefulWidget {
  const PublicMemberProfileScreen({required this.memberId, super.key});

  final String memberId;

  @override
  State<PublicMemberProfileScreen> createState() =>
      _PublicMemberProfileScreenState();
}

class _PublicMemberProfileScreenState extends State<PublicMemberProfileScreen> {
  String get memberId => widget.memberId;

  /// True while a member not yet known on this device is being fetched.
  /// Members already known are shown straight away, without fetching.
  late bool _fetching = MemberService().byId(memberId) == null;

  @override
  void initState() {
    super.initState();
    // Their ratings, unless already loaded; nothing for demo members.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ReviewService().refreshReviews([memberId]),
    );
    if (_fetching) {
      MemberService().loadMembers([memberId]).whenComplete(() {
        if (mounted) setState(() => _fetching = false);
      });
    }
  }

  Future<void> _block(BuildContext context, User member) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Block ${member.name}?',
      message: 'You will no longer see their listings or chats.',
      confirmLabel: 'Block',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Blocked online first; the screen only moves on once that worked.
    try {
      await SafetyService().blockMember(memberId);
    } on BlockingException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (!context.mounted) return;
    context.resetTo(AppRoutes.home);
    context.showMessage('${member.name} was blocked');
  }

  Future<void> _unblock(BuildContext context) async {
    final name = MemberService().nameOf(memberId);
    try {
      await SafetyService().unblockMember(memberId);
    } on BlockingException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (context.mounted) context.showMessage('$name was unblocked');
  }

  @override
  Widget build(BuildContext context) => _fetching
      ? const AppPage(
          title: 'Member profile',
          body: Center(child: CircularProgressIndicator()),
        )
      : LiveView(
          builder: (context) => SafetyService().isBlocked(memberId)
              ? _buildBlocked(context)
              : _buildProfile(context),
        );

  /// A blocked member's profile stays hidden, with a way to unblock them.
  Widget _buildBlocked(BuildContext context) =>
      ValueListenableBuilder<Set<String>>(
        valueListenable: SafetyService.changingIds,
        builder: (context, changing, _) {
          final busy = changing.contains(memberId);
          return StatusPage(
            pageTitle: 'Member profile',
            icon: Icons.block,
            title: 'You blocked this member',
            message:
                'You will not see ${MemberService().nameOf(memberId)}\'s '
                'listings or chats. Unblock them to see their profile again.',
            action: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                SouqButton(
                  label: busy ? 'Unblocking…' : 'Unblock',
                  onPressed: busy ? null : () => _unblock(context),
                ),
                TextButton(
                  onPressed: () =>
                      context.open(AppRoutes.reportMember, args: memberId),
                  child: const Text('Report member'),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildProfile(BuildContext context) => LiveEntity<User>(
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
