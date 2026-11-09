import '../models/user.dart';
import 'repository.dart';

class AuthService {
  AuthService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  bool get isSignedIn => _repository.currentUser.isVerified;
  Future<bool> requestOtp(String phone) async => phone.trim().isNotEmpty;
  Future<bool> verifyOtp(String code) async => RegExp(r'^\d{6}$').hasMatch(code.trim());
  Future<User> createAccount({required String name, required String username, required String phone}) async {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
    final initials = parts.map((part) => part[0].toUpperCase()).join();
    _repository.updateUser(User(name: name, initials: initials, username: username, phone: phone, isVerified: true));
    return _repository.currentUser;
  }
  Future<void> signOut() async => _repository.updateUser(const User(name: '', initials: ''));
}
