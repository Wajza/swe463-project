import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';
import 'package:souq_skills/models/search_criteria.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'badge_service.dart';
import 'member_service.dart';
import 'repository.dart';
import 'review_service.dart';
import 'safety_service.dart';

export 'package:souq_skills/data/listing_repository.dart' show ListingException;

enum ListingLoadStatus { notLoaded, loading, loaded, failed }

/// How far loading the shared listings has got.
class ListingLoadState {
  const ListingLoadState(this.status, [this.error]);

  final ListingLoadStatus status;

  /// What went wrong, when [status] is [ListingLoadStatus.failed].
  final String? error;

  bool get isFailed => status == ListingLoadStatus.failed;
}

class ListingService {
  final Repository _repo = Repository.instance;

  static ListingRepository? _listings;

  /// Where listings are shared online: Firestore once Firebase has been
  /// initialized. Null in the offline demo, which keeps listings on this
  /// device only. Can be replaced, e.g. with a fake.
  static ListingRepository? get repository =>
      _listings ??
      (Firebase.apps.isEmpty ? null : _listings = FirebaseListingRepository());
  static set repository(ListingRepository? value) {
    _listings = value;
    _forgetLoaded();
  }

  static SavedListingsRepository? _saved;

  /// Where each member's saved listings are kept online, alongside
  /// [repository]. Null in the offline demo, where the saved hearts stay on
  /// this device. Can be replaced, e.g. with a fake.
  static SavedListingsRepository? get savedRepository =>
      _saved ??
      (Firebase.apps.isEmpty
          ? null
          : _saved = FirebaseSavedListingsRepository());
  static set savedRepository(SavedListingsRepository? value) {
    _saved = value;
    _forgetLoaded();
  }

  /// Listings and saved hearts from another source no longer count as
  /// loaded.
  static void _forgetLoaded() {
    _loadedFor = null;
    _refreshing = null;
    loadState.value = const ListingLoadState(ListingLoadStatus.notLoaded);
  }

  /// Listings whose saved heart is being changed online right now. Their
  /// heart ignores taps until that has finished.
  static final ValueNotifier<Set<String>> savingIds = ValueNotifier(const {});

  /// Progress of [refresh], for screens to show loading and errors.
  static final ValueNotifier<ListingLoadState> loadState = ValueNotifier(
    const ListingLoadState(ListingLoadStatus.notLoaded),
  );

  /// The account the listings on this device were last loaded for.
  static String? _loadedFor;
  static Future<void>? _refreshing;
  static String? _refreshingFor;

  /// Whether listings are shared online rather than kept on this device.
  bool get isOnline => repository != null;

  /// Whether the listings on this device can be shown: always offline, and
  /// online once they have been loaded for the signed-in account. Until
  /// then they may be sample data or another account's.
  bool get hasCurrentListings =>
      !isOnline ||
      (_loadedFor != null && _loadedFor == AuthService.repository.uid);

  /// Replaces the listings on this device with the shared ones, as seen by
  /// the signed-in member. Does nothing offline. Never throws: the outcome
  /// is in [loadState]. A refresh already running for the same account is
  /// shared rather than repeated.
  Future<void> refresh() {
    final repository = ListingService.repository;
    if (repository == null) return Future.value();
    final uid = AuthService.repository.uid;
    if (_refreshing != null && _refreshingFor == uid) return _refreshing!;
    _refreshingFor = uid;
    final refreshing = _refresh(repository, uid);
    _refreshing = refreshing;
    return refreshing.whenComplete(() {
      if (identical(_refreshing, refreshing)) _refreshing = null;
    });
  }

  Future<void> _refresh(ListingRepository repository, String? uid) async {
    loadState.value = const ListingLoadState(ListingLoadStatus.loading);
    // Nothing is applied once the account or source has changed meanwhile,
    // so one account never ends up with another's listings.
    bool isCurrent() =>
        uid == AuthService.repository.uid &&
        identical(repository, ListingService.repository);
    final saved = savedRepository;
    final blocked = SafetyService.repository;
    try {
      // The hearts and the blocks decide what is shown, so all three load
      // together or none is applied: listings are never shown before the
      // block list, which would show members who were blocked.
      final (fetched, savedIds, blockedIds) = await (
        repository.fetchListings(uid: uid),
        saved == null || uid == null
            ? Future<Set<String>?>.value()
            : saved.fetchSavedIds(uid),
        blocked == null || uid == null
            ? Future<Set<String>?>.value()
            : blocked.fetchBlockedIds(uid),
      ).wait;
      if (!isCurrent()) return;
      if (blockedIds != null) SafetyService().replaceOnlineBlocks(blockedIds);
      _replaceListings(fetched, savedIds);
      _loadedFor = uid;
      loadState.value = const ListingLoadState(ListingLoadStatus.loaded);
      if (saved != null && uid != null && savedIds != null) {
        _forgetDeletedSaves(saved, uid, savedIds, fetched);
      }
      // Owners' and blocked members' names are filled in afterwards:
      // browsing never waits for them, and known members are not fetched
      // again.
      MemberService().loadMembers({
        for (final item in fetched) item.ownerId,
        ...?blockedIds,
      }).ignore();
      // Ratings on the cards and the member's own, likewise in the
      // background, once per account; private ones stay hidden.
      ReviewService().refreshReviews({
        User.currentUserId,
        for (final item in fetched) item.ownerId,
      }).ignore();
    } on ParallelWaitError<
      (List<SkillListing>?, Set<String>?, Set<String>?),
      dynamic
    > catch (error) {
      if (!isCurrent()) return;
      final (listingsError, savedError, blockedError) = error.errors;
      final problem =
          listingsError?.error ?? savedError?.error ?? blockedError?.error;
      loadState.value = ListingLoadState(
        ListingLoadStatus.failed,
        switch (problem) {
          ListingException(:final message) => message,
          BlockingException(:final message) => message,
          _ => 'We could not reach the listings. Try again.',
        },
      );
    } on ListingException catch (error) {
      if (!isCurrent()) return;
      loadState.value = ListingLoadState(
        ListingLoadStatus.failed,
        error.message,
      );
    }
  }

  /// The shared listings replace everything on this device, so nothing is
  /// listed twice and deleted or sample listings disappear. Their hearts
  /// show exactly the signed-in member's [savedIds], so no other account's
  /// show. Without saved listings online, the device's hearts carry over.
  void _replaceListings(List<SkillListing> fetched, Set<String>? savedIds) {
    final saved =
        savedIds ??
        {
          for (final item in _repo.listings)
            if (item.isSaved) item.id,
        };
    _repo.listings
      ..clear()
      ..addAll([
        for (final item in fetched)
          item.copyWith(isSaved: saved.contains(item.id)),
      ]);
    _repo.emitChange();
  }

  /// Saved listings that no longer exist are removed from [uid]'s saved
  /// listings, quietly: if it fails, the next refresh tries again.
  void _forgetDeletedSaves(
    SavedListingsRepository saved,
    String uid,
    Set<String> savedIds,
    List<SkillListing> listings,
  ) {
    final existing = {for (final item in listings) item.id};
    for (final id in savedIds.difference(existing)) {
      saved.unsave(uid, id).ignore();
    }
  }

  /// Active listings from other, unblocked members that match [criteria].
  List<SkillListing> discover(SearchCriteria criteria) {
    final query = criteria.query.trim().toLowerCase();
    return _repo.listings.where((item) {
      final text = '${item.title} ${item.offers} ${item.wants}'.toLowerCase();
      return item.ownerId != User.currentUserId &&
          !item.isPaused &&
          !_repo.blockedMemberIds.contains(item.ownerId) &&
          (query.isEmpty || text.contains(query)) &&
          (criteria.category == null || item.category == criteria.category) &&
          (criteria.city == null || item.city == criteria.city) &&
          (!criteria.onlineOnly || item.onlineOnly) &&
          (!criteria.womenOnly || item.womenOnly);
    }).toList();
  }

  SkillListing? byId(String id) => _repo.find(_repo.listings, id);

  List<SkillListing> byOwner(String ownerId) =>
      _repo.listings.where((item) => item.ownerId == ownerId).toList();

  List<SkillListing> activeByOwner(String ownerId) =>
      byOwner(ownerId).where((item) => !item.isPaused).toList();

  List<SkillListing> mine() => byOwner(User.currentUserId);

  /// Saved listings, leaving out blocked members' (they stay saved, and
  /// come back if the member is unblocked).
  List<SkillListing> saved() => _repo.listings
      .where(
        (item) =>
            item.isSaved && !_repo.blockedMemberIds.contains(item.ownerId),
      )
      .toList();

  /// The location to show, hiding the current user's city if they chose to.
  String locationLabel(SkillListing listing) =>
      isMine(listing) && !_repo.settings.locationVisible
      ? 'Location private'
      : listing.city;

  bool isMine(SkillListing listing) => listing.ownerId == User.currentUserId;

  // Creating, changing and deleting a listing save it online first, and
  // only then on this device, so the device never shows a change that was
  // not saved. They throw a [ListingException] and change nothing on
  // failure, including for a listing that belongs to someone else.

  /// Publishes [draft] as the current member's listing and returns it.
  Future<SkillListing> create(SkillListing draft) async {
    final repository = ListingService.repository;
    final listing = repository == null
        ? draft.copyWith(id: _repo.nextId('l'))
        : await repository.createListing(_signedInUid(), draft);
    _repo.insert(_repo.listings, listing);
    BadgeService().sync();
    return listing;
  }

  /// Saves the changes to [listing], which must be the current member's.
  Future<void> update(SkillListing listing) async {
    _checkMine(listing);
    try {
      await repository?.updateListing(_signedInUid(), listing);
    } on ListingException catch (error) {
      // Deleted elsewhere: the device stops showing it.
      if (_isGone(error)) _repo.remove(_repo.listings, listing.id);
      rethrow;
    }
    _repo.update(_repo.listings, listing.id, (_) => listing);
  }

  /// Deletes the current member's listing [id].
  Future<void> delete(String id) async {
    final listing = byId(id);
    if (listing == null) throw ListingException.notFound;
    _checkMine(listing);
    try {
      await repository?.deleteListing(_signedInUid(), id);
    } on ListingException catch (error) {
      // Already deleted elsewhere, which is what was asked for.
      if (!_isGone(error)) rethrow;
    }
    _repo.remove(_repo.listings, id);
  }

  /// Before the signed-in account is deleted: deletes all its listings and
  /// its saved listings online, then here. Only this account's data is
  /// touched. Throws a [ListingException] if anything may remain, in which
  /// case the account must not be deleted yet; running it again finishes
  /// what an interrupted run started. Offline it does nothing, as before.
  Future<void> removeAccountData() async {
    final listings = repository;
    final saved = savedRepository;
    final blocked = SafetyService.repository;
    if (listings == null && saved == null && blocked == null) return;
    final uid = _signedInUid();
    await listings?.deleteAllListingsOf(uid);
    await saved?.unsaveAll(uid);
    // Only this account's own blocks; others' blocks are theirs.
    try {
      await SafetyService().removeAccountData();
    } on BlockingException catch (error) {
      throw ListingException(error.message);
    }
    final others = [
      for (final item in _repo.listings)
        if (!isMine(item)) item.copyWith(isSaved: false),
    ];
    _repo.listings
      ..clear()
      ..addAll(others);
    _repo.emitChange();
  }

  static bool _isGone(ListingException error) =>
      error.message == ListingException.notFound.message;

  /// Pauses or resumes the current member's listing [id].
  Future<void> setPaused(String id, bool paused) async {
    final listing = byId(id);
    if (listing == null) throw ListingException.notFound;
    await update(listing.copyWith(isPaused: paused));
  }

  void _checkMine(SkillListing listing) {
    if (!isMine(listing)) throw ListingException.notYours;
  }

  /// The uid the online listings are saved under. Only needed online.
  String _signedInUid() =>
      AuthService.repository.uid ??
      (throw const ListingException(
        'Your session has expired. Sign in again.',
      ));

  /// Whether [id]'s saved heart is being changed online right now.
  bool isSaving(String id) => savingIds.value.contains(id);

  /// Saves or unsaves listing [id] for the signed-in member.
  ///
  /// The heart changes at once. Online, the change is then saved to the
  /// member's own saved listings; if that fails the heart changes back and
  /// a [ListingException] is thrown. Taps while that is under way are
  /// ignored, so rapid taps never send changes out of order.
  Future<void> toggleSaved(String id) async {
    final listing = byId(id);
    if (listing == null || isSaving(id)) return;
    final saving = !listing.isSaved;
    _setSaved(id, saving);
    final saved = savedRepository;
    if (saved == null) return;
    final uid = AuthService.repository.uid;
    savingIds.value = {...savingIds.value, id};
    try {
      if (uid == null) {
        throw const ListingException(
          'Your session has expired. Sign in again.',
        );
      }
      await (saving ? saved.save(uid, id) : saved.unsave(uid, id));
    } on ListingException {
      // Only undone if still showing this account's hearts.
      if (uid == AuthService.repository.uid) _setSaved(id, !saving);
      rethrow;
    } finally {
      savingIds.value = {...savingIds.value}..remove(id);
    }
  }

  void _setSaved(String id, bool saved) =>
      _repo.update(_repo.listings, id, (item) => item.copyWith(isSaved: saved));
}
