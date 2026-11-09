import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ReturningUserSignInScreen extends StatefulWidget {
  const ReturningUserSignInScreen({super.key});
  @override State<ReturningUserSignInScreen> createState() => _ReturningUserSignInScreenState();
}
class _ReturningUserSignInScreenState extends State<ReturningUserSignInScreen> {
  final phoneController = TextEditingController();
  String? error; bool loading = false;
  @override void dispose() { phoneController.dispose(); super.dispose(); }
  Future<void> continueFlow() async {
    final validation = AppValidators.phone(phoneController.text);
    if (validation != null) { setState(() => error = validation); return; }
    setState(() { loading = true; error = null; });
    final sent = await AuthService().requestOtp(phoneController.text.trim());
    if (!mounted) return;
    setState(() => loading = false);
    if (!sent) { setState(() => error = 'Could not send verification code.'); return; }
    Navigator.pushNamed(context, AppRoutes.otpVerification);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome back')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone number', errorText: error)),
      const Spacer(),
      SouqButton(label: loading ? 'Sending...' : 'Continue', onPressed: loading ? null : continueFlow),
    ])),
  );
}
