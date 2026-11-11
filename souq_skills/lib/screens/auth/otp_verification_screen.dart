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

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({required this.request, super.key});

  final OtpRequest request;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  // Filled in when the code is already known, e.g. read from the SMS.
  final _code = TextEditingController(text: AuthService().suggestedCode);
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _code.text.trim();
    setState(() => _verifying = true);
    try {
      if (widget.request.purpose == OtpPurpose.changePhone) {
        await AuthService().verifyNewPhone(code);
        if (mounted) context.back(true);
        return;
      }
      if (widget.request.purpose == OtpPurpose.confirmIdentity) {
        // Stays signed in, and on this screen, if the code is wrong.
        await AuthService().confirmIdentity(code);
        if (mounted) context.back(true);
        return;
      }
      // New and returning members verify the same way; the saved profile
      // decides where they go next.
      final hasProfile = await AuthService().verifyCode(code);
      if (!mounted) return;
      if (hasProfile) {
        context.resetTo(AppRoutes.home);
      } else {
        context.replaceWith(
          AppRoutes.createAccountProfile,
          args: widget.request.phone,
        );
      }
    } on AuthException catch (error) {
      if (mounted) context.showMessage(error.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Verify phone',
    action: SouqButton(
      label: _verifying ? 'Verifying…' : 'Verify',
      onPressed: _verifying ? null : _verify,
    ),
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
