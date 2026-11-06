import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class ProfileProvider extends ChangeNotifier {

  bool _tradeMessagesEnabled = true;
  bool _tradeUpdatesEnabled = true;
  bool _matchingListingsEnabled = false;

  bool get tradeMessagesEnabled => _tradeMessagesEnabled;
  bool get tradeUpdatesEnabled => _tradeUpdatesEnabled;
  bool get matchingListingsEnabled => _matchingListingsEnabled;

  void updateNotificationPreferences({
    bool? tradeMessages,
    bool? tradeUpdates,
    bool? matchingListings,
  }) {
    final nextMessages = tradeMessages ?? _tradeMessagesEnabled;
    final nextUpdates = tradeUpdates ?? _tradeUpdatesEnabled;
    final nextMatches = matchingListings ?? _matchingListingsEnabled;

    if (nextMessages == _tradeMessagesEnabled &&
        nextUpdates == _tradeUpdatesEnabled &&
        nextMatches == _matchingListingsEnabled) {
      return;
    }

    _tradeMessagesEnabled = nextMessages;
    _tradeUpdatesEnabled = nextUpdates;
    _matchingListingsEnabled = nextMatches;
    notifyListeners();
  }


  // Temporary sample profile; persistence will be connected separately.
  UserProfile _profile = const UserProfile(
    id: 'demo-raghad',
    shownName: 'Raghad Almaghrabi',
    username: 'raghad',
    city: 'Riyadh',
    bio: 'Excel specialist helping local founders get organized. '
        'Learning pottery one trade at a time.',
    phoneVerified: true,
  );

  UserProfile get profile => _profile;

  void updateProfile({
    required String shownName,
    required String username,
    required String city,
    required String bio,
  }) {
    final cleanName = shownName.trim();
    final cleanUsername = username
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase();

    if (cleanName.isEmpty) {
      throw ArgumentError('Please enter your shown name.');
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw ArgumentError(
        'Use 3–20 letters, numbers, or underscores for your username.',
      );
    }

    if (city.trim().isEmpty) {
      throw ArgumentError('Please choose your city.');
    }

    _profile = _profile.copyWith(
      shownName: cleanName,
      username: cleanUsername,
      city: city.trim(),
      bio: bio.trim(),
    );

    notifyListeners();
  }

  void setHideLocation(bool value) {
    if (_profile.hideLocation == value) return;
    _profile = _profile.copyWith(hideLocation: value);
    notifyListeners();
  }
}
