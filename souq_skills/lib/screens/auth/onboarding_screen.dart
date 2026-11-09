import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/souq_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SouqLogo(), const SizedBox(height: 28),
        const Text('Souq Skills', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Exchange what you know and discover useful skills from your community.', textAlign: TextAlign.center),
        const SizedBox(height: 36),
        SouqButton(label: 'Create account', onPressed: () => Navigator.pushNamed(context, AppRoutes.createAccount)),
        const SizedBox(height: 12),
        SouqButton(label: 'Sign in', outlined: true, onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn)),
      ],
    ))),
  );
}
