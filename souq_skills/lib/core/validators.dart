class AppValidators {
  const AppValidators._();

  static String? personName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2) return 'Enter a name';
    if (RegExp(r'[0-9]').hasMatch(name)) return 'Names cannot contain numbers';
    return null;
  }

  static String? username(String? value) {
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value?.trim() ?? '')) {
      return 'Use 3-20 letters, numbers or underscores';
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
      return 'Enter a valid 6-digit code';
    }
    return null;
  }
}
