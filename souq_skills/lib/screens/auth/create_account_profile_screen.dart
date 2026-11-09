import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/city_field.dart';
import 'package:souq_skills/widgets/souq_button.dart';

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
  final _name = TextEditingController();
  final _username = TextEditingController();
  String _city = AppOptions.defaultCity;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AuthService().createAccount(
      name: _name.text.trim(),
      username: _username.text.trim(),
      phone: widget.phone,
      city: _city,
    );
    context.resetTo(AppRoutes.notificationPermission);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Your profile',
    showBackButton: false,
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
            SouqButton(label: 'Create account', onPressed: _submit),
          ],
        ),
      ),
    ],
  );
}
