import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/identifiable.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/models/user.dart';

import 'app_data_source.dart';
import 'seed_data.dart';
import 'snapshot_codec.dart';

/// The single owner of the app's state. It publishes every change and saves
/// it to the data source; business rules live in the services.
class Repository extends ChangeNotifier {
  Repository._() {
    reset();
  }

  static final Repository instance = Repository._();

  AppDataSource dataSource = LocalDataSource();

  /// True while the latest changes could not be saved.
  final ValueNotifier<bool> saveFailed = ValueNotifier(false);

  late User currentUser;
  AppSettings settings = const AppSettings();
  bool hasAccount = true;
  bool isSignedIn = false;
  bool isRestored = false;

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
  final List<DisputeCase> disputes = [];
  final Set<String> blockedMemberIds = {};
  final Set<String> awardedBadgeIds = {};
  int _nextId = 0;
  bool _saveQueued = false;

  /// Restores the demo account and forgets anything loaded earlier.
  void reset() {
    hasAccount = true;
    isSignedIn = false;
    isRestored = false;
    _nextId = 0;
    saveFailed.value = false;
    load(SeedData.demo());
  }

  void load(SeedData data) {
    currentUser = data.currentUser;
    settings = data.settings;
    _replaceAll(members, data.members);
    _replaceAll(listings, data.listings);
    _replaceAll(messages, data.messages);
    _replaceAll(proposals, data.proposals);
    _replaceAll(trades, data.trades);
    _replaceAll(sessions, data.sessions);
    _replaceAll(groupTrades, data.groupTrades);
    _replaceAll(notifications, data.notifications);
    _replaceAll(transactions, data.transactions);
    _replaceAll(reviews, data.reviews);
    _replaceAll(disputes, data.disputes);
    blockedMemberIds
      ..clear()
      ..addAll(data.blockedMemberIds);
    awardedBadgeIds
      ..clear()
      ..addAll(data.awardedBadgeIds);
    notifyListeners();
  }

  /// Loads saved data. Throws if the data source cannot be read, and falls
  /// back to the sample data if what was saved can no longer be understood.
  Future<void> restore() async {
    final saved = await dataSource.read();
    if (saved != null) _applySaved(saved);
    isRestored = true;
    notifyListeners();
  }

  /// Writes the current state now, recording whether that worked.
  Future<void> save() async {
    try {
      await dataSource.write(jsonEncode(_encode()));
      saveFailed.value = false;
    } catch (_) {
      saveFailed.value = true;
    }
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

  @override
  void notifyListeners() {
    super.notifyListeners();
    _queueSave();
  }

  void _queueSave() {
    if (!isRestored || _saveQueued) return;
    _saveQueued = true;
    scheduleMicrotask(() {
      _saveQueued = false;
      save();
    });
  }

  void _applySaved(String saved) {
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      if (json['version'] != SnapshotCodec.version) return;
      final data = SnapshotCodec.decode(json);
      final session = json['session'] as Map<String, dynamic>;
      hasAccount = session['hasAccount'] as bool;
      isSignedIn = session['isSignedIn'] as bool;
      _nextId = session['nextId'] as int;
      load(data);
    } on FormatException {
      return;
    } on TypeError {
      return;
    }
  }

  Map<String, dynamic> _encode() => {
    ...SnapshotCodec.encode(
      SeedData(
        currentUser: currentUser,
        settings: settings,
        members: members,
        listings: listings,
        messages: messages,
        proposals: proposals,
        trades: trades,
        sessions: sessions,
        groupTrades: groupTrades,
        notifications: notifications,
        transactions: transactions,
        reviews: reviews,
        disputes: disputes,
        awardedBadgeIds: awardedBadgeIds,
        blockedMemberIds: blockedMemberIds,
      ),
    ),
    'session': {
      'hasAccount': hasAccount,
      'isSignedIn': isSignedIn,
      'nextId': _nextId,
    },
  };

  void _replaceAll<T>(List<T> target, List<T> values) {
    final copy = values.toList();
    target
      ..clear()
      ..addAll(copy);
  }
}
