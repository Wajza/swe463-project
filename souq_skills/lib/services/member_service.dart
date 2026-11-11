import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
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

  /// Members whose public profiles are being fetched right now.
  static final Set<String> _fetching = {};

  /// Fetches the public profiles of [ids] that are not known yet and keeps
  /// them with the other members, so [byId] and [nameOf] find them. With
  /// [refresh], known members are fetched again too.
  ///
  /// Never the current member: neither the local id nor the signed-in uid
  /// is ever stored as another member. Members already being fetched are
  /// not fetched twice. Offline it does nothing. Never throws: a member
  /// that could not be fetched is simply tried again next time.
  Future<void> loadMembers(Iterable<String> ids, {bool refresh = false}) async {
    final profiles = AuthService.profiles;
    if (profiles == null) return;
    final uid = AuthService.repository.uid;
    final wanted = {
      for (final id in ids)
        if (id.isNotEmpty &&
            id != User.currentUserId &&
            id != uid &&
            !_fetching.contains(id) &&
            (refresh || _repo.find(_repo.members, id) == null))
          id,
    };
    // The signed-in account may have been kept as another member while
    // someone else was signed in on this device; now it is 'me' instead.
    final staleSelf = uid != null && _repo.members.any((m) => m.id == uid);
    if (wanted.isEmpty && !staleSelf) return;
    _fetching.addAll(wanted);
    var found = const <String, User>{};
    try {
      // Always awaited, so members never change while a screen is built.
      found = wanted.isEmpty
          ? await Future.value(found)
          : await profiles.fetchPublicProfiles(wanted);
    } catch (_) {
      // Left out; tried again next time.
    } finally {
      _fetching.removeAll(wanted);
    }
    // Fetched for an account that has since signed out or switched.
    if (uid != AuthService.repository.uid) return;
    _repo.members
      ..removeWhere((member) => member.id == uid)
      ..removeWhere((member) => found.containsKey(member.id))
      ..addAll(found.values);
    _repo.emitChange();
  }
}
