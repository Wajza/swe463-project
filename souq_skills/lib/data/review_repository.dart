import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/user.dart';

/// A rating problem explained in words the member can act on.
class ReviewException implements Exception {
  const ReviewException(this.message);

  final String message;

  static const cannotRateYourself = ReviewException(
    'You cannot rate yourself.',
  );
  static const duplicate = ReviewException('You already rated this member.');
  static const invalidRating = ReviewException('Choose from 1 to 5 stars.');
  static const invalidTags = ReviewException(
    'Choose up to ${ReviewDocument.maxTags} of the feedback options.',
  );

  @override
  String toString() => message;
}

/// What a trade or group the rating is about is.
enum ReviewContextKind { trade, groupTrade }

/// A rating before it is sent.
class ReviewDraft {
  const ReviewDraft({
    required this.subjectId,
    required this.rating,
    required this.contextId,
    required this.contextKind,
    this.tags = const [],
    this.skillTitle = '',
  });

  /// The rated member's Firebase uid.
  final String subjectId;
  final int rating;
  final List<String> tags;

  /// The trade or group on the reviewer's device. Trades are not shared
  /// online yet, so this proves nothing about the trade.
  final String contextId;
  final ReviewContextKind contextKind;
  final String skillTitle;
}

/// Ratings members give each other, kept at the top-level
/// `reviews/{reviewId}` by uid only, with no names or other profile data.
///
/// For now each member rates another member once: the id is
/// `{reviewerUid}_{subjectUid}`. Once trades are shared online this can
/// become once per completed trade, checked by the server.
///
/// A member's received reviews can be read by them and by each reviewer;
/// by others only while the member's public profile is switched on. Nobody
/// can change or delete a review from the app, so they are kept when
/// either account is deleted.
abstract class ReviewRepository {
  /// Sends [draft] as [uid]'s review and returns it as [uid] sees it.
  /// Throws a [ReviewException], including [ReviewException.duplicate].
  Future<Review> createReview(String uid, ReviewDraft draft);

  /// The reviews of [subjectUid] as [viewerUid] sees them, newest first, or
  /// null if they are private to [subjectUid]. Throws a [ReviewException].
  Future<List<Review>?> fetchReviewsAbout(
    String subjectUid, {
    required String viewerUid,
  });

  /// The reviews [uid] wrote. Throws a [ReviewException].
  Future<List<Review>> fetchReviewsBy(String uid);
}

/// Converts between [Review] and the data stored in `reviews/{reviewId}`.
abstract final class ReviewDocument {
  static const maxTags = 5;
  static const maxSkillTitleLength = 100;

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// The fixed id of [reviewerUid]'s review of [subjectUid].
  static String reviewIdFor(String reviewerUid, String subjectUid) {
    if (!_safeId.hasMatch(reviewerUid) || !_safeId.hasMatch(subjectUid)) {
      throw const ReviewException('This member cannot be rated.');
    }
    return '${reviewerUid}_$subjectUid';
  }

  /// Checks [draft] by [uid] before anything is sent.
  static void validate(String uid, ReviewDraft draft) {
    if (draft.subjectId == uid || draft.subjectId == User.currentUserId) {
      throw ReviewException.cannotRateYourself;
    }
    if (draft.rating < 1 || draft.rating > 5) {
      throw ReviewException.invalidRating;
    }
    final tags = draft.tags;
    if (tags.length > maxTags ||
        tags.toSet().length != tags.length ||
        !tags.every(AppOptions.ratingTags.contains)) {
      throw ReviewException.invalidTags;
    }
    if (!_safeId.hasMatch(draft.contextId)) {
      throw const ReviewException('This exchange cannot be rated.');
    }
    reviewIdFor(uid, draft.subjectId);
  }

  /// The fields stored for [draft] by [uid]; `createdAt` is added by the
  /// server. No names, phone or other profile data.
  static Map<String, dynamic> toData(String uid, ReviewDraft draft) {
    final title = draft.skillTitle.trim();
    return {
      'reviewerId': uid,
      'subjectId': draft.subjectId,
      'rating': draft.rating,
      'tags': [...draft.tags],
      'contextId': draft.contextId,
      'contextKind': draft.contextKind.name,
      if (title.isNotEmpty)
        'skillTitle': title.length > maxSkillTitleLength
            ? title.substring(0, maxSkillTitleLength)
            : title,
    };
  }

  /// Reads stored data as [viewerUid] sees it: their own uid becomes the
  /// app's current member, as everywhere else. Tags are shown as the
  /// review's comment, as on this device.
  static Review fromData(
    String id,
    Map<String, dynamic> data, {
    String? viewerUid,
  }) {
    String asSeen(Object? uid) {
      final value = uid is String ? uid : '';
      return viewerUid != null && value == viewerUid
          ? User.currentUserId
          : value;
    }

    final created = data['createdAt'];
    final tags = data['tags'] is List
        ? (data['tags'] as List).whereType<String>().toList()
        : const <String>[];
    return Review(
      id: id,
      authorId: asSeen(data['reviewerId']),
      subjectId: asSeen(data['subjectId']),
      rating: data['rating'] is num ? (data['rating'] as num).toDouble() : 0,
      comment: tags.join(' • '),
      contextId: data['contextId'] is String ? data['contextId'] as String : '',
      skillTitle: data['skillTitle'] is String
          ? data['skillTitle'] as String
          : '',
      date: switch (created) {
        Timestamp() => created.toDate(),
        DateTime() => created,
        _ => DateTime.now(),
      },
    );
  }

  static List<Review> newestFirst(Iterable<Review> reviews) =>
      reviews.toList()..sort((a, b) => b.date.compareTo(a.date));
}

/// Reviews in Cloud Firestore.
class FirebaseReviewRepository implements ReviewRepository {
  FirebaseReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// The most reviews fetched at once for one member.
  static const fetchLimit = 200;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  @override
  Future<Review> createReview(String uid, ReviewDraft draft) async {
    ReviewDocument.validate(uid, draft);
    final id = ReviewDocument.reviewIdFor(uid, draft.subjectId);
    final data = ReviewDocument.toData(uid, draft);
    return _guard(() async {
      // Among the reviewer's own reviews, by field: a lookup by id would
      // read the document itself, which the rules allow only once it
      // exists. The rules also refuse a second review with the same id.
      final existing = await _reviews
          .where('reviewerId', isEqualTo: uid)
          .where('subjectId', isEqualTo: draft.subjectId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) throw ReviewException.duplicate;
      await _reviews.doc(id).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ReviewDocument.fromData(id, {
        ...data,
        'createdAt': DateTime.now(),
      }, viewerUid: uid);
    });
  }

  @override
  Future<List<Review>?> fetchReviewsAbout(
    String subjectUid, {
    required String viewerUid,
  }) async {
    try {
      final snapshot = await _reviews
          .where('subjectId', isEqualTo: subjectUid)
          .limit(fetchLimit)
          .get();
      return ReviewDocument.newestFirst([
        for (final doc in snapshot.docs)
          ReviewDocument.fromData(doc.id, doc.data(), viewerUid: viewerUid),
      ]);
    } on FirebaseException catch (error) {
      // The member keeps their reviews private.
      if (error.code == 'permission-denied') return null;
      throw _describe(error);
    } catch (_) {
      throw const ReviewException('We could not load ratings. Try again.');
    }
  }

  @override
  Future<List<Review>> fetchReviewsBy(String uid) => _guard(() async {
    final snapshot = await _reviews
        .where('reviewerId', isEqualTo: uid)
        .limit(fetchLimit)
        .get();
    return ReviewDocument.newestFirst([
      for (final doc in snapshot.docs)
        ReviewDocument.fromData(doc.id, doc.data(), viewerUid: uid),
    ]);
  });

  static ReviewException _describe(FirebaseException error) =>
      ReviewException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your rating could not be saved.',
        _ => 'We could not reach ratings. Try again.',
      });

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ReviewException {
      rethrow;
    } on FirebaseException catch (error) {
      throw _describe(error);
    } catch (_) {
      throw const ReviewException('We could not reach ratings. Try again.');
    }
  }
}

/// Keeps reviews in memory, with the same rules as Firestore. Used when
/// Firebase has not been set up, such as in tests.
class DemoReviewRepository implements ReviewRepository {
  /// [isPublic] says whether a member's public profile is switched on, as
  /// the rules check it.
  DemoReviewRepository({bool Function(String uid)? isPublic})
    : _isPublic = isPublic ?? ((_) => true);

  final bool Function(String uid) _isPublic;
  final Map<String, Map<String, dynamic>> _reviews = {};
  DateTime _lastCreated = DateTime(2000);

  /// A copy of what is stored for review [id], or null.
  Map<String, dynamic>? storedData(String id) {
    final data = _reviews[id];
    return data == null ? null : {...data};
  }

  @override
  Future<Review> createReview(String uid, ReviewDraft draft) async {
    ReviewDocument.validate(uid, draft);
    final id = ReviewDocument.reviewIdFor(uid, draft.subjectId);
    if (_reviews.containsKey(id)) throw ReviewException.duplicate;
    final now = DateTime.now();
    _lastCreated = now.isAfter(_lastCreated)
        ? now
        : _lastCreated.add(const Duration(milliseconds: 1));
    _reviews[id] = {
      ...ReviewDocument.toData(uid, draft),
      'createdAt': _lastCreated,
    };
    return ReviewDocument.fromData(id, _reviews[id]!, viewerUid: uid);
  }

  @override
  Future<List<Review>?> fetchReviewsAbout(
    String subjectUid, {
    required String viewerUid,
  }) async {
    final about = [
      for (final MapEntry(:key, :value) in _reviews.entries)
        if (value['subjectId'] == subjectUid)
          ReviewDocument.fromData(key, value, viewerUid: viewerUid),
    ];
    // As the rules: others may only read them while the profile is public;
    // each reviewer can still read their own.
    if (subjectUid != viewerUid && !_isPublic(subjectUid)) return null;
    return ReviewDocument.newestFirst(about);
  }

  @override
  Future<List<Review>> fetchReviewsBy(String uid) async =>
      ReviewDocument.newestFirst([
        for (final MapEntry(:key, :value) in _reviews.entries)
          if (value['reviewerId'] == uid)
            ReviewDocument.fromData(key, value, viewerUid: uid),
      ]);
}
