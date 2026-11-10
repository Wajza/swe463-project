import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/user.dart';

/// A profile problem explained in words the member can act on.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The signed-in member's profile, kept at `users/{uid}`.
///
/// The app refers to the current member as [User.currentUserId], so
/// profiles are returned with that id; the account's [uid] stays in the
/// storage path and in the stored `id` field.
abstract class ProfileRepository {
  /// The profile of [uid], or null if it has none yet.
  /// Throws a [ProfileException] if it cannot be read.
  Future<User?> fetchProfile(String uid);

  /// Saves [profile] as the profile of [uid], keeping fields this app does
  /// not know about. Throws a [ProfileException] if it cannot be saved.
  Future<void> saveProfile(String uid, User profile);
}

/// Converts between [User] and the data stored in `users/{uid}`.
abstract final class ProfileDocument {
  /// The fields to store for [profile] under [uid].
  static Map<String, dynamic> toData(String uid, User profile) => {
    ...profile.toJson(),
    'id': uid,
  };

  /// Reads stored [data], using empty values for any field that is missing
  /// or of the wrong type, so older or hand-edited records still open.
  static User fromData(Map<String, dynamic> data) => User(
    id: User.currentUserId,
    firstName: _text(data['firstName']),
    lastName: _text(data['lastName']),
    username: _text(data['username']),
    city: _text(data['city']),
    bio: _text(data['bio']),
    phone: _text(data['phone']),
    isVerified: data['isVerified'] is bool ? data['isVerified'] as bool : false,
    skillsOffered: _texts(data['skillsOffered']),
    skillsWanted: _texts(data['skillsWanted']),
    availability: _text(data['availability']),
  );

  static String _text(Object? value) => value is String ? value : '';

  static List<String> _texts(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

/// Profiles in Cloud Firestore.
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileOf(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<User?> fetchProfile(String uid) => _guard(() async {
    final data = (await _profileOf(uid).get()).data();
    return data == null ? null : ProfileDocument.fromData(data);
  });

  @override
  Future<void> saveProfile(String uid, User profile) => _guard(
    // Merging keeps fields such as `createdAt` that are set elsewhere.
    () => _profileOf(uid).set({
      ...ProfileDocument.toData(uid, profile),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  /// Runs [action], turning Firestore errors into [ProfileException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw ProfileException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your profile could not be opened.',
        _ => 'We could not reach your profile. Try again.',
      });
    } on TypeError {
      throw const ProfileException('Your profile could not be read.');
    } catch (_) {
      throw const ProfileException('We could not reach your profile. Try again.');
    }
  }
}

/// Keeps profiles in memory. Used when Firebase has not been set up, such
/// as in widget tests.
class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository({Map<String, User>? profiles})
    : _data = {
        for (final MapEntry(:key, :value) in (profiles ?? {}).entries)
          key: ProfileDocument.toData(key, value),
      };

  // Stored as data so it behaves like Firestore: a saved profile is a copy.
  final Map<String, Map<String, dynamic>> _data;

  @override
  Future<User?> fetchProfile(String uid) async {
    final data = _data[uid];
    return data == null ? null : ProfileDocument.fromData(data);
  }

  @override
  Future<void> saveProfile(String uid, User profile) async {
    _data[uid] = {..._data[uid] ?? {}, ...ProfileDocument.toData(uid, profile)};
  }
}
