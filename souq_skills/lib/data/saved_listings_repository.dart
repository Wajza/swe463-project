import 'package:cloud_firestore/cloud_firestore.dart';

import 'listing_repository.dart';

/// Which listings each member saved, kept at `users/{uid}/saved/{listingId}`
/// as `{ listingId, savedAt }`.
///
/// Saving belongs to the member, not to the shared listing, so every
/// account has its own saved listings and nothing is written to
/// `listings/{listingId}`. Problems are reported as [ListingException]s.
abstract class SavedListingsRepository {
  /// The ids of the listings [uid] saved.
  Future<Set<String>> fetchSavedIds(String uid);

  /// Saves [listingId] for [uid]. Saving it again changes nothing.
  Future<void> save(String uid, String listingId);

  /// Removes [listingId] from [uid]'s saved listings, if it is there.
  Future<void> unsave(String uid, String listingId);

  /// Removes all of [uid]'s saved listings, and no one else's, as when the
  /// account is deleted. Safe to run again after an interrupted run.
  Future<void> unsaveAll(String uid);
}

/// Saved listings in Cloud Firestore.
class FirebaseSavedListingsRepository implements SavedListingsRepository {
  FirebaseSavedListingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _savedOf(String uid) =>
      _firestore.collection('users').doc(uid).collection('saved');

  @override
  Future<Set<String>> fetchSavedIds(String uid) => _guard(() async {
    final snapshot = await _savedOf(uid).get();
    return {for (final doc in snapshot.docs) doc.id};
  });

  @override
  Future<void> save(String uid, String listingId) => _guard(
    () => _savedOf(uid)
        .doc(listingId)
        .set({'listingId': listingId, 'savedAt': FieldValue.serverTimestamp()}),
  );

  @override
  Future<void> unsave(String uid, String listingId) =>
      _guard(() => _savedOf(uid).doc(listingId).delete());

  /// How many saved listings are removed per batch: below Firestore's
  /// limit of 500 writes in one batch.
  static const deleteBatchSize = 400;

  /// Removes them a batch at a time, looking them up again each time, until
  /// none are left; a failure part-way is finished by the next run.
  @override
  Future<void> unsaveAll(String uid) => _guard(() async {
    while (true) {
      final page = await _savedOf(uid).limit(deleteBatchSize).get();
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  });

  /// Runs [action], turning Firestore errors into [ListingException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw ListingException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your saved skills could not be opened.',
        _ => 'We could not update your saved skills. Try again.',
      });
    } catch (_) {
      throw const ListingException(
        'We could not update your saved skills. Try again.',
      );
    }
  }
}

/// Keeps each account's saved listings in memory. Used when Firebase has
/// not been set up, such as in tests.
class DemoSavedListingsRepository implements SavedListingsRepository {
  /// [saved] maps uids to the listing ids they saved.
  DemoSavedListingsRepository({Map<String, Set<String>>? saved})
    : _saved = {
        for (final MapEntry(:key, :value) in (saved ?? {}).entries)
          key: {...value},
      };

  final Map<String, Set<String>> _saved;

  @override
  Future<Set<String>> fetchSavedIds(String uid) async => {...?_saved[uid]};

  @override
  Future<void> save(String uid, String listingId) async =>
      (_saved[uid] ??= {}).add(listingId);

  @override
  Future<void> unsave(String uid, String listingId) async =>
      _saved[uid]?.remove(listingId);

  @override
  Future<void> unsaveAll(String uid) async => _saved.remove(uid);
}
