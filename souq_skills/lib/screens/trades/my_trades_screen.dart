import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/trade_card.dart';

class MyTradesScreen extends StatelessWidget {
  const MyTradesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final trades = TradeService().active();
      final actions = [
        IconButton(
          tooltip: 'Trade history',
          onPressed: () => context.open(AppRoutes.tradeHistory),
          icon: const Icon(Icons.history),
        ),
      ];
      return AppPage(
        emptyState: EmptyState(
          title: 'No active trades',
          message: 'Propose a trade on any listing to get started.',
          icon: Icons.swap_horiz,
          action: SouqButton(
            label: 'Browse skills',
            onPressed: () => context.resetTo(AppRoutes.home),
          ),
        ),
        title: 'My trades',
        actions: actions,
        children: [for (final trade in trades) TradeCard(trade: trade)],
      );
    },
  );
}
