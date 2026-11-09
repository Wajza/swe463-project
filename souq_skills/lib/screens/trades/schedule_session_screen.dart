import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/trade_session_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/form_section.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({required this.tradeId, super.key});

  final String tradeId;

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  late final _trade = TradeService().byId(widget.tradeId);
  late final _existing = TradeSessionService().byId(_trade?.sessionId);
  late DateTime _scheduledAt = _existing?.scheduledAt ?? _defaultTime();
  late String _method = _existing?.method ?? AppOptions.deliveryMethods.first;
  late String _place =
      AppOptions.meetingPlaces.contains(_existing?.locationOrLink)
      ? _existing!.locationOrLink
      : AppOptions.meetingPlaces.first;

  bool get _isInPerson => _method == AppOptions.deliveryMethods.last;

  DateTime _defaultTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 18);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(now) ? now : _scheduledAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(
      () => _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(
      () => _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _save() {
    if (_scheduledAt.isBefore(DateTime.now())) {
      context.showMessage('Choose a time in the future');
      return;
    }
    TradeSessionService().schedule(
      tradeId: widget.tradeId,
      scheduledAt: _scheduledAt,
      method: _method,
      locationOrLink: _isInPerson ? _place : '',
      notes: '',
    );
    context.back();
    context.showMessage('Session scheduled');
  }

  @override
  Widget build(BuildContext context) {
    if (_trade == null) return const NotFoundScreen();
    return AppPage(
      title: 'Schedule session',
      action: SouqButton(label: 'Save session', onPressed: _save),
      children: [
        InfoCard(
          tiles: [
            InfoTile(
              label: 'Date',
              value: AppFormatters.date(_scheduledAt),
              icon: Icons.calendar_today_outlined,
              trailing: const Icon(Icons.expand_more),
              onTap: _pickDate,
            ),
            InfoTile(
              label: 'Time',
              value: AppFormatters.time(_scheduledAt),
              icon: Icons.access_time,
              trailing: const Icon(Icons.expand_more),
              onTap: _pickTime,
            ),
          ],
        ),
        FormSection(
          title: 'Method',
          child: ChoiceChipRow<String>(
            options: AppOptions.deliveryMethods,
            selected: _method,
            onSelected: (value) => setState(() => _method = value),
          ),
        ),
        if (_isInPerson)
          FormSection(
            title: 'Meeting place',
            child: ChoiceChipRow<String>(
              options: AppOptions.meetingPlaces,
              selected: _place,
              onSelected: (value) => setState(() => _place = value),
            ),
          ),
      ],
    );
  }
}
