import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/listings/shared/listing_form_controller.dart';
import 'package:souq_skills/screens/listings/shared/listing_information_fields.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/step_progress.dart';

class ListingInformationScreen extends StatefulWidget {
  const ListingInformationScreen({required this.draft, super.key});

  final SkillListing draft;

  @override
  State<ListingInformationScreen> createState() =>
      _ListingInformationScreenState();
}

class _ListingInformationScreenState extends State<ListingInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _form = ListingFormController(widget.draft);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.open(AppRoutes.listingPreview, args: _form.applyTo(widget.draft));
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Exchange preferences',
    footer: [SouqButton(label: 'Preview', onPressed: _next)],
    children: [
      const StepProgress(step: 3, total: 4),
      Form(
        key: _formKey,
        child: ListingInformationFields(controller: _form),
      ),
    ],
  );
}
