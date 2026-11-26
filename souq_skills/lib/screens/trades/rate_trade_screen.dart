import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/load_status.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/form_section.dart';
import 'package:souq_skills/widgets/multi_choice_chip_row.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/star_rating_input.dart';
import 'package:souq_skills/widgets/status_page.dart';

class RateTradeScreen extends StatefulWidget {
  const RateTradeScreen({required this.contextId, super.key});

  /// The id of the finished trade or group trade being rated.
  final String contextId;

  @override
  State<RateTradeScreen> createState() => _RateTradeScreenState();
}

class _RateTradeScreenState extends State<RateTradeScreen> {
  final _service = ReviewService();

  /// What is being rated, kept once found so the member rated never
  /// changes while the form is filled in. Looked for again until then: the
  /// trade or group may still be loading, as when opened from a
  /// notification just after signing in.
  RatingRequest? _request;
  RatingRequest? _findRequest() =>
      _request ??= _service.requestFor(widget.contextId);

  /// Trades, then group trades: this page is for either, so it is loading,
  /// or failed, while the trades are, and otherwise while the groups are.
  static LoadStatus _loadStatus() {
    final trades = TradeService().loadStatus;
    if (trades.isLoading || trades.error != null) return trades;
    return GroupTradeService().loadStatus;
  }

  List<String> _tags = const [];
  int _stars = 0;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The member's own ratings, so one given on another device is known.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _service.refreshReviews(const [User.currentUserId]),
    );
  }

  /// Rated this member for this exchange before.
  bool _alreadyRated(RatingRequest request) =>
      _service.hasRated(widget.contextId, subjectId: request.subjectId);

  Future<void> _submit(RatingRequest request) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.submitRating(request, _stars, _tags);
    } on ReviewException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
      return;
    }
    if (!mounted) return;
    _saved = true;
    context.resetTo(AppRoutes.profile);
    context.showMessage('Rating saved to your profile');
  }

  /// While what is rated is missing, [LiveEntity] shows loading, a failure
  /// with Try again, or, once everything has loaded, Page not found.
  @override
  Widget build(BuildContext context) => LiveEntity<RatingRequest>(
    find: _findRequest,
    loadStatus: _loadStatus,
    builder: (context, request) => ValueListenableBuilder(
      valueListenable: ReviewService.loadStates,
      builder: (context, _, _) {
        if (!_saved && !_saving && _alreadyRated(request)) {
          return StatusPage(
            title: 'Already rated',
            message:
                'Your rating of ${request.subjectName} is on your profile.',
            action: SouqButton(
              label: 'See it on my profile',
              onPressed: () => context.resetTo(AppRoutes.profile),
            ),
          );
        }
        return _form(context, request);
      },
    ),
  );

  Widget _form(BuildContext context, RatingRequest request) => AppPage(
    title: 'Rate your experience',
    action: SouqButton(
      label: _saving
          ? 'Saving…'
          : _error != null
          ? 'Try again'
          : 'Submit rating',
      onPressed: _stars == 0 || _saving ? null : () => _submit(request),
    ),
    children: [
      Text(
        'How was your exchange with ${request.subjectName}?',
        textAlign: TextAlign.center,
        style: context.textStyles.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(request.skillTitle, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      IgnorePointer(
        ignoring: _saving,
        child: StarRatingInput(
          stars: _stars,
          onChanged: (stars) => setState(() => _stars = stars),
        ),
      ),
      FormSection(
        title: 'What went well? (optional)',
        child: IgnorePointer(
          ignoring: _saving,
          child: MultiChoiceChipRow(
            options: AppOptions.ratingTags,
            selected: _tags,
            onChanged: (tags) => setState(() => _tags = tags),
          ),
        ),
      ),
      if (_error case final error?)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '$error Your rating was not saved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.error),
          ),
        ),
    ],
  );
}
