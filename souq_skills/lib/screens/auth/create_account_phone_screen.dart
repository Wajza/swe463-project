import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/phone_entry_form.dart';

class CreateAccountPhoneScreen extends StatelessWidget {
  const CreateAccountPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Create account',
    body: PhoneEntryForm(
      onSubmit: (phone) {
        context.open(
          AppRoutes.otpVerification,
          args: OtpRequest(phone: phone, isReturningUser: false),
        );
        return null;
      },
    ),
  );
}
