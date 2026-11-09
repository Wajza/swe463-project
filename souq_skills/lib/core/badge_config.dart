import 'package:flutter/material.dart';

class BadgeConfig {
  const BadgeConfig._();

  static const firstExchange = 'first_exchange';
  static const trustedTrader = 'trusted_trader';
  static const topRated = 'top_rated';
  static const helpfulReviewer = 'helpful_reviewer';
  static const skillSharer = 'skill_sharer';
  static const communityBuilder = 'community_builder';

  static const _icons = <String, IconData>{
    firstExchange: Icons.handshake_outlined,
    trustedTrader: Icons.verified_outlined,
    topRated: Icons.star_outline,
    helpfulReviewer: Icons.rate_review_outlined,
    skillSharer: Icons.lightbulb_outline,
    communityBuilder: Icons.groups_outlined,
  };

  static IconData iconFor(String badgeId) =>
      _icons[badgeId] ?? Icons.emoji_events_outlined;
}
