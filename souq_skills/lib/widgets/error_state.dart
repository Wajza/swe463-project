import 'package:flutter/material.dart';
import 'retry_button.dart';
class ErrorState extends StatelessWidget { const ErrorState({required this.message, this.onRetry, super.key}); final String message; final VoidCallback? onRetry; @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline), Text(message), if (onRetry != null) RetryButton(onPressed: onRetry!)])); }
