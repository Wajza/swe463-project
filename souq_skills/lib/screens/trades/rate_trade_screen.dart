import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/star_rating.dart';
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
  late bool _isRated = _service.hasRated(widget.contextId);
  final _comment = TextEditingController();
  int _stars = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit(RatingRequest request) {
    _service.submit(request, _stars, _comment.text);
    setState(() => _isRated = true);
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) return const NotFoundScreen();
    return _isRated ? _buildSaved(request) : _buildForm(request);
  }

  Widget _buildForm(RatingRequest request) => AppPage(
    title: 'Rate your experience',
    footer: [
      SouqButton(
        label: 'Submit rating',
        onPressed: _stars == 0 ? null : () => _submit(request),
      ),
    ],
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
      const SizedBox(height: 20),
      AppTextField(
        controller: _comment,
        label: 'Share your experience (optional)',
        maxLines: 4,
      ),
    ],
  );

  Widget _buildSaved(RatingRequest request) {
    final review = _service.givenFor(widget.contextId);
    return StatusPage(
      title: 'Rating saved',
      message: 'Your rating of ${request.subjectName} is now on your profile.',
      showBackButton: false,
      visual: StarRating(rating: review?.rating ?? 0, size: 44),
      actions: [
        SouqButton(
          label: 'See it on my profile',
          icon: Icons.person_outline,
          onPressed: () => context.resetTo(AppRoutes.profile),
        ),
        SouqButton(
          label: 'Back to home',
          outlined: true,
          onPressed: () => context.resetTo(AppRoutes.home),
        ),
      ],
    );
  }
}
