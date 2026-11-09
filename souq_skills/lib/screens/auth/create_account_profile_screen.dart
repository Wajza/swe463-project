import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class CreateAccountProfileScreen extends StatefulWidget {
  const CreateAccountProfileScreen({super.key});
  @override State<CreateAccountProfileScreen> createState() => _CreateAccountProfileScreenState();
}
class _CreateAccountProfileScreenState extends State<CreateAccountProfileScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  bool loading = false;
  String? error;
  @override void dispose() { nameController.dispose(); usernameController.dispose(); phoneController.dispose(); super.dispose(); }
  Future<void> submit() async {
    final nameError = AppValidators.requiredText(nameController.text);
    final usernameError = AppValidators.username(usernameController.text);
    if (nameError != null || usernameError != null) { setState(() => error = nameError ?? usernameError); return; }
    setState(() { loading = true; error = null; });
    try {
      await AuthService().createAccount(name: nameController.text.trim(), username: usernameController.text.trim(), phone: phoneController.text.trim());
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } catch (value) { if (mounted) setState(() => error = value.toString()); }
    if (mounted) setState(() => loading = false);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: Form(child: ListView(padding: const EdgeInsets.all(24), children: [
      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name'), validator: AppValidators.requiredText),
      const SizedBox(height: 16),
      TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username'), validator: AppValidators.username),
      const SizedBox(height: 16),
      TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone number'), validator: AppValidators.phone),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 24),
      SouqButton(label: loading ? 'Creating...' : 'Create account', onPressed: loading ? null : submit),
    ])),
  );
}
