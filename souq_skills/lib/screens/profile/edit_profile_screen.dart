import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/city_field.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = ProfileService().currentUser;
  late final _name = TextEditingController(text: _user.name);
  late final _username = TextEditingController(text: _user.username);
  late final _bio = TextEditingController(text: _user.bio);
  late final _availability = TextEditingController(text: _user.availability);
  late String _city = _user.city;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _availability.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ProfileService().updateProfile(
      _user.copyWith(
        name: _name.text.trim(),
        username: _username.text.trim(),
        bio: _bio.text.trim(),
        availability: _availability.text.trim(),
        city: _city,
      ),
    );
    context.back();
    context.showMessage('Profile updated');
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Edit profile',
    footer: [SouqButton(label: 'Save', onPressed: _save)],
    children: [
      Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _name,
              label: 'Full name',
              validator: AppValidators.requiredText,
            ),
            AppTextField(
              controller: _username,
              label: 'Username',
              validator: AppValidators.username,
            ),
            CityField(
              value: _city,
              onChanged: (city) => setState(() => _city = city),
            ),
            AppTextField(controller: _bio, label: 'Bio', maxLines: 3),
            AppTextField(controller: _availability, label: 'Availability'),
          ],
        ),
      ),
    ],
  );
}
