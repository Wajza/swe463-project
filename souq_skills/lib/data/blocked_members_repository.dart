import 'package:cloud_firestore/cloud_firestore.dart';

/// A blocking problem explained in words the member can act on.
class BlockingException implements Exception {
  const BlockingException(this.message);

  final String message;

  static const cannotBlockYourself = BlockingException(
    'You cannot block yourself.',
  );

  @override
  String toString() => message;
}

/// Who each member blocked, kept at `users/{uid}/blocked/{blockedUid}` as
/// `{ blockedUid, blockedAt }`. Private to the member who blocked; the
/// blocked member is never told. Accounts are named by Firebase uid only.
abstract class BlockedMembersRepository {
  /// The uids [uid] has blocked. Throws a [BlockingException].
  Future<Set<String>> fetchBlockedIds(String uid);

  /// Blocks [blockedUid] for [uid]. Blocking again changes nothing.
  /// Throws [BlockingException.cannotBlockYourself] for [uid] itself.
  Future<void> block(String uid, String blockedUid);

  /// Unblocks [blockedUid] for [uid], if blocked.
  Future<void> unblock(String uid, String blockedUid);

  /// Removes every block [uid] made, and no one else's, as when the
  /// account is deleted. Safe to run again after an interrupted run.
  Future<void> unblockAll(String uid);
}

/// Blocked members in Cloud Firestore.
class FirebaseBlockedMembersRepository implements BlockedMembersRepository {
  FirebaseBlockedMembersRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// How many blocks are removed per batch: below Firestore's limit of
  /// 500 writes in one batch.
  static const deleteBatchSize = 400;

  CollectionReference<Map<String, dynamic>> _blockedOf(String uid) =>
      _firestore.collection('users').doc(uid).collection('blocked');

  @override
  Future<Set<String>> fetchBlockedIds(String uid) => _guard(() async {
    final snapshot = await _blockedOf(uid).get();
    return {for (final doc in snapshot.docs) doc.id};
  });

  @override
  Future<void> block(String uid, String blockedUid) async {
    if (blockedUid == uid) throw BlockingException.cannotBlockYourself;
    await _guard(
      () => _blockedOf(uid).doc(blockedUid).set({
        'blockedUid': blockedUid,
        'blockedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> unblock(String uid, String blockedUid) =>
      _guard(() => _blockedOf(uid).doc(blockedUid).delete());

  /// A batch at a time, looking them up again each time, until none are
  /// left; a failure part-way is finished by the next run.
  @override
  Future<void> unblockAll(String uid) => _guard(() async {
    while (true) {
      final page = await _blockedOf(uid).limit(deleteBatchSize).get();
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  });

  /// Runs [action], turning Firestore errors into [BlockingException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on BlockingException {
      rethrow;
    } on FirebaseException catch (error) {
      throw BlockingException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your blocked members could not be updated.',
        _ => 'We could not update your blocked members. Try again.',
      });
    } catch (_) {
      throw const BlockingException(
        'We could not update your blocked members. Try again.',
      );
    }
  }
}

/// Keeps each account's blocked members in memory. Used when Firebase has
/// not been set up, such as in tests.
class DemoBlockedMembersRepository implements BlockedMembersRepository {
  /// [blocked] maps uids to the uids they blocked.
  DemoBlockedMembersRepository({Map<String, Set<String>>? blocked})
    : _blocked = {
        for (final MapEntry(:key, :value) in (blocked ?? {}).entries)
          key: {...value},
      };

  final Map<String, Set<String>> _blocked;

  @override
  Future<Set<String>> fetchBlockedIds(String uid) async => {...?_blocked[uid]};

  @override
  Future<void> block(String uid, String blockedUid) async {
    if (blockedUid == uid) throw BlockingException.cannotBlockYourself;
    (_blocked[uid] ??= {}).add(blockedUid);
  }

  @override
  Future<void> unblock(String uid, String blockedUid) async =>
      _blocked[uid]?.remove(blockedUid);

  @override
  Future<void> unblockAll(String uid) async => _blocked.remove(uid);
}
