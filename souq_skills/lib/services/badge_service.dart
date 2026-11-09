import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/badge_config.dart';
import 'package:souq_skills/models/achievement_badge.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';

import 'notification_service.dart';
import 'repository.dart';

/// Works out badge progress from the user's real activity.
class BadgeService {
  final Repository _repo = Repository.instance;

  List<AchievementBadge> badges() {
    final completedTrades = _repo.trades
        .where((trade) => trade.status == TradeStatus.completed)
        .length;
    final received = _repo.reviews.where(
      (review) => review.subjectId == User.currentUserId,
    );
    final given = _repo.reviews
        .where((review) => review.authorId == User.currentUserId)
        .length;
    final listings = _repo.listings
        .where((listing) => listing.ownerId == User.currentUserId)
        .length;
    final groups = _repo.groupTrades
        .where((group) => group.memberIds.contains(User.currentUserId))
        .length;

    return [
      AchievementBadge(
        id: BadgeConfig.firstExchange,
        title: 'First Exchange',
        description: 'You completed your first skill trade.',
        requirement: 'Complete 1 trade',
        progress: completedTrades,
        target: 1,
      ),
      AchievementBadge(
        id: BadgeConfig.trustedTrader,
        title: 'Trusted Trader',
        description: 'A reliable member of the community.',
        requirement: 'Complete 5 trades',
        progress: completedTrades,
        target: 5,
      ),
      AchievementBadge(
        id: BadgeConfig.topRated,
        title: 'Top Rated',
        description: 'Members consistently love trading with you.',
        requirement: 'Receive 3 ratings of 4.5 stars or higher',
        progress: received.where((review) => review.rating >= 4.5).length,
        target: 3,
      ),
      AchievementBadge(
        id: BadgeConfig.helpfulReviewer,
        title: 'Helpful Reviewer',
        description: 'Your ratings help others trade with confidence.',
        requirement: 'Rate 3 exchanges',
        progress: given,
        target: 3,
      ),
      AchievementBadge(
        id: BadgeConfig.skillSharer,
        title: 'Skill Sharer',
        description: 'You offer a variety of skills to the community.',
        requirement: 'Publish 3 listings',
        progress: listings,
        target: 3,
      ),
      AchievementBadge(
        id: BadgeConfig.communityBuilder,
        title: 'Community Builder',
        description: 'You take part in group exchanges.',
        requirement: 'Join 1 group trade',
        progress: groups,
        target: 1,
      ),
    ];
  }

  AchievementBadge? byId(String id) => _repo.find(badges(), id);

  /// Announces any badge that became earned since the last check.
  void sync() {
    for (final badge in badges()) {
      if (badge.isEarned && _repo.awardedBadgeIds.add(badge.id)) {
        NotificationService().push(
          title: 'Badge earned: ${badge.title}',
          message: badge.description,
          type: NotificationType.review,
          route: AppRoutes.badgeDetails,
          routeArgument: badge.id,
        );
      }
    }
  }
}
