import 'package:flutter/material.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/loading_indicator.dart';
import 'package:souq_skills/widgets/trade_card.dart';

enum _TradeFilter {
  active('Active'),
  completed('Completed'),
  all('All');

  const _TradeFilter(this.label);
  final String label;
}

class MyTradesScreen extends StatefulWidget {
  const MyTradesScreen({super.key});

  @override
  State<MyTradesScreen> createState() => _MyTradesScreenState();
}

class _MyTradesScreenState extends State<MyTradesScreen> {
  _TradeFilter _filter = _TradeFilter.active;

  bool _matches(Trade trade) => switch (_filter) {
    _TradeFilter.active => trade.isActive,
    _TradeFilter.completed => trade.isComplete,
    _TradeFilter.all => true,
  };

  /// The trades, or why they cannot be shown yet. The empty message
  /// appears only once the trades have really loaded with none matching.
  Widget _buildTrades() {
    final service = TradeService();
    final trades = service.all().where(_matches).toList();
    final error = service.loadError;
    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListingsLoadError(
              title: 'Could not load your trades',
              message: error,
              onRetry: service.retry,
            ),
          ),
        if (service.isLoading)
          const LoadingIndicator(label: 'Loading your trades…')
        else if (trades.isEmpty && error == null)
          const EmptyState(
            title: 'Nothing here yet',
            message: 'Propose a trade on any listing to get started.',
            icon: Icons.swap_horiz,
          ),
        for (final trade in trades) TradeCard(trade: trade),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'My trades',
    children: [
      ChoiceChipRow<_TradeFilter>(
        options: _TradeFilter.values,
        selected: _filter,
        labelOf: (filter) => filter.label,
        onSelected: (filter) => setState(() => _filter = filter),
      ),
      const SizedBox(height: 14),
      LiveView(builder: (_) => _buildTrades()),
    ],
  );
}
