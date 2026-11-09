import 'package:souq_skills/models/user.dart';

import 'repository.dart';

class MemberService {
  final Repository _repo = Repository.instance;

  User? byId(String id) => id == User.currentUserId
      ? _repo.currentUser
      : _repo.find(_repo.members, id);

  String nameOf(String id) => byId(id)?.name ?? 'Member';

  /// Usernames are unique, ignoring case.
  bool isUsernameTaken(String username, {required bool isEditingOwn}) {
    final wanted = username.toLowerCase();
    final current = _repo.currentUser;
    final isOwnedByCurrentUser =
        _repo.hasAccount && current.username.toLowerCase() == wanted;
    return (isOwnedByCurrentUser && !isEditingOwn) ||
        _repo.members.any((member) => member.username.toLowerCase() == wanted);
  }

  bool isCurrentUser(String id) => id == User.currentUserId;
}
