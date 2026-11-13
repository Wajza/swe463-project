import 'identifiable.dart';

enum GroupTradeStatus {
  open('Active'),
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
    this.confirmedIds = const [],
    this.lastChangedBy = '',
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

  /// Members who confirmed the exchange happened; an online group completes
  /// once every member has.
  final List<String> confirmedIds;

  /// Who made the latest change to an online group (`'me'` for the current
  /// member), so they are not notified of their own changes. Not saved on
  /// this device.
  final String lastChangedBy;

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
    List<String>? confirmedIds,
    String? lastChangedBy,
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
    confirmedIds: confirmedIds ?? this.confirmedIds,
    lastChangedBy: lastChangedBy ?? this.lastChangedBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'ownerId': ownerId,
    'memberIds': memberIds,
    'invitedIds': invitedIds,
    'skills': skills,
    'status': status.name,
    'description': description,
    'sessionsMinutes': sessionsMinutes,
    'confirmedIds': confirmedIds,
  };

  factory GroupTrade.fromJson(Map<String, dynamic> json) => GroupTrade(
    id: json['id'] as String,
    title: json['title'] as String,
    ownerId: json['ownerId'] as String,
    memberIds: List<String>.from(json['memberIds'] as List),
    invitedIds: List<String>.from(json['invitedIds'] as List),
    skills: List<String>.from(json['skills'] as List),
    status: GroupTradeStatus.values.byName(json['status'] as String),
    description: json['description'] as String,
    sessionsMinutes: json['sessionsMinutes'] as int,
    // Missing from groups saved before confirmations existed.
    confirmedIds: List<String>.from(json['confirmedIds'] as List? ?? const []),
  );
}
