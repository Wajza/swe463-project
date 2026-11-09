import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/completion_confirm_page.dart';

class TradeCompletionScreen extends StatelessWidget {
  const TradeCompletionScreen({required this.tradeId, super.key});

  final String tradeId;

  @override
  Widget build(BuildContext context) => LiveEntity<Trade>(
    find: () => TradeService().byId(tradeId),
    builder: (context, trade) => CompletionConfirmPage(
      pageTitle: 'Complete trade',
      title: 'Did the exchange happen?',
      summary: trade.title,
      credits: TradeService.completionCredits,
      onConfirm: () {
        TradeService().complete(tradeId);
        context.replaceWith(AppRoutes.rateTrade, args: tradeId);
      },
    ),
  );
}
