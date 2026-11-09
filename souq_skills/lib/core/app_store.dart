import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../models/notification.dart';
import '../models/skill_listing.dart';
import '../models/trade.dart';
import '../models/user.dart';
import '../models/app_settings.dart';
import '../models/badge.dart';
import '../models/dispute_case.dart';
import '../models/group_trade.dart';
import '../models/review.dart';
import '../models/saved_search.dart';
import '../models/search_alert.dart';
import '../models/trade_session.dart';
import '../models/transaction.dart';
import '../services/repository.dart';

class AppStore extends ChangeNotifier {
  AppStore._() {
    _repository.addListener(notifyListeners);
  }

  static final AppStore instance = AppStore._();
  final Repository _repository = Repository.instance;

  User get currentUser => _repository.currentUser;
  bool get isSignedIn => _repository.currentUser.isVerified;
  bool isLoading = false;
  String? errorMessage;
  bool balanceVisible = true;

  Repository get repository => _repository;
  int get credits => _repository.balance;
  bool get balanceIsVisible => balanceVisible;
  List<SkillListing> get listings => List.unmodifiable(_repository.listings);
  List<Message> get messages => List.unmodifiable(_repository.messages);
  List<Trade> get trades => List.unmodifiable(_repository.trades);
  Set<String> get savedListingIds => _repository.listings
      .where((listing) => listing.isSaved)
      .map((listing) => listing.id)
      .toSet();
  List<AppNotification> get notifications =>
      List.unmodifiable(_repository.notifications);
  List<GroupTrade> get groupTrades => List.unmodifiable(_repository.groupTrades);
  List<TradeSession> get sessions => List.unmodifiable(_repository.sessions);
  List<WalletTransaction> get transactions =>
      List.unmodifiable(_repository.transactions);
  List<Review> get reviews => List.unmodifiable(_repository.reviews);
  List<Badge> get badges => List.unmodifiable(_repository.badges);
  List<SavedSearch> get savedSearches =>
      List.unmodifiable(_repository.savedSearches);
  List<SearchAlert> get searchAlerts =>
      List.unmodifiable(_repository.searchAlerts);
  List<DisputeCase> get disputes => List.unmodifiable(_repository.disputes);
  AppSettings get settings => _repository.settings;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void refresh() => notifyListeners();

  void signIn() => _repository.updateUser(
        User(
          name: currentUser.name,
          initials: currentUser.initials,
          username: currentUser.username,
          city: currentUser.city,
          bio: currentUser.bio,
          phone: currentUser.phone,
          isVerified: true,
          skillsOffered: currentUser.skillsOffered,
          skillsWanted: currentUser.skillsWanted,
          availability: currentUser.availability,
        ),
      );

  void signOut() => _repository.updateUser(const User(name: '', initials: ''));

  void updateUser(User user) => _repository.updateUser(user);

  void toggleBalance() {
    balanceVisible = !balanceVisible;
    notifyListeners();
  }

  void toggleSavedListing(String listingId) {
    final index = _repository.listings.indexWhere((item) => item.id == listingId);
    if (index < 0) return;
    final item = _repository.listings[index];
    _repository.listings[index] = item.copyWith(isSaved: !item.isSaved);
    _repository.emitChange();
  }
}
