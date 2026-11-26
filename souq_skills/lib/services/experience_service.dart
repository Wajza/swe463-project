import 'package:souq_skills/models/experience_level.dart';
import 'package:souq_skills/models/load_status.dart';
import 'package:souq_skills/models/user.dart';

import 'group_trade_service.dart';
import 'listing_service.dart';
import 'online_groups.dart';
import 'review_service.dart';
import 'trade_service.dart';

/// One way to earn XP, with how often the member has done it.
class ExperienceSource {
  const ExperienceSource({
    required this.label,
    required this.xpEach,
    required this.count,
    this.limit,
  });

  final String label;
  final int xpEach;
  final int count;

  /// The most times it counts, if limited.
  final int? limit;

  int get countedTimes => limit == null ? count : count.clamp(0, limit!);
  int get xp => xpEach * countedTimes;
}

/// Works out XP and levels from records the backend already verifies, so
/// XP cannot be raised from the app: trades completed only once both
/// members confirmed (settled in Firestore with the wallets), completed
/// group trades, ratings received (one per member, checked by the rules),
/// and published listings, up to a limit so posting cannot be farmed.
/// Nothing extra is stored; offline, the same rules read this device's data.
class ExperienceService {
  static const tradeXp = 100;
  static const groupTradeXp = 150;
  static const ratingXp = 20;
  static const listingXp = 25;
  static const listingsCounted = 5;
  static const xpPerLevel = 250;

  /// The title from each level on.
  static const _titles = <(int, String)>[
    (1, 'Newcomer'),
    (3, 'Skill Swapper'),
    (6, 'Trusted Trader'),
    (10, 'Community Guide'),
  ];

  static const _me = User.currentUserId;

  /// Whether every record XP is worked out from has loaded, so a low or
  /// zero total is never shown before the real one.
  LoadStatus get loadStatus {
    final trades = TradeService();
    final groupsLoading =
        OnlineGroups.isAvailable &&
        !OnlineGroups.isLoaded &&
        OnlineGroups.loadError == null;
    final listings = ListingService().loadStatus;
    final reviews = ReviewService().stateOf(_me).status;
    final error =
        trades.loadError ??
        OnlineGroups.loadError ??
        listings.error ??
        (reviews == ReviewsLoadStatus.failed
            ? 'We could not load your ratings. Try again.'
            : null);
    return LoadStatus(
      isLoading:
          error == null &&
          (trades.isLoading ||
              groupsLoading ||
              listings.isLoading ||
              reviews != ReviewsLoadStatus.loaded),
      error: error,
      onRetry: retry,
    );
  }

  void retry() {
    if (TradeService().loadError != null) TradeService().retry();
    if (OnlineGroups.loadError != null) OnlineGroups.retry();
    ListingService().refresh();
    ReviewService().refreshReviews(const [_me], refresh: true);
  }

  List<ExperienceSource> sources() {
    final groups = GroupTradeService();
    return [
      ExperienceSource(
        label: 'Completed trades',
        xpEach: tradeXp,
        count: TradeService().completedCount(),
      ),
      ExperienceSource(
        label: 'Completed group trades',
        xpEach: groupTradeXp,
        count: groups
            .all()
            .where((group) => group.isCompleted && groups.isMember(group))
            .length,
      ),
      ExperienceSource(
        label: 'Ratings received',
        xpEach: ratingXp,
        count: ReviewService().receivedBy(_me).length,
      ),
      ExperienceSource(
        label: 'Listings published',
        xpEach: listingXp,
        count: ListingService().mine().length,
        limit: listingsCounted,
      ),
    ];
  }

  int get xp => sources().fold(0, (sum, source) => sum + source.xp);

  ExperienceLevel current() => levelFor(xp);

  static ExperienceLevel levelFor(int xp) {
    final level = 1 + xp ~/ xpPerLevel;
    return ExperienceLevel(
      xp: xp,
      level: level,
      title: titleOf(level),
      levelStartXp: (level - 1) * xpPerLevel,
      nextLevelXp: level * xpPerLevel,
      nextTitle: titleOf(level + 1),
    );
  }

  static String titleOf(int level) =>
      _titles.lastWhere((entry) => level >= entry.$1).$2;
}
