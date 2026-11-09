import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_post.dart';

import 'choice_chip_row.dart';
import 'form_section.dart';
import 'listing_tag_selector.dart';
import 'multi_choice_chip_row.dart';
import 'select_field.dart';
import 'souq_button.dart';

/// One screen of selections for posting or editing a solo or group listing.
class SkillPostForm extends StatefulWidget {
  const SkillPostForm({
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.canChangeKind = false,
    super.key,
  });

  final SkillPost initial;
  final String submitLabel;
  final ValueChanged<SkillPost> onSubmit;
  final bool canChangeKind;

  @override
  State<SkillPostForm> createState() => _SkillPostFormState();
}

class _SkillPostFormState extends State<SkillPostForm> {
  late SkillPost _post = widget.initial;
  bool _showErrors = false;

  String? get _categoryError =>
      _post.category == null ? 'Choose a category' : null;

  String? get _skillsError {
    if (_post.skills.isEmpty) return 'Choose at least one skill';
    return null;
  }

  String? get _wantsError {
    if (_post.isGroup) return null;
    if (_post.wants == null) return 'Choose what you want in exchange';
    if (_post.skills.contains(_post.wants)) {
      return 'Choose a different skill from the one you offer';
    }
    return null;
  }

  void _submit() {
    if (_categoryError != null || _skillsError != null || _wantsError != null) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onSubmit(_post);
  }

  void _update(SkillPost post) => setState(() => _post = post);

  void _changeKind(ListingKind kind) =>
      _update(_post.copyWith(kind: kind, skills: const []));

  void _changeCategory(String category) =>
      _update(_post.copyWith(category: category, skills: const []));

  List<T> _withCurrent<T>(List<T> options, T current) =>
      options.contains(current) ? options : [...options, current];

  List<String> get _skillOptions {
    final skills = CategoryConfig.skillsFor(_post.category ?? '');
    return {...skills, ..._post.skills}.toList();
  }

  Widget _buildSkills() {
    final category = _post.category;
    if (category == null) return const Text('Choose a category first.');
    return _post.isGroup
        ? MultiChoiceChipRow(
            options: _skillOptions,
            selected: _post.skills,
            onChanged: (skills) => _update(_post.copyWith(skills: skills)),
          )
        : ChoiceChipRow<String?>(
            options: _skillOptions,
            selected: _post.skills.firstOrNull,
            onSelected: (skill) => _update(_post.copyWith(skills: [skill!])),
          );
  }

  List<Widget> _buildSoloFields() => [
    const SizedBox(height: 14),
    SelectField<String>(
      label: 'Skill you want in exchange',
      value: _post.wants,
      options: CategoryConfig.allSkills,
      errorText: _showErrors ? _wantsError : null,
      onChanged: (wants) => _update(_post.copyWith(wants: wants)),
    ),
    SelectField<String>(
      label: 'City',
      value: _post.city,
      options: AppOptions.cities,
      onChanged: (city) => _update(_post.copyWith(city: city)),
    ),
    FormSection(
      title: 'Availability',
      child: ChoiceChipRow<String>(
        options: _withCurrent(AppOptions.availabilities, _post.availability),
        selected: _post.availability,
        onSelected: (value) => _update(_post.copyWith(availability: value)),
      ),
    ),
    FormSection(
      title: 'Tags',
      child: ListingTagSelector(
        onlineOnly: _post.onlineOnly,
        womenOnly: _post.womenOnly,
        onChanged: (online, women) =>
            _update(_post.copyWith(onlineOnly: online, womenOnly: women)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.canChangeKind)
        FormSection(
          title: 'Type',
          child: ChoiceChipRow<ListingKind>(
            options: ListingKind.values,
            selected: _post.kind,
            labelOf: (kind) => kind.label,
            onSelected: _changeKind,
          ),
        ),
      FormSection(
        title: 'Category',
        errorText: _showErrors ? _categoryError : null,
        child: ChoiceChipRow<String?>(
          options: CategoryConfig.names,
          selected: _post.category,
          onSelected: (category) => _changeCategory(category!),
        ),
      ),
      FormSection(
        title: _post.isGroup ? 'Skills in this group' : 'Skill you offer',
        errorText: _showErrors ? _skillsError : null,
        child: _buildSkills(),
      ),
      FormSection(
        title: 'Session length',
        child: ChoiceChipRow<int>(
          options: _withCurrent(
            AppOptions.sessionLengths,
            _post.sessionsMinutes,
          ),
          selected: _post.sessionsMinutes,
          labelOf: (minutes) => '$minutes min',
          onSelected: (value) =>
              _update(_post.copyWith(sessionsMinutes: value)),
        ),
      ),
      if (!_post.isGroup) ..._buildSoloFields(),
      const SizedBox(height: 20),
      SouqButton(label: widget.submitLabel, onPressed: _submit),
    ],
  );
}
