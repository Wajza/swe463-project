import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/trade_session_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/proposal_card.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';
import 'package:souq_skills/widgets/status_timeline.dart';

class TradeDetailsScreen extends StatelessWidget {
  const TradeDetailsScreen({required this.tradeId, super.key});

  final String tradeId;

  void _complete(BuildContext context) {
    TradeService().complete(tradeId);
    context.replaceWith(AppRoutes.rateTrade, args: tradeId);
  }

  /// The one next step for the trade's current status.
  Widget? _nextStep(BuildContext context, Trade trade, bool hasSession) =>
      switch (trade.status) {
        TradeStatus.accepted when !hasSession => SouqButton(
          label: 'Schedule session',
          icon: Icons.event_outlined,
          onPressed: () =>
              context.open(AppRoutes.scheduleSession, args: tradeId),
        ),
        TradeStatus.accepted => SouqButton(
          label: 'Mark as complete',
          icon: Icons.task_alt,
          onPressed: () => _complete(context),
        ),
        TradeStatus.completed when !ReviewService().hasRated(tradeId) =>
          SouqButton(
            label: 'Rate this experience',
            icon: Icons.star_outline,
            onPressed: () => context.open(AppRoutes.rateTrade, args: tradeId),
          ),
        TradeStatus.disputed => SouqButton(
          label: 'View case',
          onPressed: () => context.open(
            AppRoutes.disputeCaseDetails,
            args: SafetyService().caseForTrade(tradeId)?.id,
          ),
        ),
        _ => null,
      };

  List<MenuAction> _menu(BuildContext context, Trade trade, bool hasSession) =>
      [
        if (trade.status == TradeStatus.accepted && hasSession)
          MenuAction(
            'Reschedule',
            () => context.open(AppRoutes.scheduleSession, args: tradeId),
          ),
        MenuAction(
          'Report trade',
          () => context.open(AppRoutes.reportTrade, args: tradeId),
        ),
        if (trade.status == TradeStatus.accepted)
          MenuAction(
            'Open a dispute',
            () => context.open(AppRoutes.disputeTrade, args: tradeId),
          ),
      ];

  List<InfoTile> _sessionTiles(TradeSession session) => [
    InfoTile(
      label: 'Session',
      value: AppFormatters.dateTime(session.scheduledAt),
      icon: Icons.event_outlined,
    ),
    InfoTile(
      label: 'Method',
      value: session.locationOrLink.isEmpty
          ? session.method
          : '${session.method} • ${session.locationOrLink}',
      icon: Icons.place_outlined,
    ),
  ];

  List<TimelineEntry> _timeline(Trade trade) => [
    const TimelineEntry('Proposal sent', isDone: true),
    TimelineEntry(
      'Proposal accepted',
      isDone:
          trade.status == TradeStatus.accepted ||
          trade.isComplete ||
          trade.status == TradeStatus.disputed,
    ),
    TimelineEntry('Session scheduled', isDone: trade.sessionId != null),
    TimelineEntry('Exchange completed', isDone: trade.isComplete),
    TimelineEntry(
      'Experience rated',
      isDone: ReviewService().hasRated(tradeId),
    ),
  ];

  @override
  Widget build(BuildContext context) => LiveEntity<Trade>(
    find: () => TradeService().byId(tradeId),
    builder: (context, trade) {
      final session = TradeSessionService().byId(trade.sessionId);
      final myReview = ReviewService().givenFor(tradeId);
      final proposal = ProposalService().byId(trade.proposalId);
      return AppPage(
        title: 'Trade details',
        actions: [
          IconButton(
            tooltip: 'Open chat',
            onPressed: () =>
                context.open(AppRoutes.chat, args: trade.otherMemberId),
            icon: const Icon(Icons.chat_outlined),
          ),
          OverflowMenu(items: _menu(context, trade, session != null)),
        ],
        action: _nextStep(context, trade, session != null),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.trade(trade.status),
          ),
          const SizedBox(height: 12),
          InfoCard(
            tiles: [
              InfoTile(
                label: 'You give',
                value: trade.givenLabel,
                icon: Icons.volunteer_activism_outlined,
              ),
              InfoTile(
                label: 'You receive',
                value: trade.requestedSkill,
                icon: Icons.swap_horiz,
              ),
              InfoTile(
                label: 'Session length',
                value: '${trade.sessionsMinutes} minutes',
                icon: Icons.timer_outlined,
              ),
              if (proposal != null && session == null)
                InfoTile(
                  label: 'Delivery',
                  value: proposal.deliveryMethod,
                  icon: Icons.place_outlined,
                ),
              ...?(session == null ? null : _sessionTiles(session)),
            ],
          ),
          if (proposal != null && trade.status == TradeStatus.pending)
            ProposalCard(proposal: proposal),
          const SectionHeader(title: 'Trading with'),
          MemberTile(memberId: trade.otherMemberId),
          if (myReview != null) ...[
            const SectionHeader(title: 'Your rating'),
            ReviewCard(review: myReview),
          ],
          const SectionHeader(title: 'Progress'),
          StatusTimeline(entries: _timeline(trade)),
        ],
      );
    },
  );
}
