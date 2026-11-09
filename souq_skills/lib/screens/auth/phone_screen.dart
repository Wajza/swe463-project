import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/souq_button.dart';

/// One entry point for both new and returning members.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    context.open(
      AppRoutes.otpVerification,
      args: OtpRequest(
        phone: phone,
        purpose: AuthService().isKnownPhone(phone)
            ? OtpPurpose.signIn
            : OtpPurpose.signUp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Your phone number',
    action: SouqButton(label: 'Continue', onPressed: _continue),
    children: [
      Form(
        key: _formKey,
        child: AppTextField(
          controller: _phone,
          label: 'Phone number',
          hint: '5XXXXXXXX',
          prefixText: '+966 ',
          keyboardType: TextInputType.phone,
          validator: AppValidators.phone,
        ),
      ),
      const Text(
        'Demo account: 501234567. Any other number creates a new one.',
      ),
    ],
  );
}
