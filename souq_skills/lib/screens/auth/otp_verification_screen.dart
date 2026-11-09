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
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.request.isReturningUser) {
      AuthService().signIn();
      context.resetTo(AppRoutes.home);
    } else {
      context.replaceWith(
        AppRoutes.createAccountProfile,
        args: widget.request.phone,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Verify phone',
    body: Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter the 6-digit code sent to your phone.'),
            const SizedBox(height: 20),
            AppTextField(
              controller: _code,
              label: 'Verification code',
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: AppValidators.otp,
            ),
            const Spacer(),
            SouqButton(label: 'Verify', onPressed: _verify),
          ],
        ),
      ),
    ),
  );
}
