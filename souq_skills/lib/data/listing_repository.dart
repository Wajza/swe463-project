import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';

/// A listing problem explained in words the member can act on.
class ListingException implements Exception {
  const ListingException(this.message);

  final String message;

  /// The listing was deleted, or never existed.
  static const notFound = ListingException('This listing no longer exists.');

  /// The listing belongs to another member.
  static const notYours = ListingException(
    'You can only change your own listings.',
  );

  @override
  String toString() => message;
}

/// Skill listings shared by all members, kept at `listings/{listingId}`.
///
/// Stored listings name their owner by Firebase uid. The app calls the
/// current member [User.currentUserId], so the caller's own uid is shown as
/// that id, and turned back into the uid when saving; other owners' uids
/// are left as they are.
///
/// Whether a listing is saved belongs to each member, not to the shared
/// listing, so `isSaved` is never stored here and always reads as false.
abstract class ListingRepository {
  /// Every listing, as seen by [uid] (null when signed out).
  /// Throws a [ListingException] if they cannot be read.
  Future<List<SkillListing>> fetchListings({String? uid});

  /// The listing [id], as seen by [uid], or null if it does not exist.
  Future<SkillListing?> fetchListing(String id, {String? uid});

  /// Publishes [draft] as a new listing owned by [uid], and returns it with
  /// its new id. The draft's own id and `isSaved` are ignored.
  Future<SkillListing> createListing(String uid, SkillListing draft);

  /// Saves the changes to [listing], which must belong to [uid]. Keeps
  /// fields this app does not know about. Throws [ListingException.notFound]
  /// or [ListingException.notYours], changing nothing.
  Future<void> updateListing(String uid, SkillListing listing);

  /// Deletes the listing [id], which must belong to [uid]. Throws
  /// [ListingException.notFound] or [ListingException.notYours].
  Future<void> deleteListing(String uid, String id);

  /// Deletes every listing owned by [uid], and no one else's, as when the
  /// account is deleted. Safe to run again: whatever an interrupted run
  /// left behind is deleted next time. Throws a [ListingException].
  Future<void> deleteAllListingsOf(String uid);
}

/// Converts between [SkillListing] and the data stored in `listings/{id}`.
abstract final class ListingDocument {
  /// The fields to store for [listing], published by [uid].
  ///
  /// The id is the document's own id and is not repeated in its data;
  /// `isSaved` is never stored. Throws [ListingException.notYours] if the
  /// listing names another owner.
  static Map<String, dynamic> toData(String uid, SkillListing listing) {
    final owner = listing.ownerId;
    if (owner != User.currentUserId && owner != uid) {
      throw ListingException.notYours;
    }
    return {...listing.toJson(), 'ownerId': uid}
      ..remove('id')
      ..remove('isSaved');
  }

  /// Reads stored [data] for listing [id] as seen by [viewerUid].
  ///
  /// Missing or wrongly typed fields get the same defaults as a new
  /// [SkillListing], so older or hand-edited records still open; extra
  /// fields such as `createdAt` and an old `isSaved` are ignored.
  static SkillListing fromData(
    String id,
    Map<String, dynamic> data, {
    String? viewerUid,
  }) {
    const defaults = SkillListing(ownerId: '', category: '');
    final owner = _text(data['ownerId'], '');
    return SkillListing(
      id: id,
      ownerId: viewerUid != null && owner == viewerUid
          ? User.currentUserId
          : owner,
      category: _text(data['category'], defaults.category),
      title: _text(data['title'], defaults.title),
      offers: _text(data['offers'], defaults.offers),
      wants: _text(data['wants'], defaults.wants),
      distance: _text(data['distance'], defaults.distance),
      description: _text(data['description'], defaults.description),
      city: _text(data['city'], defaults.city),
      availability: _text(data['availability'], defaults.availability),
      sessionsMinutes: data['sessionsMinutes'] is num
          ? (data['sessionsMinutes'] as num).toInt()
          : defaults.sessionsMinutes,
      onlineOnly: _flag(data['onlineOnly'], defaults.onlineOnly),
      womenOnly: _flag(data['womenOnly'], defaults.womenOnly),
      isPaused: _flag(data['isPaused'], defaults.isPaused),
    );
  }

  /// Whether stored [data] belongs to [uid].
  static bool isOwnedBy(Map<String, dynamic> data, String uid) =>
      data['ownerId'] == uid;

  static String _text(Object? value, String fallback) =>
      value is String ? value : fallback;

  static bool _flag(Object? value, bool fallback) =>
      value is bool ? value : fallback;
}

/// Listings in Cloud Firestore.
class FirebaseListingRepository implements ListingRepository {
  FirebaseListingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  @override
  Future<List<SkillListing>> fetchListings({String? uid}) => _guard(() async {
    final snapshot = await _listings.get();
    return [
      for (final doc in snapshot.docs)
        ListingDocument.fromData(doc.id, doc.data(), viewerUid: uid),
    ];
  });

  @override
  Future<SkillListing?> fetchListing(String id, {String? uid}) =>
      _guard(() async {
        final data = (await _listings.doc(id).get()).data();
        return data == null
            ? null
            : ListingDocument.fromData(id, data, viewerUid: uid);
      });

  @override
  Future<SkillListing> createListing(String uid, SkillListing draft) =>
      _guard(() async {
        final data = ListingDocument.toData(uid, draft);
        final ref = _listings.doc();
        await ref.set({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return ListingDocument.fromData(ref.id, data, viewerUid: uid);
      });

  /// Checked and written in one transaction, so the owner cannot change in
  /// between.
  @override
  Future<void> updateListing(String uid, SkillListing listing) =>
      _guard(() async {
        final data = ListingDocument.toData(uid, listing);
        final ref = _listings.doc(listing.id);
        final problem = await _firestore.runTransaction<ListingException?>((
          transaction,
        ) async {
          final problem = _ownershipProblem(await transaction.get(ref), uid);
          if (problem != null) return problem;
          // Merging keeps `createdAt` and fields this app does not know.
          transaction.set(ref, {
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return null;
        });
        if (problem != null) throw problem;
      });

  @override
  Future<void> deleteListing(String uid, String id) => _guard(() async {
    final ref = _listings.doc(id);
    final problem = await _firestore.runTransaction<ListingException?>((
      transaction,
    ) async {
      final problem = _ownershipProblem(await transaction.get(ref), uid);
      if (problem == null) transaction.delete(ref);
      return problem;
    });
    if (problem != null) throw problem;
  });

  /// How many listings are deleted per batch: below Firestore's limit of
  /// 500 writes in one batch.
  static const deleteBatchSize = 400;

  /// Deletes the owner's listings a batch at a time, looking them up again
  /// each time, until none are left. Each batch either fully succeeds or
  /// changes nothing, so a failure part-way leaves only whole listings,
  /// which the next run finds and deletes.
  @override
  Future<void> deleteAllListingsOf(String uid) => _guard(() async {
    while (true) {
      final page = await _listings
          .where('ownerId', isEqualTo: uid)
          .limit(deleteBatchSize)
          .get();
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  });

  /// Returned rather than thrown inside transactions, so it reads the same
  /// on every platform; nothing has been written when it is not null.
  static ListingException? _ownershipProblem(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String uid,
  ) {
    final data = snapshot.data();
    if (data == null) return ListingException.notFound;
    if (!ListingDocument.isOwnedBy(data, uid)) return ListingException.notYours;
    return null;
  }

  /// Runs [action], turning Firestore errors into [ListingException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ListingException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ListingException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'You do not have access to this listing.',
        'not-found' => ListingException.notFound.message,
        _ => 'We could not reach the listings. Try again.',
      });
    } catch (_) {
      throw const ListingException(
        'We could not reach the listings. Try again.',
      );
    }
  }
}

/// Keeps listings in memory, with the same rules as Firestore. Used when
/// Firebase has not been set up, such as in tests.
class DemoListingRepository implements ListingRepository {
  /// [documents] are stored data by listing id, as Firestore would hold it
  /// (owners named by uid), e.g. to stand in for older records.
  DemoListingRepository({Map<String, Map<String, dynamic>>? documents})
    : _data = {
        for (final MapEntry(:key, :value) in (documents ?? {}).entries)
          key: {...value},
      };

  // Stored as data so it behaves like Firestore: a saved listing is a copy.
  final Map<String, Map<String, dynamic>> _data;
  int _nextId = 0;

  /// A copy of what is stored for listing [id], or null if there is none.
  Map<String, dynamic>? storedData(String id) {
    final data = _data[id];
    return data == null ? null : {...data};
  }

  @override
  Future<List<SkillListing>> fetchListings({String? uid}) async => [
    for (final MapEntry(:key, :value) in _data.entries)
      ListingDocument.fromData(key, value, viewerUid: uid),
  ];

  @override
  Future<SkillListing?> fetchListing(String id, {String? uid}) async {
    final data = _data[id];
    return data == null
        ? null
        : ListingDocument.fromData(id, data, viewerUid: uid);
  }

  @override
  Future<SkillListing> createListing(String uid, SkillListing draft) async {
    final data = ListingDocument.toData(uid, draft);
    String id;
    do {
      id = 'listing-${++_nextId}';
    } while (_data.containsKey(id));
    _data[id] = data;
    return ListingDocument.fromData(id, data, viewerUid: uid);
  }

  @override
  Future<void> updateListing(String uid, SkillListing listing) async {
    final data = ListingDocument.toData(uid, listing);
    final stored = _ownedData(uid, listing.id);
    _data[listing.id] = {...stored, ...data};
  }

  @override
  Future<void> deleteListing(String uid, String id) async {
    _ownedData(uid, id);
    _data.remove(id);
  }

  @override
  Future<void> deleteAllListingsOf(String uid) async =>
      _data.removeWhere((_, data) => ListingDocument.isOwnedBy(data, uid));

  Map<String, dynamic> _ownedData(String uid, String id) {
    final stored = _data[id];
    if (stored == null) throw ListingException.notFound;
    if (!ListingDocument.isOwnedBy(stored, uid)) {
      throw ListingException.notYours;
    }
    return stored;
  }
}
