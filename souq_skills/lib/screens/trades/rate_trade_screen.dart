import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/review_service.dart';
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
  late final RatingRequest? _request = _service.requestFor(widget.contextId);
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

  /// Rated this exchange, or online this member, before.
  bool _alreadyRated(RatingRequest request) =>
      _service.hasRated(widget.contextId) ||
      _service.hasRatedMember(request.subjectId);

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

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) return const NotFoundScreen();
    return ValueListenableBuilder(
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
    );
  }

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
