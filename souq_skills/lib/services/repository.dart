import 'package:flutter/foundation.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/identifiable.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/models/search_alert.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/models/user.dart';

import 'seed_data.dart';

/// In-memory data store. Holds state and publishes changes; business rules
/// live in the services.
class Repository extends ChangeNotifier {
  Repository._() {
    reset();
  }

  static final Repository instance = Repository._();

  late User currentUser;
  AppSettings settings = const AppSettings();
  bool hasAccount = true;
  bool isSignedIn = false;

  final List<User> members = [];
  final List<SkillListing> listings = [];
  final List<Message> messages = [];
  final List<TradeProposal> proposals = [];
  final List<Trade> trades = [];
  final List<TradeSession> sessions = [];
  final List<GroupTrade> groupTrades = [];
  final List<AppNotification> notifications = [];
  final List<WalletTransaction> transactions = [];
  final List<Review> reviews = [];
  final List<SavedSearch> savedSearches = [];
  final List<SearchAlert> searchAlerts = [];
  final List<DisputeCase> disputes = [];
  final Set<String> blockedMemberIds = {};
  final Set<String> awardedBadgeIds = {};
  int _nextId = 0;

  /// Restores the demo account that "Sign in" uses.
  void reset() {
    hasAccount = true;
    isSignedIn = false;
    load(SeedData.demo());
  }

  void load(SeedData seed) {
    currentUser = seed.currentUser;
    settings = const AppSettings();
    _replaceAll(members, seed.members);
    _replaceAll(listings, seed.listings);
    _replaceAll(messages, seed.messages);
    _replaceAll(proposals, seed.proposals);
    _replaceAll(trades, seed.trades);
    _replaceAll(sessions, seed.sessions);
    _replaceAll(groupTrades, seed.groupTrades);
    _replaceAll(notifications, seed.notifications);
    _replaceAll(transactions, seed.transactions);
    _replaceAll(reviews, seed.reviews);
    _replaceAll(savedSearches, seed.savedSearches);
    _replaceAll(searchAlerts, seed.searchAlerts);
    _replaceAll(disputes, seed.disputes);
    blockedMemberIds.clear();
    awardedBadgeIds
      ..clear()
      ..addAll(seed.awardedBadgeIds);
    notifyListeners();
  }

  String nextId(String prefix) => '$prefix-${++_nextId}';

  T? find<T extends Identifiable>(List<T> items, String? id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void insert<T>(List<T> items, T item) {
    items.add(item);
    notifyListeners();
  }

  void update<T extends Identifiable>(
    List<T> items,
    String id,
    T Function(T current) change,
  ) {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    items[index] = change(items[index]);
    notifyListeners();
  }

  void remove<T extends Identifiable>(List<T> items, String id) {
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateUser(User user) {
    currentUser = user;
    notifyListeners();
  }

  void updateSettings(AppSettings value) {
    settings = value;
    notifyListeners();
  }

  /// Publishes a change made directly to one of the repository's collections.
  void emitChange() => notifyListeners();

  void _replaceAll<T>(List<T> target, List<T> values) => target
    ..clear()
    ..addAll(values);
}
