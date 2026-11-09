import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/models/user.dart';

import 'seed_data.dart';

/// Converts the app's data to and from the JSON kept by the data source.
class SnapshotCodec {
  const SnapshotCodec._();

  static const version = 4;

  static Map<String, dynamic> encode(SeedData data) => {
    'version': version,
    'currentUser': data.currentUser.toJson(),
    'settings': data.settings.toJson(),
    'members': _encodeAll(data.members, (item) => item.toJson()),
    'listings': _encodeAll(data.listings, (item) => item.toJson()),
    'messages': _encodeAll(data.messages, (item) => item.toJson()),
    'proposals': _encodeAll(data.proposals, (item) => item.toJson()),
    'trades': _encodeAll(data.trades, (item) => item.toJson()),
    'sessions': _encodeAll(data.sessions, (item) => item.toJson()),
    'groupTrades': _encodeAll(data.groupTrades, (item) => item.toJson()),
    'notifications': _encodeAll(data.notifications, (item) => item.toJson()),
    'transactions': _encodeAll(data.transactions, (item) => item.toJson()),
    'reviews': _encodeAll(data.reviews, (item) => item.toJson()),
    'disputes': _encodeAll(data.disputes, (item) => item.toJson()),
    'awardedBadgeIds': data.awardedBadgeIds.toList(),
    'blockedMemberIds': data.blockedMemberIds.toList(),
  };

  static SeedData decode(Map<String, dynamic> json) => SeedData(
    currentUser: User.fromJson(_map(json['currentUser'])),
    settings: AppSettings.fromJson(_map(json['settings'])),
    members: _decodeAll(json['members'], User.fromJson),
    listings: _decodeAll(json['listings'], SkillListing.fromJson),
    messages: _decodeAll(json['messages'], Message.fromJson),
    proposals: _decodeAll(json['proposals'], TradeProposal.fromJson),
    trades: _decodeAll(json['trades'], Trade.fromJson),
    sessions: _decodeAll(json['sessions'], TradeSession.fromJson),
    groupTrades: _decodeAll(json['groupTrades'], GroupTrade.fromJson),
    notifications: _decodeAll(json['notifications'], AppNotification.fromJson),
    transactions: _decodeAll(json['transactions'], WalletTransaction.fromJson),
    reviews: _decodeAll(json['reviews'], Review.fromJson),
    disputes: _decodeAll(json['disputes'], DisputeCase.fromJson),
    awardedBadgeIds: Set<String>.from(json['awardedBadgeIds'] as List),
    blockedMemberIds: Set<String>.from(json['blockedMemberIds'] as List),
  );

  static Map<String, dynamic> _map(Object? value) =>
      value! as Map<String, dynamic>;

  static List<Map<String, dynamic>> _encodeAll<T>(
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) => items.map(toJson).toList();

  static List<T> _decodeAll<T>(
    Object? items,
    T Function(Map<String, dynamic> json) fromJson,
  ) => (items! as List).map((item) => fromJson(_map(item))).toList();
}
