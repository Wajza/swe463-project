import 'package:flutter/material.dart';

extension AppFeedback on BuildContext {
  void showMessage(String message) => ScaffoldMessenger.of(this)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
