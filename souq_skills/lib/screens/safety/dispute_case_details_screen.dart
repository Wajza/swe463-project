import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class DisputeCaseDetailsScreen extends StatelessWidget {
  const DisputeCaseDetailsScreen({required this.caseId, super.key});

  final String caseId;

  @override
  Widget build(BuildContext context) => LiveEntity<DisputeCase>(
    find: () => SafetyService().caseById(caseId),
    builder: (context, item) {
      final tradeId = item.tradeId;
      return AppPage(
        title: 'Case ${item.caseNumber}',
        footer: [
          SouqButton(
            label: 'Message support',
            onPressed: () => context.open(AppRoutes.supportMessages),
          ),
        ],
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.dispute(item.status),
          ),
          const SizedBox(height: 12),
          InfoCard(
            tiles: [
              InfoTile(label: 'Type', value: item.kind.label),
              InfoTile(label: 'Reason', value: item.reason),
              InfoTile(label: 'Details', value: item.details),
              InfoTile(
                label: 'Submitted',
                value: AppFormatters.dateTime(item.createdAt),
              ),
              if (tradeId != null)
                InfoTile(
                  label: 'Related trade',
                  value: 'View trade',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.open(AppRoutes.tradeDetails, args: tradeId),
                ),
            ],
          ),
        ],
      );
    },
  );
}
