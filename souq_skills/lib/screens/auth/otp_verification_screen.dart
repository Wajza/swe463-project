import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});
  @override State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}
class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final controller = TextEditingController();
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify phone')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('Enter the 6-digit code sent to your phone.'),
      const SizedBox(height: 20),
      TextField(controller: controller, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'Verification code', errorText: error)),
      const Spacer(),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: () async {
        final valid = await AuthService().verifyOtp(controller.text);
        if (!context.mounted) return;
        if (!valid) { setState(() => error = 'Enter a valid 6-digit code'); return; }
        final returningUser =
            (ModalRoute.of(context)?.settings.arguments as Map?)?['returningUser'] == true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          returningUser ? AppRoutes.home : AppRoutes.createAccountProfile,
          (route) => false,
        );
      }, child: const Text('Verify'))),
    ])),
  );
}
