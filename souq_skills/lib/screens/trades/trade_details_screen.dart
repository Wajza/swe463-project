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
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class TradeDetailsScreen extends StatelessWidget {
  const TradeDetailsScreen({required this.tradeId, super.key});

  final String tradeId;

  List<Widget> _actions(BuildContext context, Trade trade, bool hasSession) =>
      switch (trade.status) {
        TradeStatus.pending => [
          SouqButton(
            label: 'View proposal',
            onPressed: () =>
                context.open(AppRoutes.proposalDetails, args: trade.proposalId),
          ),
        ],
        TradeStatus.accepted when !hasSession => [
          SouqButton(
            label: 'Schedule session',
            icon: Icons.event_outlined,
            onPressed: () =>
                context.open(AppRoutes.scheduleSession, args: tradeId),
          ),
        ],
        TradeStatus.accepted => [
          SouqButton(
            label: 'Mark as complete',
            icon: Icons.task_alt,
            onPressed: () =>
                context.open(AppRoutes.tradeCompletion, args: tradeId),
          ),
          SouqButton(
            label: 'Reschedule',
            outlined: true,
            onPressed: () =>
                context.open(AppRoutes.scheduleSession, args: tradeId),
          ),
        ],
        TradeStatus.completed when !ReviewService().hasRated(tradeId) => [
          SouqButton(
            label: 'Rate this experience',
            icon: Icons.star_outline,
            onPressed: () => context.open(AppRoutes.rateTrade, args: tradeId),
          ),
        ],
        TradeStatus.disputed => [
          SouqButton(
            label: 'View case',
            onPressed: () => context.open(
              AppRoutes.disputeCaseDetails,
              args: SafetyService().caseForTrade(tradeId)?.id,
            ),
          ),
        ],
        _ => const [],
      };

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
          PopupMenuButton<String>(
            onSelected: (route) => context.open(route, args: tradeId),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: AppRoutes.reportTrade,
                child: Text('Report trade'),
              ),
              if (trade.status == TradeStatus.accepted)
                const PopupMenuItem(
                  value: AppRoutes.disputeTrade,
                  child: Text('Open a dispute'),
                ),
            ],
          ),
        ],
        footer: _actions(context, trade, session != null),
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
                value: trade.offeredSkill,
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
          const SectionHeader(title: 'Trading with'),
          MemberTile(memberId: trade.otherMemberId),
          SouqButton(
            label: 'Open chat',
            outlined: true,
            icon: Icons.chat_outlined,
            onPressed: () =>
                context.open(AppRoutes.chat, args: trade.otherMemberId),
          ),
          const SizedBox(height: 10),
          SouqButton(
            label: 'Track status',
            outlined: true,
            icon: Icons.timeline,
            onPressed: () => context.open(AppRoutes.tradeStatus, args: tradeId),
          ),
          if (myReview != null) ...[
            const SectionHeader(title: 'Your rating'),
            ReviewCard(review: myReview),
          ],
        ],
      );
    },
  );
}
