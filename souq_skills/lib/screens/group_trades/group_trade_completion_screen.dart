import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/widgets/completion_confirm_page.dart';

class GroupTradeCompletionScreen extends StatelessWidget {
  const GroupTradeCompletionScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) => CompletionConfirmPage(
      pageTitle: 'Complete group trade',
      title: 'Is the exchange finished?',
      summary: group.title,
      credits: GroupTradeService.completionCredits,
      onConfirm: () {
        GroupTradeService().complete(groupId);
        context.replaceWith(AppRoutes.rateTrade, args: groupId);
      },
    ),
  );
}
