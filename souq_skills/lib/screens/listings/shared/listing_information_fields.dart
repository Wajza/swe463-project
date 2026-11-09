import 'package:flutter/material.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/city_field.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';

import 'listing_form_controller.dart';

class ListingInformationFields extends StatefulWidget {
  const ListingInformationFields({required this.controller, super.key});

  final ListingFormController controller;

  @override
  State<ListingInformationFields> createState() =>
      _ListingInformationFieldsState();
}

class _ListingInformationFieldsState extends State<ListingInformationFields> {
  ListingFormController get _form => widget.controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTextField(
        controller: _form.wants,
        label: 'Skill you want in exchange',
        validator: AppValidators.requiredText,
      ),
      AppTextField(
        controller: _form.availability,
        label: 'Availability',
        hint: 'For example, weekday evenings',
        validator: AppValidators.requiredText,
      ),
      AppTextField(
        controller: _form.minutes,
        label: 'Session length (minutes)',
        keyboardType: TextInputType.number,
        validator: AppValidators.positiveMinutes,
      ),
      CityField(
        value: _form.city,
        onChanged: (city) => setState(() => _form.city = city),
      ),
      SettingsSwitchTile(
        title: 'Online only',
        value: _form.onlineOnly,
        onChanged: (value) => setState(() => _form.onlineOnly = value),
      ),
      SettingsSwitchTile(
        title: 'Women only',
        value: _form.womenOnly,
        onChanged: (value) => setState(() => _form.womenOnly = value),
      ),
    ],
  );
}
