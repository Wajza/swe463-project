import 'package:flutter/material.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/status_chip.dart';
import 'package:souq_skills/widgets/status_timeline.dart';

class TradeStatusScreen extends StatelessWidget {
  const TradeStatusScreen({required this.tradeId, super.key});

  final String tradeId;

  @override
  Widget build(BuildContext context) => LiveEntity<Trade>(
    find: () => TradeService().byId(tradeId),
    builder: (context, trade) {
      final wasAccepted =
          trade.status == TradeStatus.accepted ||
          trade.status == TradeStatus.completed ||
          trade.status == TradeStatus.disputed;
      return AppPage(
        title: 'Trade status',
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.trade(trade.status),
          ),
          const SizedBox(height: 12),
          StatusTimeline(
            entries: [
              const TimelineEntry('Proposal sent', isDone: true),
              TimelineEntry('Proposal accepted', isDone: wasAccepted),
              TimelineEntry(
                'Session scheduled',
                isDone: trade.sessionId != null,
              ),
              TimelineEntry('Exchange completed', isDone: trade.isComplete),
              TimelineEntry(
                'Experience rated',
                isDone: ReviewService().hasRated(tradeId),
              ),
            ],
          ),
        ],
      );
    },
  );
}
