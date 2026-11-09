class AppValidators {
  const AppValidators._();

  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(phone)) {
      return 'Enter a valid Saudi mobile number';
    }
    return null;
  }

  static String? otp(String? value) {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value?.trim() ?? '')) {
      return 'Enter the 6-digit verification code';
    }
    return null;
  }

  static String? username(String? value) {
    final username = value?.trim() ?? '';
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      return 'Use 3–20 letters, numbers, or underscores';
    }
    return null;
  }

  static String? positiveMinutes(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null || minutes <= 0) {
      return 'Enter a positive number of minutes';
    }
    return null;
  }

  static String? listingTitle(String? value) {
    final error = requiredText(value);
    if (error != null) return error;
    return value!.trim().length < 3 ? 'Use at least 3 characters' : null;
  }

  static String? listingDescription(String? value) {
    final error = requiredText(value);
    if (error != null) return error;
    return value!.trim().length < 10 ? 'Use at least 10 characters' : null;
  }

  static String? tradeProposal(String? value) => requiredText(value);

  static String? supportMessage(String? value) => requiredText(value);

  static String? reportDetails(String? value) => requiredText(value);
}
