import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/group_trade_form.dart';

class CreateGroupTradeScreen extends StatelessWidget {
  const CreateGroupTradeScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Create group trade',
    children: [
      GroupTradeForm(
        initial: const GroupTrade(title: ''),
        submitLabel: 'Create group',
        onSubmit: (draft) {
          final group = GroupTradeService().create(draft);
          context.replaceWith(AppRoutes.groupTradeDetails, args: group.id);
        },
      ),
    ],
  );
}
