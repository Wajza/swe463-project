import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/widgets/app_text_field.dart';

import 'listing_form_controller.dart';

class SkillDetailsFields extends StatelessWidget {
  const SkillDetailsFields({required this.controller, super.key});

  final ListingFormController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTextField(
        controller: controller.title,
        label: 'Listing title',
        validator: AppValidators.listingTitle,
      ),
      AppTextField(
        controller: controller.offers,
        label: 'Skill you offer',
        validator: AppValidators.requiredText,
      ),
      AppTextField(
        controller: controller.description,
        label: 'Description',
        maxLines: 4,
        validator: AppValidators.listingDescription,
      ),
    ],
  );
}
