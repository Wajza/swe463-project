import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'chat_service.dart';
import 'repository.dart';
import 'wallet_service.dart';

class GroupTradeService {
  static const completionCredits = 15;
  static const _me = User.currentUserId;

  final Repository _repo = Repository.instance;

  List<GroupTrade> all() => _repo.groupTrades
      .where((group) => group.status != GroupTradeStatus.cancelled)
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

  void join(String id) {
    _repo.update(
      _repo.groupTrades,
      id,
      (group) => group.copyWith(
        memberIds: {...group.memberIds, _me}.toList(),
        invitedIds: group.invitedIds.where((item) => item != _me).toList(),
      ),
    );
    ChatService().postSystem(
      ChatService.groupConversationId(id),
      '${_repo.currentUser.name} joined the group.',
    );
    BadgeService().sync();
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
}
