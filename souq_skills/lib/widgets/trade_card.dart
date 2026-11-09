import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/services/member_service.dart';

import 'status_chip.dart';

class TradeCard extends StatelessWidget {
  const TradeCard({required this.trade, super.key});

  final Trade trade;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.open(AppRoutes.tradeDetails, args: trade.id),
      leading: const Icon(Icons.swap_horiz),
      title: Text(trade.title),
      subtitle: Text('With ${MemberService().nameOf(trade.otherMemberId)}'),
      trailing: StatusChip.trade(trade.status),
    ),
  );
}
