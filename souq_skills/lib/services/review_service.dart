import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:souq_skills/data/review_repository.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'badge_service.dart';
import 'group_trade_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'repository.dart';
import 'safety_service.dart';
import 'trade_service.dart';

export 'package:souq_skills/data/review_repository.dart' show ReviewException;

enum ReviewsLoadStatus { notLoaded, loading, loaded, failed }

/// How loading one member's reviews went, with a message if it failed.
class ReviewsLoadState {
  const ReviewsLoadState(this.status, [this.message = '']);

  final ReviewsLoadStatus status;
  final String message;
}

class ReviewService {
  static const _me = User.currentUserId;

  final Repository _repo = Repository.instance;

  static ReviewRepository? _online;

  /// Where real members' reviews are kept: Firestore once Firebase has been
  /// initialized. Null in the offline demo, where every review stays on
  /// this device. Can be replaced, e.g. with a fake.
  static ReviewRepository? get repository =>
      _online ??
      (Firebase.apps.isEmpty ? null : _online = FirebaseReviewRepository());
  static set repository(ReviewRepository? value) {
    _online = value;
    _resetLoads();
  }

  /// Load progress per member id (`'me'` for the current member's own
  /// given and received reviews), for screens to listen to.
  static final ValueNotifier<Map<String, ReviewsLoadState>> loadStates =
      ValueNotifier(const {});

  /// The account [loadStates] and [_hidden] belong to.
  static String? _statesFor;

  /// Members whose public profile is switched off, so their reviews are
  /// private to them.
  static final Set<String> _hidden = {};

  static final Map<String, Future<void>> _loading = {};
  static final Map<String, Future<Review>> _sending = {};

  static void _resetLoads() {
    _statesFor = null;
    _hidden.clear();
    _loading.clear();
    loadStates.value = const {};
  }

  /// Forgets what was loaded for another account.
  static void _useAccount(String? uid) {
    if (_statesFor == uid) return;
    _resetLoads();
    _statesFor = uid;
  }

  static void _setState(String id, ReviewsLoadState state) =>
      loadStates.value = {...loadStates.value, id: state};

  /// How loading [memberId]'s reviews went for the signed-in account.
  /// Always loaded offline and for demo members, whose reviews are here.
  ReviewsLoadState stateOf(String memberId) {
    final id = _key(memberId);
    if (repository == null || (id != _me && !_isRealMember(id))) {
      return const ReviewsLoadState(ReviewsLoadStatus.loaded);
    }
    if (_statesFor != AuthService.repository.uid) {
      return const ReviewsLoadState(ReviewsLoadStatus.notLoaded);
    }
    return loadStates.value[id] ??
        const ReviewsLoadState(ReviewsLoadStatus.notLoaded);
  }

  /// Whether [memberId] keeps their ratings private. Never the current
  /// member, who always sees their own.
  bool isHidden(String memberId) =>
      memberId != _me &&
      _statesFor == AuthService.repository.uid &&
      _hidden.contains(memberId);

  List<Review> receivedBy(String memberId) => isHidden(memberId)
      ? const []
      : _newestFirst(_repo.reviews.where((item) => item.subjectId == memberId));

  List<Review> givenByCurrentUser() =>
      _newestFirst(_repo.reviews.where((item) => item.authorId == _me));

  /// Ratings given and received by the current user, newest first.
  List<Review> latestForCurrentUser({required int limit}) => _newestFirst(
    _repo.reviews.where(
      (item) => item.authorId == _me || item.subjectId == _me,
    ),
  ).take(limit).toList();

  double? averageRatingOf(String memberId) {
    final reviews = receivedBy(memberId);
    if (reviews.isEmpty) return null;
    final total = reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  /// The current member's rating for the exchange [contextId]: of
  /// [subjectId] when given, otherwise the first found (a trade has only one
  /// member to rate). Legacy reviews count for the exchange they name.
  Review? givenFor(String contextId, {String? subjectId}) {
    for (final review in _repo.reviews) {
      if (review.authorId == _me &&
          review.contextId == contextId &&
          (subjectId == null || review.subjectId == subjectId)) {
        return review;
      }
    }
    return null;
  }

  /// Whether the current member rated [subjectId] for the exchange
  /// [contextId]. Without [subjectId]: whether everyone they can rate there
  /// is rated, or, for an exchange that cannot be rated (any more), whether
  /// they rated anyone there.
  bool hasRated(String contextId, {String? subjectId}) {
    if (subjectId != null) {
      return givenFor(contextId, subjectId: subjectId) != null;
    }
    final requests = requestsFor(contextId);
    if (requests.isEmpty) return givenFor(contextId) != null;
    return requests.every(
      (request) => givenFor(contextId, subjectId: request.subjectId) != null,
    );
  }

  /// Whether rating [contextId] would be accepted for someone: it is
  /// finished, and at least one of its other members is not rated for it
  /// yet. Each member can be rated once per exchange.
  bool canRate(String contextId) =>
      requestsFor(contextId)
          .any((request) => !hasRated(contextId, subjectId: request.subjectId));

  /// Whether the current member rated real member [memberId] online for any
  /// exchange. Not a limit on rating them again for another exchange.
  bool hasRatedMember(String memberId) => _repo.reviews.any(
    (item) =>
        item.authorId == _me &&
        item.subjectId == memberId &&
        _isOnlineReview(item),
  );

  /// Everyone the current member can rate for the finished trade or group
  /// [contextId], rated already or not: a trade's other member, or each
  /// other member of a group they belong to, organizer first. Empty if it
  /// is not finished or not theirs.
  List<RatingRequest> requestsFor(String contextId) {
    final trade = TradeService().byId(contextId);
    if (trade != null) {
      if (!trade.isComplete) return const [];
      return [
        RatingRequest(
          contextId: contextId,
          subjectId: trade.otherMemberId,
          subjectName: MemberService().nameOf(trade.otherMemberId),
          skillTitle: trade.requestedSkill,
        ),
      ];
    }
    final groups = GroupTradeService();
    final group = groups.byId(contextId);
    if (group == null || !group.isCompleted || !groups.isMember(group)) {
      return const [];
    }
    final subjectIds = {
      if (group.memberIds.contains(group.ownerId)) group.ownerId,
      ...group.memberIds,
    }..removeWhere((id) => id.isEmpty || id == _me);
    return [
      for (final subjectId in subjectIds)
        RatingRequest(
          contextId: contextId,
          subjectId: subjectId,
          subjectName: MemberService().nameOf(subjectId),
          skillTitle: group.title,
        ),
    ];
  }

  /// What to rate next for the finished trade or group [contextId]: the
  /// first member not rated for it yet, or, once everyone is, the first
  /// member (so it can be shown as already rated). Null if nothing there can
  /// be rated.
  RatingRequest? requestFor(String contextId) {
    final requests = requestsFor(contextId);
    for (final request in requests) {
      if (!hasRated(contextId, subjectId: request.subjectId)) return request;
    }
    return requests.firstOrNull;
  }

  /// Saves a rating on this device straight away. Kept for compatibility;
  /// [submitRating] also saves real members' ratings online.
  void submit(RatingRequest request, int stars, String comment) {
    if (stars < 1 || stars > 5) {
      throw ArgumentError.value(stars, 'stars', 'Must be between 1 and 5');
    }
    _saveOnDevice(request, stars, comment);
    MemberSimulator().rateCurrentUser(request);
  }

  /// Rates [request]'s member with [stars] and feedback [tags].
  ///
  /// A real member is rated online first, and only once saved there on this
  /// device; demo members, and everyone in the offline demo, on this device
  /// only. Throws a [ReviewException] and changes nothing if it fails, for
  /// the current member, or if the member was already rated for this
  /// exchange. The same rating sent twice at once is sent once; ratings of
  /// other exchanges or members are sent separately.
  Future<Review> submitRating(
    RatingRequest request,
    int stars,
    List<String> tags,
  ) {
    final uid = AuthService.repository.uid;
    final subject = request.subjectId;
    if (subject == _me || (uid != null && subject == uid)) {
      return Future.error(ReviewException.cannotRateYourself);
    }
    final draft = ReviewDraft(
      subjectId: subject,
      rating: stars,
      tags: tags,
      contextId: request.contextId,
      contextKind: TradeService().byId(request.contextId) != null
          ? ReviewContextKind.trade
          : ReviewContextKind.groupTrade,
      skillTitle: request.skillTitle,
    );
    final online = repository;
    if (online == null || !_isRealMember(subject)) {
      return Future.sync(() {
        if (hasRated(request.contextId, subjectId: subject)) {
          throw ReviewException.duplicate;
        }
        ReviewDocument.validate(uid ?? 'device', draft);
        final saved = _saveOnDevice(request, stars, tags.join(' • '));
        if (SafetyService.isDemoMember(subject)) {
          MemberSimulator().rateCurrentUser(request);
        }
        return saved;
      });
    }
    if (uid == null) {
      return Future.error(
        const ReviewException('Your session has expired. Sign in again.'),
      );
    }
    // One send per member per exchange, as the review's id.
    final key = '$uid ${request.contextId} $subject';
    final sending = _sending[key];
    if (sending != null) return sending;
    if (hasRated(request.contextId, subjectId: subject)) {
      return Future.error(ReviewException.duplicate);
    }
    return _sending[key] = _sendOnline(online, uid, draft)
        // A block body: returning the removed future would make this one
        // wait for itself.
        .whenComplete(() {
          _sending.remove(key);
        });
  }

  Future<Review> _sendOnline(
    ReviewRepository online,
    String uid,
    ReviewDraft draft,
  ) async {
    final Review saved;
    try {
      saved = await online.createReview(uid, draft);
    } on ReviewException catch (error) {
      // Rated before, perhaps on another device: load it so it shows here.
      if (identical(error, ReviewException.duplicate) &&
          uid == AuthService.repository.uid) {
        refreshReviews(const [_me], refresh: true).ignore();
      }
      rethrow;
    }
    // Sent for an account that has since signed out or switched: it stays
    // that account's, and nothing changes here.
    if (uid != AuthService.repository.uid) return saved;
    _repo.reviews.removeWhere((item) => item.id == saved.id);
    _repo.insert(_repo.reviews, saved);
    BadgeService().sync();
    return saved;
  }

  Review _saveOnDevice(RatingRequest request, int stars, String comment) {
    final review = Review(
      id: _repo.nextId('r'),
      authorId: _me,
      subjectId: request.subjectId,
      contextId: request.contextId,
      skillTitle: request.skillTitle,
      rating: stars.toDouble(),
      comment: comment.trim(),
      date: DateTime.now(),
    );
    _repo.insert(_repo.reviews, review);
    BadgeService().sync();
    return review;
  }

  /// Loads the reviews of [memberIds] for the signed-in account: `'me'`
  /// loads the reviews they gave and received. Real members' reviews on
  /// this device are replaced with what is online; demo reviews and those
  /// made on this device are kept. Members already loaded are not fetched
  /// again unless [refresh]. Never throws: the outcome is in [loadStates].
  /// Does nothing offline.
  Future<void> refreshReviews(
    Iterable<String> memberIds, {
    bool refresh = false,
  }) {
    final online = repository;
    if (online == null) return Future.value();
    final uid = AuthService.repository.uid;
    _useAccount(uid);
    final loads = <Future<void>>[];
    for (final id in {for (final id in memberIds) _key(id)}) {
      if (id != _me && !_isRealMember(id)) continue;
      final running = _loading[id];
      if (running != null) {
        loads.add(running);
        continue;
      }
      final status = loadStates.value[id]?.status;
      if (!refresh && status == ReviewsLoadStatus.loaded) continue;
      final loading = _load(online, uid, id);
      _loading[id] = loading;
      loads.add(loading);
      // A block body, as in [submitRating].
      loading.whenComplete(() {
        if (identical(_loading[id], loading)) _loading.remove(id);
      }).ignore();
    }
    return Future.wait(loads).then((_) {});
  }

  Future<void> _load(ReviewRepository online, String? uid, String id) async {
    _setState(id, const ReviewsLoadState(ReviewsLoadStatus.loading));
    bool isCurrent() =>
        uid == AuthService.repository.uid &&
        _statesFor == uid &&
        identical(online, repository);
    try {
      if (uid == null) {
        throw const ReviewException('Your session has expired. Sign in again.');
      }
      if (id == _me) {
        final (given, received) = await (
          online.fetchReviewsBy(uid),
          online.fetchReviewsAbout(uid, viewerUid: uid),
        ).wait;
        final mine = [...given, ...?received];
        if (!isCurrent()) return;
        _replace((item) => item.authorId == _me || item.subjectId == _me, mine);
        BadgeService().sync();
      } else {
        final about = await online.fetchReviewsAbout(id, viewerUid: uid);
        if (!isCurrent()) return;
        if (about == null) {
          _hidden.add(id);
          // Only the current member's own rating of them is kept; it comes
          // with 'me'.
          _replace(
            (item) => item.subjectId == id && item.authorId != _me,
            const [],
          );
        } else {
          _hidden.remove(id);
          _replace((item) => item.subjectId == id, about);
        }
      }
      _setState(id, const ReviewsLoadState(ReviewsLoadStatus.loaded));
    } catch (error) {
      if (!isCurrent()) return;
      final cause = error is ParallelWaitError
          ? (error.errors as (AsyncError?, AsyncError?)).$1?.error ??
                (error.errors as (AsyncError?, AsyncError?)).$2?.error
          : error;
      _setState(
        id,
        ReviewsLoadState(
          ReviewsLoadStatus.failed,
          cause is ReviewException
              ? cause.message
              : 'We could not load ratings. Try again.',
        ),
      );
    }
  }

  /// Replaces the online reviews matching [where] with [fetched].
  void _replace(bool Function(Review) where, List<Review> fetched) {
    final byId = {for (final item in fetched) item.id: item};
    _repo.reviews
      ..removeWhere(
        (item) =>
            _isOnlineReview(item) && (where(item) || byId.containsKey(item.id)),
      )
      ..addAll(byId.values);
    _repo.emitChange();
  }

  static String _key(String memberId) =>
      memberId == AuthService.repository.uid ? _me : memberId;

  /// Reviews made on this device have local ids (`r-…`); online ones are
  /// `{reviewerUid}_{subjectUid}`, and Firebase uids have no hyphen.
  static bool _isOnlineReview(Review item) => !item.id.startsWith('r-');

  static bool _isRealMember(String id) =>
      id.isNotEmpty && id != _me && !SafetyService.isDemoMember(id);

  List<Review> _newestFirst(Iterable<Review> reviews) =>
      reviews.toList()..sort((a, b) => b.date.compareTo(a.date));
}
