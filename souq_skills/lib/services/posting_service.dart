import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/models/user.dart';

import 'group_trade_service.dart';
import 'listing_service.dart';
import 'profile_service.dart';

/// Turns the post form's selections into a listing or a group trade, writing
/// the title and description so the member never has to type them.
class PostingService {
  SkillPost draft(ListingKind kind) {
    final user = ProfileService().currentUser;
    return SkillPost(
      kind: kind,
      city: user.city.isEmpty ? AppOptions.defaultCity : user.city,
      availability: user.availability.isEmpty
          ? AppOptions.availabilities.last
          : user.availability,
      wants: user.skillsWanted.firstOrNull,
    );
  }

  SkillPost fromListing(SkillListing listing) => SkillPost(
    kind: ListingKind.solo,
    category: listing.category,
    skills: [listing.offers],
    wants: listing.wants,
    availability: listing.availability,
    sessionsMinutes: listing.sessionsMinutes,
    city: listing.city,
    onlineOnly: listing.onlineOnly,
    womenOnly: listing.womenOnly,
  );

  SkillPost fromGroup(GroupTrade group) => draft(ListingKind.group).copyWith(
    category: _categoryOf(group),
    skills: group.skills,
    sessionsMinutes: group.sessionsMinutes,
  );

  /// Publishes [post] and returns the id of the new listing or group.
  /// A listing is saved online first and throws a [ListingException] if
  /// that fails; a group trade is created as before.
  Future<String> publish(SkillPost post) async => post.isGroup
      ? GroupTradeService()
            .create(
              GroupTrade(
                title: _groupTitle(post),
                description: _groupDescription(post),
                skills: post.skills,
                sessionsMinutes: post.sessionsMinutes,
              ),
            )
            .id
      : (await ListingService().create(_applyTo(_newListing(post), post))).id;

  /// Saves [post] over [listing]. Throws a [ListingException] on failure.
  Future<void> updateListing(SkillListing listing, SkillPost post) =>
      ListingService().update(_applyTo(listing, post));

  void updateGroup(GroupTrade group, SkillPost post) =>
      GroupTradeService().update(
        group.copyWith(
          title: _groupTitle(post),
          description: _groupDescription(post),
          skills: post.skills,
          sessionsMinutes: post.sessionsMinutes,
        ),
      );

  SkillListing _newListing(SkillPost post) =>
      SkillListing(ownerId: User.currentUserId, category: post.category!);

  SkillListing _applyTo(SkillListing listing, SkillPost post) {
    final skill = post.skills.single;
    final isSameSkill = listing.offers == skill;
    return listing.copyWith(
      category: post.category,
      title: isSameSkill ? listing.title : 'Learn $skill',
      offers: skill,
      wants: post.wants,
      description: isSameSkill
          ? listing.description
          : 'Practical $skill sessions, exchanged for ${post.wants}.',
      availability: post.availability,
      sessionsMinutes: post.sessionsMinutes,
      city: post.city,
      onlineOnly: post.onlineOnly,
      womenOnly: post.womenOnly,
    );
  }

  String _groupTitle(SkillPost post) => '${post.category} skill circle';

  String _groupDescription(SkillPost post) =>
      'A group exchange around ${post.skills.join(', ')}.';

  String? _categoryOf(GroupTrade group) {
    final title = group.title;
    const suffix = ' skill circle';
    return title.endsWith(suffix)
        ? title.substring(0, title.length - suffix.length)
        : null;
  }
}
