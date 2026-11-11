import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'member_service.dart';
import 'member_simulator.dart';
import 'notification_service.dart';
import 'online_groups.dart';
import 'repository.dart';
import 'safety_service.dart';
import 'wallet_service.dart';

export 'online_groups.dart' show GroupTradeException;

/// Group trades are invite only: members only see groups they belong to or
/// have been invited to.
///
/// Groups created by a signed-in real member are kept online with real
/// members ([OnlineGroups]): every member confirms before a group
/// completes, and each then gets [completionCredits] in their online
/// wallet. Groups with the built-in demo members, and every group in the
/// offline demo, stay on this device as before: the organizer completes
/// them alone. Online changes throw a [GroupTradeException] on failure.
class GroupTradeService {
  static const completionCredits = WalletDocument.groupReward;
  static const _me = User.currentUserId;

  final Repository _repo = Repository.instance;

  List<GroupTrade> all() => [...OnlineGroups.groups(), ..._repo.groupTrades]
      .where(
        (group) =>
            group.status != GroupTradeStatus.cancelled &&
            (isMember(group) || isInvited(group)),
      )
      .toList();

  GroupTrade? byId(String id) =>
      _repo.find(_repo.groupTrades, id) ?? OnlineGroups.group(id);

  /// Whether [group] is kept online with real members.
  bool isOnline(GroupTrade group) => OnlineGroups.group(group.id) != null;

  bool isOwner(GroupTrade group) => group.ownerId == _me;
  bool isMember(GroupTrade group) => group.memberIds.contains(_me);
  bool isInvited(GroupTrade group) => group.invitedIds.contains(_me);
  bool hasConfirmed(GroupTrade group) => group.confirmedIds.contains(_me);

  bool _isOpen(GroupTrade group) =>
      !group.isCompleted && group.status != GroupTradeStatus.cancelled;

  /// Every current member of online [group] has confirmed.
  bool _allConfirmed(GroupTrade group) =>
      group.memberIds.every(group.confirmedIds.contains);

  /// Whether the current member can mark [group] complete now: on this
  /// device the organizer alone; online any member who has not confirmed
  /// yet (or, once everyone has, to finish it).
  bool canComplete(GroupTrade group) => isOnline(group)
      ? isMember(group) &&
            _isOpen(group) &&
            group.memberIds.length >= 2 &&
            (!hasConfirmed(group) || _allConfirmed(group))
      : isOwner(group) && !group.isCompleted && group.memberIds.length >= 2;

  /// The members of [group] who still have to confirm it.
  int waitingFor(GroupTrade group) =>
      group.memberIds.where((id) => !group.confirmedIds.contains(id)).length;

  /// Whether the organizer can remove [memberId] from online [group], so
  /// an inactive member cannot hold up its completion.
  bool canRemove(GroupTrade group, String memberId) =>
      isOnline(group) &&
      isOwner(group) &&
      _isOpen(group) &&
      memberId != group.ownerId &&
      group.memberIds.contains(memberId);

  /// Whether the organizer can delete [group]: online, only before it
  /// completes, so its members keep it and their rewards.
  bool canDelete(GroupTrade group) =>
      isOwner(group) && (!isOnline(group) || _isOpen(group));

  /// Creates a group from [draft] and returns its id: online when a real
  /// member is signed in, otherwise on this device as before.
  Future<String> createGroup(GroupTrade draft) async {
    if (!OnlineGroups.isAvailable) return create(draft).id;
    final (online, uid) = OnlineGroups.signedIn();
    final id = await online.create(uid, draft);
    OnlineGroups.remember(
      draft.copyWith(id: id, ownerId: _me, memberIds: const [_me]),
    );
    BadgeService().sync();
    return id;
  }

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

  /// Saves [group]'s details: online for an online group.
  Future<void> save(GroupTrade group) async {
    if (!isOnline(group)) return update(group);
    final (online, uid) = OnlineGroups.signedIn();
    await online.updateDetails(uid, group.id, group);
  }

  void delete(String id) => _repo.remove(_repo.groupTrades, id);

  /// Deletes group [id] for all its members; an online group is cancelled.
  Future<void> deleteGroup(String id) async {
    if (OnlineGroups.group(id) == null) return delete(id);
    final (online, uid) = OnlineGroups.signedIn();
    await online.cancel(uid, id);
  }

  /// Members whose username matches [query] and who can still be invited.
  /// Signed in online, a group on this device takes only demo members and
  /// an online group only real members, so every invitee can answer.
  List<User> inviteCandidates(GroupTrade group, String query) {
    final search = query.trim().toLowerCase().replaceFirst('@', '');
    if (search.isEmpty) return const [];
    final online = OnlineGroups.isAvailable;
    final wantsReal = isOnline(group);
    return _repo.members
        .where(
          (member) =>
              member.username.toLowerCase().contains(search) &&
              !group.memberIds.contains(member.id) &&
              !group.invitedIds.contains(member.id) &&
              !_repo.blockedMemberIds.contains(member.id) &&
              (!online || SafetyService.isDemoMember(member.id) != wantsReal),
        )
        .toList();
  }

  /// Invites the member with [username] to online [group], looked up
  /// online, as they may not have been loaded on this device.
  Future<void> inviteByUsername(GroupTrade group, String username) async {
    final (online, uid) = OnlineGroups.signedIn();
    final memberUid = await online.findMember(username);
    if (memberUid == uid) throw GroupTradeException.cannotInvite;
    if (SafetyService().isBlocked(memberUid)) {
      throw const GroupTradeException('Unblock this member to invite them.');
    }
    await online.invite(uid, group.id, memberUid);
  }

  Future<void> invite(String groupId, User member) async {
    if (OnlineGroups.group(groupId) != null) {
      final (online, uid) = OnlineGroups.signedIn();
      return online.invite(uid, groupId, member.id);
    }
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

  Future<void> acceptInvitation(String id) async {
    if (OnlineGroups.group(id) != null) {
      final (online, uid) = OnlineGroups.signedIn();
      await online.respondToInvitation(uid, id, accept: true);
    } else {
      _addMember(id, _me);
    }
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

  Future<void> leave(String id) => removeMember(id, _me);

  /// [memberId] leaves [groupId] when it is the current member, or the
  /// organizer removes them.
  Future<void> removeMember(String groupId, String memberId) async {
    if (OnlineGroups.group(groupId) != null) {
      final (online, uid) = OnlineGroups.signedIn();
      return online.removeMember(
        uid,
        groupId,
        memberId == _me ? uid : memberId,
      );
    }
    _repo.update(
      _repo.groupTrades,
      groupId,
      (group) => group.copyWith(
        memberIds: group.memberIds.where((item) => item != memberId).toList(),
      ),
    );
  }

  Future<void> declineInvitation(String id) async {
    if (OnlineGroups.group(id) != null) {
      final (online, uid) = OnlineGroups.signedIn();
      return online.respondToInvitation(uid, id, accept: false);
    }
    _repo.update(
      _repo.groupTrades,
      id,
      (group) => group.copyWith(
        invitedIds: group.invitedIds.where((item) => item != _me).toList(),
      ),
    );
  }

  /// The current member marks [id] complete; returns whether it is now
  /// completed. On this device the organizer completes it straight away,
  /// as before; online it completes once every member has confirmed, and
  /// each member's reward is then added to their online wallet.
  Future<bool> complete(String id) async {
    if (OnlineGroups.group(id) != null) {
      final (online, uid) = OnlineGroups.signedIn();
      return online.confirmCompletion(uid, id);
    }
    final group = byId(id);
    if (group == null) return false;
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
    return true;
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
