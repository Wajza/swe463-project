import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';

enum StatusTone { positive, waiting, negative, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  factory StatusChip.trade(TradeStatus status) => StatusChip(
    label: status.label,
    tone: switch (status) {
      TradeStatus.accepted || TradeStatus.completed => StatusTone.positive,
      TradeStatus.pending => StatusTone.waiting,
      TradeStatus.declined || TradeStatus.disputed => StatusTone.negative,
      TradeStatus.cancelled => StatusTone.neutral,
    },
  );

  factory StatusChip.proposal(ProposalStatus status) => StatusChip(
    label: status.label,
    tone: switch (status) {
      ProposalStatus.accepted => StatusTone.positive,
      ProposalStatus.pending => StatusTone.waiting,
      ProposalStatus.declined => StatusTone.negative,
      ProposalStatus.countered ||
      ProposalStatus.cancelled => StatusTone.neutral,
    },
  );

  factory StatusChip.group(GroupTradeStatus status) => StatusChip(
    label: status.label,
    tone: switch (status) {
      GroupTradeStatus.open ||
      GroupTradeStatus.accepted ||
      GroupTradeStatus.completed => StatusTone.positive,
      GroupTradeStatus.negotiating => StatusTone.waiting,
      GroupTradeStatus.cancelled => StatusTone.neutral,
    },
  );

  factory StatusChip.dispute(DisputeStatus status) => StatusChip(
    label: status.label,
    tone: switch (status) {
      DisputeStatus.resolved || DisputeStatus.closed => StatusTone.positive,
      _ => StatusTone.waiting,
    },
  );

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusTone.positive => context.colors.primary,
      StatusTone.waiting => souqGold,
      StatusTone.negative => context.colors.error,
      StatusTone.neutral => context.colors.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
