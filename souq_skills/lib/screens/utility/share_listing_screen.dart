import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ShareListingScreen extends StatelessWidget {
  const ShareListingScreen({required this.listingId, super.key});

  final String listingId;

  String get _link => 'https://souqskills.app/listing/$listingId';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (context.mounted) context.showMessage('Link copied');
  }

  void _sendToChat(
    BuildContext context,
    SkillListing listing,
    String memberId,
  ) {
    ChatService().post(
      memberId,
      'Check out this skill: ${listing.title}\n$_link',
    );
    context.replaceWith(AppRoutes.chat, args: memberId);
  }

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(listingId),
    builder: (context, listing) {
      final direct = ChatService().conversations().where(
        (item) => !item.isGroup,
      );
      return AppPage(
        title: 'Share listing',
        children: [
          InfoCard(
            tiles: [
              InfoTile(label: listing.title, value: _link, icon: Icons.link),
            ],
          ),
          SouqButton(
            label: 'Copy link',
            icon: Icons.copy,
            onPressed: () => _copy(context),
          ),
          if (direct.isNotEmpty) const SectionHeader(title: 'Send in a chat'),
          for (final conversation in direct)
            Card(
              child: ListTile(
                leading: const Icon(Icons.send_outlined),
                title: Text(conversation.title),
                onTap: () =>
                    _sendToChat(context, listing, conversation.memberId!),
              ),
            ),
        ],
      );
    },
  );
}
