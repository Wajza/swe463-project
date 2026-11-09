enum OtpPurpose { signIn, signUp, changePhone }

class OtpRequest {
  const OtpRequest({required this.phone, required this.purpose});

  final String phone;
  final OtpPurpose purpose;
}
