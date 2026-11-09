import 'package:souq_skills/models/user.dart';

import 'repository.dart';

class MemberService {
  final Repository _repo = Repository.instance;

  User? byId(String id) => id == User.currentUserId
      ? _repo.currentUser
      : _repo.find(_repo.members, id);

  String nameOf(String id) => byId(id)?.name ?? 'Member';

  bool isCurrentUser(String id) => id == User.currentUserId;
}
