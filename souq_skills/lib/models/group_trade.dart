enum GroupTradeStatus { open, negotiating, accepted, completed, cancelled }

class GroupTrade {
  const GroupTrade({
    required this.title,
    this.id = '',
    this.ownerId = '',
    this.memberIds = const [],
    this.skills = const [],
    this.status = GroupTradeStatus.open,
    this.description = '',
    this.sessionsMinutes = 60,
  });

  final String id;
  final String title;
  final String ownerId;
  final List<String> memberIds;
  final List<String> skills;
  final GroupTradeStatus status;
  final String description;
  final int sessionsMinutes;
}
