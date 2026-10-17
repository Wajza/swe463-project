class AuthService {
  const AuthService();

  // Authentication will be connected during Phase 3.
  Future<bool> verifyDemoCode(String code) async => code.length == 4;
}
