import 'package:flutter/foundation.dart';
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

  /// Members whose public profile was fetched, or tried, in this app
  /// session for the signed-in account [_checkedFor]. Kept in memory only,
  /// so copies kept on this device from an earlier session are checked
  /// again once, and a page refresh shows members' latest names.
  static final Set<String> _checked = {};
  static String? _checkedFor;

  /// Forgets which members were checked, as a new app session would.
  @visibleForTesting
  static void forgetChecked() {
    _checked.clear();
    _checkedFor = null;
  }

  /// Fetches the public profiles of [ids] and keeps them with the other
  /// members, so [byId] and [nameOf] find them: members not known yet, and
  /// known ones not checked yet in this app session, whose copy on this
  /// device may be out of date. Known members are shown at once from that
  /// copy until the new one arrives. With [refresh], every member is
  /// fetched again.
  ///
  /// Never the current member: neither the local id nor the signed-in uid
  /// is ever stored as another member. Members already being fetched are
  /// not fetched twice. Offline it does nothing. Never throws: a member not
  /// known yet who could not be fetched is simply tried again next time; a
  /// known one keeps their copy until the next session.
  Future<void> loadMembers(Iterable<String> ids, {bool refresh = false}) async {
    final profiles = AuthService.profiles;
    if (profiles == null) return;
    final uid = AuthService.repository.uid;
    // Checks made for another account never count for this one.
    if (_checkedFor != uid) {
      _checked.clear();
      _checkedFor = uid;
    }
    final wanted = {
      for (final id in ids)
        if (id.isNotEmpty &&
            id != User.currentUserId &&
            id != uid &&
            !_fetching.contains(id) &&
            (refresh ||
                _repo.find(_repo.members, id) == null ||
                !_checked.contains(id)))
          id,
    };
    final known = {
      for (final id in wanted)
        if (_repo.find(_repo.members, id) != null) id,
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
    // Checked for this session: those found, and known ones even if not
    // (failed, or no longer published), which keep their copy rather than
    // being asked for again and again. Unknown ones are tried again.
    _checked.addAll({
      for (final id in wanted)
        if (found.containsKey(id) || known.contains(id)) id,
    });
    _repo.members
      ..removeWhere((member) => member.id == uid)
      ..removeWhere((member) => found.containsKey(member.id))
      ..addAll(found.values);
    _repo.emitChange();
  }
}
