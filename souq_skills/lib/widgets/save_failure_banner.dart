import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/services/repository.dart';

/// Appears under every screen while changes cannot be saved to the device.
class SaveFailureBanner extends StatelessWidget {
  const SaveFailureBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = Repository.instance;
    return Column(
      children: [
        Expanded(child: child),
        ValueListenableBuilder<bool>(
          valueListenable: repository.saveFailed,
          builder: (context, failed, _) => !failed
              ? const SizedBox.shrink()
              : Material(
                  color: context.colors.errorContainer,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Your latest changes were not saved.'),
                          ),
                          TextButton(
                            onPressed: repository.save,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
