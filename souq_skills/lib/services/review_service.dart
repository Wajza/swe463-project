import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'group_trade_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'repository.dart';
import 'trade_service.dart';

class ReviewService {
  static const _me = User.currentUserId;

  final Repository _repo = Repository.instance;

  List<Review> receivedBy(String memberId) =>
      _newestFirst(_repo.reviews.where((item) => item.subjectId == memberId));

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

  Review? givenFor(String contextId) {
    for (final review in _repo.reviews) {
      if (review.authorId == _me && review.contextId == contextId) {
        return review;
      }
    }
    return null;
  }

  bool hasRated(String contextId) => givenFor(contextId) != null;

  /// Returns what can be rated for a finished trade or group, otherwise null.
  RatingRequest? requestFor(String contextId) {
    final trade = TradeService().byId(contextId);
    if (trade != null) {
      if (!trade.isComplete) return null;
      return RatingRequest(
        contextId: contextId,
        subjectId: trade.otherMemberId,
        subjectName: MemberService().nameOf(trade.otherMemberId),
        skillTitle: trade.requestedSkill,
      );
    }
    final group = GroupTradeService().byId(contextId);
    if (group == null || !group.isCompleted) return null;
    final subjectId = group.ownerId != _me
        ? group.ownerId
        : group.memberIds.firstWhere((id) => id != _me, orElse: () => '');
    if (subjectId.isEmpty) return null;
    return RatingRequest(
      contextId: contextId,
      subjectId: subjectId,
      subjectName: MemberService().nameOf(subjectId),
      skillTitle: group.title,
    );
  }

  void submit(RatingRequest request, int stars, String comment) {
    if (stars < 1 || stars > 5) {
      throw ArgumentError.value(stars, 'stars', 'Must be between 1 and 5');
    }
    _repo.insert(
      _repo.reviews,
      Review(
        id: _repo.nextId('r'),
        authorId: _me,
        subjectId: request.subjectId,
        contextId: request.contextId,
        skillTitle: request.skillTitle,
        rating: stars.toDouble(),
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    BadgeService().sync();
    MemberSimulator().rateCurrentUser(request);
  }

  List<Review> _newestFirst(Iterable<Review> reviews) =>
      reviews.toList()..sort((a, b) => b.date.compareTo(a.date));
}
