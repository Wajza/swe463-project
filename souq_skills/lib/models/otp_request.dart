enum OtpPurpose {
  signIn,
  signUp,
  changePhone,

  /// Verifying the signed-in member's own number again, before their
  /// account is deleted.
  confirmIdentity,
}

class OtpRequest {
  const OtpRequest({required this.phone, required this.purpose});

  final String phone;
  final OtpPurpose purpose;
}
