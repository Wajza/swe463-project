import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/phone_entry_form.dart';

class ReturningUserSignInScreen extends StatelessWidget {
  const ReturningUserSignInScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Welcome back',
    body: PhoneEntryForm(
      helpText: 'Demo: any valid number and any 6-digit code will sign you in.',
      onSubmit: (phone) {
        if (!AuthService().hasAccount) {
          return 'No account found. Please create one first.';
        }
        context.open(
          AppRoutes.otpVerification,
          args: OtpRequest(phone: phone, isReturningUser: true),
        );
        return null;
      },
    ),
  );
}
