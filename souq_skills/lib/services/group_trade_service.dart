import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'notification_service.dart';
import 'repository.dart';
import 'wallet_service.dart';

/// Group trades are invite only: members only see groups they belong to or
/// have been invited to.
class GroupTradeService {
  static const completionCredits = 15;
  static const _me = User.currentUserId;

  final Repository _repo = Repository.instance;

  List<GroupTrade> all() => _repo.groupTrades
      .where(
        (group) =>
            group.status != GroupTradeStatus.cancelled &&
            (isMember(group) || isInvited(group)),
      )
      .toList();

  GroupTrade? byId(String id) => _repo.find(_repo.groupTrades, id);

  bool isOwner(GroupTrade group) => group.ownerId == _me;
  bool isMember(GroupTrade group) => group.memberIds.contains(_me);
  bool isInvited(GroupTrade group) => group.invitedIds.contains(_me);

  bool canComplete(GroupTrade group) =>
      isOwner(group) && !group.isCompleted && group.memberIds.length >= 2;

  GroupTrade create(GroupTrade draft) {
    final group = draft.copyWith(
      id: _repo.nextId('g'),
      ownerId: _me,
      memberIds: const [_me],
    );
    _repo.insert(_repo.groupTrades, group);
    BadgeService().sync();
    return group;
  }

  void update(GroupTrade group) =>
      _repo.update(_repo.groupTrades, group.id, (_) => group);

  void delete(String id) => _repo.remove(_repo.groupTrades, id);

  /// Members whose username matches [query] and who can still be invited.
  List<User> inviteCandidates(GroupTrade group, String query) {
    final search = query.trim().toLowerCase().replaceFirst('@', '');
    if (search.isEmpty) return const [];
    return _repo.members
        .where(
          (member) =>
              member.username.toLowerCase().contains(search) &&
              !group.memberIds.contains(member.id) &&
              !group.invitedIds.contains(member.id) &&
              !_repo.blockedMemberIds.contains(member.id),
        )
        .toList();
  }

  void invite(String groupId, User member) {
    _repo.update(
      _repo.groupTrades,
      groupId,
      (group) => group.copyWith(invitedIds: [...group.invitedIds, member.id]),
    );
    ChatService().postSystem(
      ChatService.groupConversationId(groupId),
      '@${member.username} was invited.',
    );
    MemberSimulator().acceptGroupInvitation(groupId, member.id);
  }

  void acceptInvitation(String id) {
    _addMember(id, _me);
    BadgeService().sync();
  }

  /// Records that someone else accepted their invitation to [groupId].
  void memberAccepted(String groupId, String memberId) {
    final group = byId(groupId);
    if (group == null || !group.invitedIds.contains(memberId)) return;
    _addMember(groupId, memberId);
    NotificationService().push(
      title: 'Invitation accepted',
      message: '${MemberService().nameOf(memberId)} joined ${group.title}.',
      type: NotificationType.groupTrade,
      route: AppRoutes.groupTradeDetails,
      routeArgument: groupId,
    );
  }

  void leave(String id) => _repo.update(
    _repo.groupTrades,
    id,
    (group) => group.copyWith(
      memberIds: group.memberIds.where((item) => item != _me).toList(),
    ),
  );

  void declineInvitation(String id) => _repo.update(
    _repo.groupTrades,
    id,
    (group) => group.copyWith(
      invitedIds: group.invitedIds.where((item) => item != _me).toList(),
    ),
  );

  void complete(String id) {
    final group = byId(id);
    if (group == null) return;
    _repo.update(
      _repo.groupTrades,
      id,
      (current) => current.copyWith(status: GroupTradeStatus.completed),
    );
    WalletService().record(
      title: 'Group trade completed',
      subtitle: group.title,
      amount: completionCredits,
    );
    ChatService().postSystem(
      ChatService.groupConversationId(id),
      'The group exchange was completed.',
    );
  }

  void _addMember(String groupId, String memberId) {
    _repo.update(
      _repo.groupTrades,
      groupId,
      (group) => group.copyWith(
        memberIds: {...group.memberIds, memberId}.toList(),
        invitedIds: group.invitedIds.where((id) => id != memberId).toList(),
      ),
    );
    ChatService().postSystem(
      ChatService.groupConversationId(groupId),
      '${MemberService().nameOf(memberId)} joined the group.',
    );
  }
}
