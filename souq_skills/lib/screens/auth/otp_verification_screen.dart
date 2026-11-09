import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/app_text_field.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({required this.request, super.key});

  final OtpRequest request;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _demoCode = '123456';

  final _formKey = GlobalKey<FormState>();
  // Stands in for reading the code from the SMS automatically.
  final _code = TextEditingController(text: _demoCode);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    switch (widget.request.purpose) {
      case OtpPurpose.signIn:
        AuthService().signIn();
        context.resetTo(AppRoutes.home);
      case OtpPurpose.signUp:
        context.replaceWith(
          AppRoutes.createAccountProfile,
          args: widget.request.phone,
        );
      case OtpPurpose.changePhone:
        context.back(true);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Verify phone',
    action: SouqButton(label: 'Verify', onPressed: _verify),
    children: [
      Text('Enter the 6-digit code sent to +966 ${widget.request.phone}.'),
      const SizedBox(height: 20),
      Form(
        key: _formKey,
        child: AppTextField(
          controller: _code,
          label: 'Verification code',
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: AppValidators.otp,
        ),
      ),
    ],
  );
}
