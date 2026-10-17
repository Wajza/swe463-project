import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/souq_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      transform: Matrix4.rotationZ(-0.25),
                    ),
                    Container(
                      width: 230,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      transform: Matrix4.rotationZ(0.25),
                    ),
                    const SouqLogo(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EEE1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Made for Saudi communities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Trade what you know.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: souqNavy,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Learn what you love.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: souqLavender,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Souq Skills connects people to exchange time\nand talent — never cash.',
                textAlign: TextAlign.center,
                style: TextStyle(color: souqNavy, fontSize: 17, height: 1.45),
              ),
              const SizedBox(height: 32),
              SouqButton(
                label: 'Get started',
                showArrow: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SouqLogo(small: true),
                ],
              ),
              const SizedBox(height: 72),
              const Text(
                'STEP 1 OF 2',
                style: TextStyle(
                  color: souqGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What’s your number?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'We’ll send a one-time SMS to verify it’s really you.',
                style: TextStyle(fontSize: 19, color: souqNavy),
              ),
              const SizedBox(height: 36),
              const Text('Mobile number'),
              const SizedBox(height: 8),
              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: souqGreen),
                  ),
                  prefixText: 'SA  +966   ',
                  hintText: '5X XXX XXXX',
                ),
              ),
              const SizedBox(height: 32),
              SouqButton(
                label: 'Send verification code',
                showArrow: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationCodeScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'By continuing, you agree to our community guidelines and safety policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerificationCodeScreen extends StatelessWidget {
  const VerificationCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Text(
                'Enter your code',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text('A demo code was sent to your phone number.'),
              const SizedBox(height: 32),
              const TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '•  •  •  •',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () {}, child: const Text('Resend code')),
              const Spacer(),
              SouqButton(
                label: 'Verify code',
                showArrow: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationSuccessScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: SouqLogo(small: true),
              ),
              const SizedBox(height: 92),
              const CircleAvatar(
                radius: 78,
                backgroundColor: Color(0xFFE7F5C9),
                child: CircleAvatar(
                  radius: 62,
                  backgroundColor: souqMint,
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 56,
                    color: souqGreen,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'You’re verified',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              const Text(
                'Your phone is secure. A verified badge now\nappears on your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, height: 1.45),
              ),
              const SizedBox(height: 34),
              Card(
                child: const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: souqGreen,
                    child: Text('YA', style: TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    'Yara Alotaibi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('✓  Phone verified'),
                ),
              ),
              const SizedBox(height: 32),
              SouqButton(
                label: 'Start exploring',
                showArrow: true,
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'By continuing, you agree to our community guidelines and safety policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
