import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/badge.dart';
import '../models/dispute_case.dart';
import '../models/group_trade.dart';
import '../models/message.dart';
import '../models/notification.dart';
import '../models/review.dart';
import '../models/saved_search.dart';
import '../models/search_alert.dart';
import '../models/skill_listing.dart';
import '../models/trade.dart';
import '../models/trade_session.dart';
import '../models/transaction.dart';
import '../models/user.dart';

class Repository extends ChangeNotifier {
  Repository._();
  static final Repository instance = Repository._();
  User currentUser = const User(name: 'Yara Alghamdi', initials: 'YA', username: 'yara', city: 'Riyadh', isVerified: true);
  AppSettings settings = const AppSettings();
  final List<SkillListing> listings = [];
  final List<Message> messages = [];
  final List<Trade> trades = [];
  final List<TradeSession> sessions = [];
  final List<GroupTrade> groupTrades = [];
  final List<AppNotification> notifications = [];
  final List<WalletTransaction> transactions = [];
  final List<Review> reviews = [];
  final List<Badge> badges = [];
  final List<SavedSearch> savedSearches = [];
  final List<SearchAlert> searchAlerts = [];
  final List<DisputeCase> disputes = [];
  final Set<String> blockedMemberIds = {};
  int get balance => transactions.fold(120, (sum, item) => sum + item.amount);

  void updateUser(User user) {
    currentUser = user;
    notifyListeners();
  }

  void updateSettings(AppSettings value) {
    settings = value;
    notifyListeners();
  }

  /// Publishes a change after a service mutates one of the repository lists.
  void emitChange() => notifyListeners();
}
