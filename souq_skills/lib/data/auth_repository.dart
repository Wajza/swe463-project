import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A sign-in problem explained in words the member can act on.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Phone number sign-in and the account record that goes with it.
///
/// Phone numbers are passed in international format, e.g. `+966501234567`.
abstract class AuthRepository {
  /// The signed-in account's id, or null when nobody is signed in.
  String? get uid;

  /// A code that is already known for the pending verification, so the
  /// member does not have to type it. Null when it must be entered.
  String? get suggestedCode;

  /// Completes once a session saved by an earlier visit has been restored.
  Future<void> restoreSession();

  /// Sends a verification code by SMS to [phoneNumber].
  Future<void> sendCode(String phoneNumber);

  /// Signs in with the code sent by [sendCode].
  Future<void> verifyCode(String smsCode);

  /// Moves the signed-in account to the number passed to [sendCode].
  Future<void> verifyNewPhone(String smsCode);

  /// Whether the signed-in account already has a member profile.
  Future<bool> hasProfile();

  Future<void> signOut();

  /// Removes the sign-in account. Its profile is removed separately, by the
  /// ProfileRepository, before this is called.
  Future<void> deleteAccount();
}

/// Firebase Authentication for sign-in, with profiles in `users/{uid}`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Pending verification: web keeps a ConfirmationResult, Android and iOS
  // keep a verification id (or a credential when verified without an SMS).
  ConfirmationResult? _confirmation;
  String? _verificationId;
  PhoneAuthCredential? _autoCredential;

  void _clearPending() {
    _confirmation = null;
    _verificationId = null;
    _autoCredential = null;
  }

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  String? get suggestedCode => _autoCredential?.smsCode;

  DocumentReference<Map<String, dynamic>> _profileOf(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<void> restoreSession() => _auth.authStateChanges().first;

  @override
  Future<void> sendCode(String phoneNumber) async {
    _clearPending();
    if (kIsWeb) {
      // Shows an invisible reCAPTCHA, then texts the code.
      _confirmation = await _guard(
        () => _auth.signInWithPhoneNumber(phoneNumber),
      );
      return;
    }
    final sent = Completer<void>();
    void finish([Object? error]) {
      if (sent.isCompleted) return;
      error == null ? sent.complete() : sent.completeError(error);
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // Some Android devices verify the number without an SMS.
        verificationCompleted: (credential) {
          _autoCredential = credential;
          finish();
        },
        verificationFailed: (error) => finish(_describe(error)),
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          finish();
        },
        codeAutoRetrievalTimeout: (verificationId) =>
            _verificationId ??= verificationId,
      );
    } on FirebaseAuthException catch (error) {
      finish(_describe(error));
    } catch (_) {
      finish(const AuthException('We could not send the code. Try again.'));
    }
    return sent.future;
  }

  PhoneAuthCredential _credentialFor(String smsCode) {
    final verificationId = _verificationId ?? _confirmation?.verificationId;
    if (verificationId != null) {
      return PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
    }
    final credential = _autoCredential;
    if (credential != null) return credential;
    throw const AuthException('Request a new code and try again.');
  }

  @override
  Future<void> verifyCode(String smsCode) => _guard(() async {
    if (kIsWeb) {
      final confirmation = _confirmation;
      if (confirmation == null) {
        throw const AuthException('Request a new code and try again.');
      }
      await confirmation.confirm(smsCode);
    } else {
      await _auth.signInWithCredential(_credentialFor(smsCode));
    }
    _clearPending();
  });

  /// On web the credential is built from the ConfirmationResult's
  /// verification id, since confirming it would sign in instead.
  @override
  Future<void> verifyNewPhone(String smsCode) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(_sessionExpired);
    await user.updatePhoneNumber(_credentialFor(smsCode));
    _clearPending();
  });

  @override
  Future<bool> hasProfile() => _guard(() async {
    final uid = this.uid;
    if (uid == null) throw const AuthException(_sessionExpired);
    final snapshot = await _profileOf(uid).get();
    return snapshot.exists;
  });

  @override
  Future<void> signOut() => _guard(() async {
    _clearPending();
    await _auth.signOut();
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(_sessionExpired);
    await user.delete();
  });

  static const _sessionExpired = 'Your session has expired. Sign in again.';

  /// Runs [action], turning Firebase errors into [AuthException]s.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _describe(error);
    } on FirebaseException catch (error) {
      throw _describeData(error);
    } catch (_) {
      throw const AuthException('Something went wrong. Try again.');
    }
  }

  static AuthException _describe(FirebaseAuthException error) =>
      AuthException(switch (error.code) {
        'invalid-phone-number' => 'Enter a valid Saudi mobile number',
        'invalid-verification-code' => 'That code is not correct.',
        'invalid-verification-id' ||
        'session-expired' ||
        'code-expired' => 'That code has expired. Request a new one.',
        'too-many-requests' ||
        'quota-exceeded' => 'Too many attempts. Wait a while and try again.',
        'network-request-failed' => 'Check your internet connection.',
        'captcha-check-failed' ||
        'missing-client-identifier' ||
        'app-not-authorized' => 'We could not confirm this device. Try again.',
        'credential-already-in-use' ||
        'account-exists-with-different-credential' =>
          'That number already belongs to another account.',
        'requires-recent-login' =>
          'For your security, sign out and sign in again first.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'We could not verify your phone number. Try again.',
      });

  static AuthException _describeData(FirebaseException error) =>
      AuthException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your account details could not be opened.',
        _ => 'We could not reach your account. Try again.',
      });
}

/// Works without a backend: any 6-digit code is accepted. Used when
/// Firebase has not been set up, such as in widget tests.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({required this.isKnownPhone});

  /// Whether [phone] (local format) already has a profile on this device.
  final bool Function(String phone) isKnownPhone;

  static const demoCode = '123456';
  String? _phone;

  @override
  String? get uid => 'me';

  @override
  String? get suggestedCode => demoCode;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> sendCode(String phoneNumber) async => _phone = phoneNumber;

  @override
  Future<void> verifyCode(String smsCode) async {}

  @override
  Future<void> verifyNewPhone(String smsCode) async {}

  @override
  Future<bool> hasProfile() async =>
      isKnownPhone(_phone?.replaceFirst('+966', '') ?? '');

  @override
  Future<void> signOut() async => _phone = null;

  @override
  Future<void> deleteAccount() async => _phone = null;
}
