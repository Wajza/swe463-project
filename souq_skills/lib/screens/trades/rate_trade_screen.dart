import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/rating_request.dart';
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
  late final bool _alreadyRated = _service.hasRated(widget.contextId);
  List<String> _tags = const [];
  int _stars = 0;

  void _submit(RatingRequest request) {
    _service.submit(request, _stars, _tags.join(' • '));
    context.resetTo(AppRoutes.profile);
    context.showMessage('Rating saved to your profile');
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) return const NotFoundScreen();
    if (_alreadyRated) {
      return StatusPage(
        title: 'Already rated',
        message: 'Your rating of ${request.subjectName} is on your profile.',
        action: SouqButton(
          label: 'See it on my profile',
          onPressed: () => context.resetTo(AppRoutes.profile),
        ),
      );
    }
    return AppPage(
      title: 'Rate your experience',
      action: SouqButton(
        label: 'Submit rating',
        onPressed: _stars == 0 ? null : () => _submit(request),
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
        StarRatingInput(
          stars: _stars,
          onChanged: (stars) => setState(() => _stars = stars),
        ),
        FormSection(
          title: 'What went well? (optional)',
          child: MultiChoiceChipRow(
            options: AppOptions.ratingTags,
            selected: _tags,
            onChanged: (tags) => setState(() => _tags = tags),
          ),
        ),
      ],
    );
  }
}
