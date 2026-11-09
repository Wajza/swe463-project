import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/location_field.dart';
import 'package:souq_skills/widgets/select_field.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/username_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profile = ProfileService();
  late final _user = _profile.currentUser;
  late final _firstName = TextEditingController(text: _user.firstName);
  late final _lastName = TextEditingController(text: _user.lastName);
  late final _username = TextEditingController(text: _user.username);
  late final _phone = TextEditingController(text: _user.phone);
  late final _bio = TextEditingController(text: _user.bio);
  late String _city = _user.city;
  late String? _availability = _user.availability.isEmpty
      ? null
      : _user.availability;
  late bool _keepLocationPrivate = !_profile.settings.locationVisible;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// A new phone number only counts once its code has been verified.
  Future<bool> _verifyPhoneIfChanged(String phone) async {
    if (phone == _user.phone) return true;
    final verified = await context.open(
      AppRoutes.otpVerification,
      args: OtpRequest(phone: phone, purpose: OtpPurpose.changePhone),
    );
    return verified == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    if (!await _verifyPhoneIfChanged(phone) || !mounted) return;
    _profile.updateProfile(
      _user.copyWith(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        username: _username.text.trim(),
        phone: phone,
        bio: _bio.text.trim(),
        availability: _availability,
        city: _city,
      ),
    );
    _profile.updateSettings(
      (current) => current.copyWith(locationVisible: !_keepLocationPrivate),
    );
    context.back();
    context.showMessage('Profile updated');
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Edit profile',
    action: SouqButton(label: 'Save', onPressed: _save),
    children: [
      Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _firstName,
              label: 'First name',
              validator: AppValidators.personName,
            ),
            AppTextField(
              controller: _lastName,
              label: 'Last name',
              validator: AppValidators.personName,
            ),
            UsernameField(controller: _username, isEditingOwn: true),
            AppTextField(
              controller: _phone,
              label: 'Phone number',
              prefixText: '+966 ',
              keyboardType: TextInputType.phone,
              validator: AppValidators.phone,
            ),
            AppTextField(
              controller: _bio,
              label: 'Bio (optional)',
              maxLines: 3,
            ),
          ],
        ),
      ),
      LocationField(
        value: _city,
        onChanged: (city) => setState(() => _city = city),
      ),
      SettingsSwitchTile(
        title: 'Keep my location private',
        value: _keepLocationPrivate,
        onChanged: (value) => setState(() => _keepLocationPrivate = value),
      ),
      SelectField<String>(
        label: 'Availability',
        value: _availability,
        options: AppOptions.availabilities,
        onChanged: (value) => setState(() => _availability = value),
      ),
    ],
  );
}
