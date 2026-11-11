import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/member_service.dart';
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
import 'package:souq_skills/widgets/trade_action.dart';

class TradeDetailsScreen extends StatelessWidget {
  const TradeDetailsScreen({required this.tradeId, super.key});

  final String tradeId;

  Future<void> _complete(BuildContext context, Trade trade) async {
    var completed = false;
    final saved = await context.runTradeAction(
      () async => completed = await TradeService().complete(tradeId),
    );
    if (!saved || !context.mounted) return;
    if (completed) {
      context.replaceWith(AppRoutes.rateTrade, args: tradeId);
    } else {
      context.showMessage(_waitingMessage(trade));
    }
  }

  /// A trade with a real member completes once both members confirmed.
  static String _waitingMessage(Trade trade) =>
      'Waiting for ${MemberService().nameOf(trade.otherMemberId)} to confirm';

  /// The one next step for the trade's current status.
  Widget? _nextStep(
    BuildContext context,
    Trade trade,
    bool hasSession,
  ) => switch (trade.status) {
    TradeStatus.accepted when !hasSession => SouqButton(
      label: 'Schedule session',
      icon: Icons.event_outlined,
      onPressed: () => context.open(AppRoutes.scheduleSession, args: tradeId),
    ),
    TradeStatus.accepted when trade.confirmedByMe => SouqButton(
      label: _waitingMessage(trade),
      icon: Icons.hourglass_empty,
      onPressed: null,
    ),
    TradeStatus.accepted => SouqButton(
      label: trade.confirmedByOther ? 'Confirm completion' : 'Mark as complete',
      icon: Icons.task_alt,
      onPressed: () => _complete(context, trade),
    ),
    TradeStatus.completed when !ReviewService().hasRated(tradeId) => SouqButton(
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

  /// Rescheduling is the pencil on the session card, not in this menu.
  List<MenuAction> _menu(BuildContext context, Trade trade) => [
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

  List<InfoTile> _sessionTiles(
    BuildContext context,
    Trade trade,
    TradeSession session,
  ) => [
    InfoTile(
      label: 'Session',
      value: AppFormatters.dateTime(session.scheduledAt),
      icon: Icons.event_outlined,
      // The way to reschedule an accepted trade's session.
      trailing: trade.status == TradeStatus.accepted
          ? IconButton(
              tooltip: 'Reschedule',
              icon: const Icon(Icons.edit_outlined),
              color: context.colors.primary,
              onPressed: () =>
                  context.open(AppRoutes.scheduleSession, args: tradeId),
            )
          : null,
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
          OverflowMenu(items: _menu(context, trade)),
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
              ...?(session == null
                  ? null
                  : _sessionTiles(context, trade, session)),
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
