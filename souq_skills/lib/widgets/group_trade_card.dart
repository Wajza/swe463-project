import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';

import 'status_chip.dart';

class GroupTradeCard extends StatelessWidget {
  const GroupTradeCard({required this.group, super.key});

  final GroupTrade group;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.open(AppRoutes.groupTradeDetails, args: group.id),
      leading: const Icon(Icons.groups_outlined),
      title: Text(group.title),
      subtitle: Text('${group.memberIds.length} members'),
      trailing: StatusChip.group(group.status),
    ),
  );
}
