import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/group_trade_service.dart';

import 'user_avatar.dart';

/// Finds a member by username and invites them to a group.
class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({required this.group, super.key});

  final GroupTrade group;

  static Future<void> show(BuildContext context, GroupTrade group) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => InviteMemberSheet(group: group),
      );

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  static final _username = RegExp(r'^@?[A-Za-z0-9_]{3,20}$');

  String _query = '';

  /// True while an invitation to an online group is being sent.
  bool _sending = false;

  /// Why the last invitation could not be sent.
  String? _error;

  /// Sends an invitation by [send]; the sheet closes once it is sent, or
  /// stays open and explains why it was not.
  Future<void> _send(String username, Future<void> Function() send) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await send();
    } on GroupTradeException catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error.message;
        });
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    context.showMessage('Invitation sent to @$username');
  }

  void _invite(User member) => _send(
    member.username,
    () => GroupTradeService().invite(widget.group.id, member),
  );

  /// An online group can invite any member by their exact username, even
  /// one not loaded on this device.
  void _inviteByUsername(String username) => _send(
    username,
    () => GroupTradeService().inviteByUsername(widget.group, username),
  );

  /// Who [query] can invite: the matching members, the typed username, and
  /// whether an online group can invite that exact username.
  ({List<User> matches, String typed, bool canInviteTyped}) _targets(
    String query,
  ) {
    final service = GroupTradeService();
    final matches = service.inviteCandidates(widget.group, query);
    final typed = query.trim().replaceFirst('@', '');
    final canInviteTyped =
        service.isOnline(widget.group) &&
        _username.hasMatch(query.trim()) &&
        !matches.any(
          (member) => member.username.toLowerCase() == typed.toLowerCase(),
        );
    return (matches: matches, typed: typed, canInviteTyped: canInviteTyped);
  }

  /// Pressing Enter invites the one member [text] clearly means, as tapping
  /// their row would; with several matches or none, nothing happens.
  void _inviteTyped(String text) {
    final (:matches, :typed, :canInviteTyped) = _targets(text);
    final exact = matches.where(
      (member) => member.username.toLowerCase() == typed.toLowerCase(),
    );
    if (exact.length == 1) return _invite(exact.single);
    if (canInviteTyped) return _inviteByUsername(typed);
    if (matches.length == 1) _invite(matches.single);
  }

  @override
  Widget build(BuildContext context) {
    final (:matches, :typed, :canInviteTyped) = _targets(_query);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              textInputAction: TextInputAction.send,
              onSubmitted: _inviteTyped,
              onChanged: (value) => setState(() {
                _query = value;
                _error = null;
              }),
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
              ),
            ),
            if (_query.trim().isNotEmpty && matches.isEmpty && !canInviteTyped)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No member can be invited with that username.'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            for (final member in matches)
              ListTile(
                leading: UserAvatar(initials: member.initials),
                title: Text('@${member.username}'),
                subtitle: Text(member.name),
                trailing: const Icon(Icons.person_add_alt),
                enabled: !_sending,
                onTap: () => _invite(member),
              ),
            if (canInviteTyped)
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text('Invite @$typed'),
                subtitle: const Text('Find this member by username'),
                trailing: const Icon(Icons.person_add_alt),
                enabled: !_sending,
                onTap: () => _inviteByUsername(typed),
              ),
          ],
        ),
      ),
    );
  }
}
