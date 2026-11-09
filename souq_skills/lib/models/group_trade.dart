import 'identifiable.dart';

enum GroupTradeStatus {
  open('Open'),
  negotiating('Negotiating'),
  accepted('Accepted'),
  completed('Completed'),
  cancelled('Cancelled');

  const GroupTradeStatus(this.label);
  final String label;
}

class GroupTrade implements Identifiable {
  const GroupTrade({
    required this.title,
    this.id = '',
    this.ownerId = '',
    this.memberIds = const [],
    this.invitedIds = const [],
    this.skills = const [],
    this.status = GroupTradeStatus.open,
    this.description = '',
    this.sessionsMinutes = 60,
  });

  @override
  final String id;
  final String title;
  final String ownerId;
  final List<String> memberIds;
  final List<String> invitedIds;
  final List<String> skills;
  final GroupTradeStatus status;
  final String description;
  final int sessionsMinutes;

  bool get isCompleted => status == GroupTradeStatus.completed;

  GroupTrade copyWith({
    String? id,
    String? title,
    String? ownerId,
    List<String>? memberIds,
    List<String>? invitedIds,
    List<String>? skills,
    GroupTradeStatus? status,
    String? description,
    int? sessionsMinutes,
  }) => GroupTrade(
    id: id ?? this.id,
    title: title ?? this.title,
    ownerId: ownerId ?? this.ownerId,
    memberIds: memberIds ?? this.memberIds,
    invitedIds: invitedIds ?? this.invitedIds,
    skills: skills ?? this.skills,
    status: status ?? this.status,
    description: description ?? this.description,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
  );
}
