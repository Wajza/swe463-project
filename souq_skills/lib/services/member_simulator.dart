import 'dart:async';

import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'group_trade_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'proposal_service.dart';
import 'repository.dart';

/// Stands in for the other members and support staff until a backend exists.
class MemberSimulator {
  static const replyDelay = Duration(seconds: 2);

  /// Long enough for a member to counter their own proposal first.
  static const proposalReplyDelay = Duration(seconds: 30);

  final Repository _repo = Repository.instance;

  void acceptProposal(String proposalId) => _later(
    () => ProposalService().accept(proposalId, byOtherMember: true),
    delay: proposalReplyDelay,
  );

  void acceptGroupInvitation(String groupId, String memberId) =>
      _later(() => GroupTradeService().memberAccepted(groupId, memberId));

  /// Restarts replies that were still waiting when the app last closed.
  void resumePendingProposals() {
    for (final proposal in _repo.proposals) {
      if (proposal.isPending && proposal.senderId == User.currentUserId) {
        acceptProposal(proposal.id);
      }
    }
  }

  void replyInChat(String memberId) => _later(
    () => ChatService().receive(
      memberId,
      MemberService().nameOf(memberId),
      'Thanks for your message! Let’s arrange the details.',
    ),
  );

  /// The other member rates the current user after an exchange.
  void rateCurrentUser(RatingRequest request) => _later(() {
    _repo.insert(
      _repo.reviews,
      Review(
        id: _repo.nextId('r'),
        authorId: request.subjectId,
        subjectId: User.currentUserId,
        contextId: request.contextId,
        skillTitle: request.skillTitle,
        rating: 5,
        comment: 'Great exchange. I would happily trade again!',
        date: DateTime.now(),
      ),
    );
    NotificationService().push(
      title: '${request.subjectName} rated you',
      message: 'See your new rating on your profile.',
      type: NotificationType.review,
      route: AppRoutes.reviews,
    );
    BadgeService().sync();
  });

  void _later(void Function() action, {Duration delay = replyDelay}) =>
      Timer(delay, () {
        if (_repo.isSignedIn) action();
      });
}
