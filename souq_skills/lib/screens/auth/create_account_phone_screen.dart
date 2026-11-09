import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/services/auth_service.dart';

class CreateAccountPhoneScreen extends StatefulWidget {
  const CreateAccountPhoneScreen({super.key});
  @override State<CreateAccountPhoneScreen> createState() => _CreateAccountPhoneScreenState();
}
class _CreateAccountPhoneScreenState extends State<CreateAccountPhoneScreen> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      TextField(controller: controller, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
      const Spacer(),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: () async {
        final sent = await AuthService().requestOtp(controller.text);
        if (!context.mounted || !sent) return;
        Navigator.pushNamed(context, AppRoutes.otpVerification,
            arguments: const {'returningUser': false});
      }, child: const Text('Continue'))),
    ])),
  );
}
