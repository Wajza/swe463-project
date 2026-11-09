import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/location_field.dart';
import 'package:souq_skills/widgets/settings_switch_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/username_field.dart';

class CreateAccountProfileScreen extends StatefulWidget {
  const CreateAccountProfileScreen({required this.phone, super.key});

  final String phone;

  @override
  State<CreateAccountProfileScreen> createState() =>
      _CreateAccountProfileScreenState();
}

class _CreateAccountProfileScreenState
    extends State<CreateAccountProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  String _city = AppOptions.defaultCity;
  bool _keepLocationPrivate = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AuthService().createAccount(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      username: _username.text.trim(),
      phone: widget.phone,
      city: _city,
      keepLocationPrivate: _keepLocationPrivate,
    );
    context.resetTo(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'About you',
    showBackButton: false,
    action: SouqButton(label: 'Create account', onPressed: _submit),
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
            UsernameField(controller: _username),
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
    ],
  );
}
