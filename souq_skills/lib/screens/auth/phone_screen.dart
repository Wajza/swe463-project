import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
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
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    setState(() => _sending = true);
    try {
      await AuthService().sendCode(phone);
    } on AuthException catch (error) {
      if (mounted) context.showMessage(error.message);
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;
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
    action: SouqButton(
      label: _sending ? 'Sending code…' : 'Continue',
      onPressed: _sending ? null : _continue,
    ),
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
