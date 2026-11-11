import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/status_chip.dart';

class SafetyCentreScreen extends StatefulWidget {
  const SafetyCentreScreen({super.key});

  @override
  State<SafetyCentreScreen> createState() => _SafetyCentreScreenState();
}

class _SafetyCentreScreenState extends State<SafetyCentreScreen> {
  @override
  void initState() {
    super.initState();
    // The signed-in account's own reports, after the first frame.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SafetyService().refreshReports(),
    );
  }

  List<Widget> _buildCases(BuildContext context, ReportsLoadState load) {
    final service = SafetyService();
    // Until loaded for this account, the cases may be another account's.
    if (!service.hasCurrentReports) {
      if (load.isFailed) return const [];
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final cases = service.cases();
    if (cases.isEmpty) {
      return const [
        EmptyState(
          title: 'No reports yet',
          message: 'Reports, complaints and disputes you send appear here.',
          icon: Icons.flag_outlined,
        ),
      ];
    }
    return [
      const SectionHeader(title: 'My cases'),
      for (final item in cases)
        Card(
          child: ListTile(
            onTap: () =>
                context.open(AppRoutes.disputeCaseDetails, args: item.id),
            title: Text(item.caseNumber),
            subtitle: Text(
              '${item.kind.label} • ${item.reason}\n'
              '${AppFormatters.dateTime(item.createdAt)}',
            ),
            isThreeLine: true,
            trailing: StatusChip.dispute(item.status),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'Safety centre',
      body: ValueListenableBuilder<ReportsLoadState>(
        valueListenable: SafetyService.reportsState,
        builder: (context, load, _) => RefreshIndicator(
          onRefresh: SafetyService().refreshReports,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const InfoCard(
                tiles: [
                  InfoTile(
                    label: 'Meet safely',
                    value: 'Choose public places for in-person sessions.',
                    icon: Icons.place_outlined,
                  ),
                  InfoTile(
                    label: 'Protect your details',
                    value: 'Keep personal information inside the app.',
                    icon: Icons.lock_outline,
                  ),
                  InfoTile(
                    label: 'Speak up',
                    value: 'Report a member from their profile menu.',
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
              if (load.isFailed)
                ListingsLoadError(
                  title: 'Could not load your reports',
                  message: load.error!,
                  onRetry: SafetyService().refreshReports,
                ),
              ..._buildCases(context, load),
            ],
          ),
        ),
      ),
    ),
  );
}
