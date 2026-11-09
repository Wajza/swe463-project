import 'package:flutter/material.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/trade_card.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  TradeStatus? _filter;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Trade history',
    children: [
      ChoiceChipRow<TradeStatus?>(
        options: const [null, ...TradeStatus.values],
        selected: _filter,
        labelOf: (status) => status?.label ?? 'All',
        onSelected: (status) => setState(() => _filter = status),
      ),
      const SizedBox(height: 14),
      LiveView(
        builder: (_) {
          final trades = TradeService().all().where(
            (trade) => _filter == null || trade.status == _filter,
          );
          if (trades.isEmpty) {
            return const EmptyState(
              title: 'Nothing here',
              message: 'No trades have this status yet.',
            );
          }
          return Column(
            children: [for (final trade in trades) TradeCard(trade: trade)],
          );
        },
      ),
    ],
  );
}
