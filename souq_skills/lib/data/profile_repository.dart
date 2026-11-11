import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:souq_skills/models/user.dart';

/// What a member shares on their public profile, `publicProfiles/{uid}`.
/// Names and username are always shared, as listings and chats need them.
class ProfileVisibility {
  const ProfileVisibility({this.showProfile = true, this.showLocation = true});

  /// False keeps city, bio, skills and availability private.
  final bool showProfile;

  /// False keeps the city private.
  final bool showLocation;
}

/// A profile problem explained in words the member can act on.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  /// Another account already uses the username.
  static const usernameTaken = ProfileException(
    'That username is already taken',
  );

  @override
  String toString() => message;
}

/// The signed-in member's profile, kept at `users/{uid}`.
///
/// The app refers to the current member as [User.currentUserId], so
/// profiles are returned with that id; the account's [uid] stays in the
/// storage path and in the stored `id` field.
///
/// Usernames are unique across accounts, ignoring case: each one is claimed
/// at `usernames/{key}` (see [ProfileDocument.usernameKey]).
abstract class ProfileRepository {
  /// The profile of [uid], or null if it has none yet.
  /// Throws a [ProfileException] if it cannot be read.
  Future<User?> fetchProfile(String uid);

  /// Saves [profile] as the profile of [uid], keeping fields this app does
  /// not know about, claims its username, and publishes what [visibility]
  /// allows at `publicProfiles/{uid}`, all together. The first save creates
  /// the profile. Throws a [ProfileException] if it cannot be saved, or
  /// [ProfileException.usernameTaken] if another account has the username;
  /// nothing is changed then.
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  });

  /// Removes the profile of [uid], its public profile and its username
  /// claim, together. Throws a [ProfileException] and changes nothing if
  /// that fails.
  Future<void> deleteProfile(String uid);

  /// The public profiles of [uids] that exist, by uid, each as a [User]
  /// whose id is the uid and whose phone is empty. Profiles that could not
  /// be read are left out, so they can be tried again later; it never
  /// throws.
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids);
}

/// What saving a profile does to the username claims.
class UsernameChange {
  const UsernameChange({this.claim, this.release});

  /// The key to claim for the account, or null if it already holds it.
  final String? claim;

  /// The key of the account's previous username to give up, if any.
  final String? release;

  /// Decides the change for [uid] moving from [oldUsername] to
  /// [newUsername], given who currently holds each name's claim.
  ///
  /// Throws [ProfileException.usernameTaken] if another account holds the
  /// new name. An account that never claimed its name (created before
  /// claims existed) claims it now, as long as it is still free.
  static UsernameChange plan({
    required String uid,
    required String oldUsername,
    required String newUsername,
    required String? newOwner,
    required String? oldOwner,
  }) {
    final newKey = ProfileDocument.usernameKey(newUsername);
    final oldKey = ProfileDocument.usernameKey(oldUsername);
    if (newKey.isNotEmpty && newOwner != null && newOwner != uid) {
      throw ProfileException.usernameTaken;
    }
    return UsernameChange(
      claim: newKey.isEmpty || newOwner == uid ? null : newKey,
      // Only a name this account holds is ever given up.
      release: oldKey.isNotEmpty && oldKey != newKey && oldOwner == uid
          ? oldKey
          : null,
    );
  }
}

/// Converts between [User] and the data stored in `users/{uid}`.
abstract final class ProfileDocument {
  /// The form a username is compared and claimed in: without surrounding
  /// spaces and in lower case, so `Maha_Z` and ` maha_z` are the same name.
  static String usernameKey(String username) => username.trim().toLowerCase();

  /// The data stored at `usernames/{key}` for a claim by [uid].
  static Map<String, dynamic> claimData(String uid, String username) => {
    'uid': uid,
    'username': username.trim(),
  };

  /// The data stored at `publicProfiles/{uid}`: only what other members
  /// may see, and never the phone number. [isVerified] comes from how the
  /// account signed in, not from the profile.
  static Map<String, dynamic> toPublicData(
    String uid,
    User profile,
    ProfileVisibility visibility, {
    required bool isVerified,
  }) {
    final details = visibility.showProfile;
    return {
      'uid': uid,
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'username': profile.username,
      'city': details && visibility.showLocation ? profile.city : '',
      'bio': details ? profile.bio : '',
      'skillsOffered': details ? profile.skillsOffered : const <String>[],
      'skillsWanted': details ? profile.skillsWanted : const <String>[],
      'availability': details ? profile.availability : '',
      'isVerified': isVerified,
      // Also decides whether others may read the member's reviews.
      'profileVisible': details,
    };
  }

  /// Reads another member's public profile as a [User] with [uid] as its
  /// id, so it is never mistaken for the current member, and no phone.
  static User fromPublicData(String uid, Map<String, dynamic> data) => User(
    id: uid,
    firstName: _text(data['firstName']),
    lastName: _text(data['lastName']),
    username: _text(data['username']),
    city: _text(data['city']),
    bio: _text(data['bio']),
    isVerified: data['isVerified'] is bool ? data['isVerified'] as bool : false,
    skillsOffered: _texts(data['skillsOffered']),
    skillsWanted: _texts(data['skillsWanted']),
    availability: _text(data['availability']),
  );

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
  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    bool Function()? isPhoneVerified,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _isPhoneVerified =
           isPhoneVerified ??
           (() => auth.FirebaseAuth.instance.currentUser?.phoneNumber != null);

  final FirebaseFirestore _firestore;

  /// Whether the signed-in account was verified by phone, which is what
  /// the published `isVerified` must say.
  final bool Function() _isPhoneVerified;

  DocumentReference<Map<String, dynamic>> _profileOf(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _publicOf(String uid) =>
      _firestore.collection('publicProfiles').doc(uid);

  DocumentReference<Map<String, dynamic>> _claimOf(String key) =>
      _firestore.collection('usernames').doc(key);

  @override
  Future<User?> fetchProfile(String uid) => _guard(() async {
    final data = (await _profileOf(uid).get()).data();
    return data == null ? null : ProfileDocument.fromData(data);
  });

  /// One transaction, so two accounts can never end up with the same name:
  /// if either claim changes before it commits, Firestore runs it again.
  @override
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  }) async {
    final isVerified = _isPhoneVerified();
    final saved = await _guard(
      () => _firestore.runTransaction<bool>((transaction) async {
        // Every read comes before any write, as transactions require.
        final current = await transaction.get(_profileOf(uid));
        final oldUsername = ProfileDocument.fromData(current.data() ?? const {})
            .username;
        final newKey = ProfileDocument.usernameKey(profile.username);
        final oldKey = ProfileDocument.usernameKey(oldUsername);
        final newOwner = newKey.isEmpty
            ? null
            : await _ownerOf(transaction, newKey);
        final oldOwner = oldKey.isEmpty || oldKey == newKey
            ? null
            : await _ownerOf(transaction, oldKey);

        final UsernameChange change;
        try {
          change = UsernameChange.plan(
            uid: uid,
            oldUsername: oldUsername,
            newUsername: profile.username,
            newOwner: newOwner,
            oldOwner: oldOwner,
          );
        } on ProfileException {
          // Returned rather than thrown, so it reads the same on every
          // platform; nothing has been written.
          return false;
        }

        final claim = change.claim;
        if (claim != null) {
          transaction.set(_claimOf(claim), {
            ...ProfileDocument.claimData(uid, profile.username),
            'claimedAt': FieldValue.serverTimestamp(),
          });
        }
        final release = change.release;
        if (release != null) transaction.delete(_claimOf(release));
        // Merging keeps `createdAt`, set once when the profile is created,
        // and any fields this app does not know about.
        transaction.set(_profileOf(uid), {
          ...ProfileDocument.toData(uid, profile),
          if (!current.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Replaced whole, so anything no longer shared is removed.
        transaction.set(_publicOf(uid), {
          ...ProfileDocument.toPublicData(
            uid,
            profile,
            visibility,
            isVerified: isVerified,
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }),
    );
    if (!saved) throw ProfileException.usernameTaken;
  }

  @override
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids) async {
    // One read per member, side by side; a failed read is left out.
    final results = await Future.wait([
      for (final uid in {...uids})
        _publicOf(uid).get().then<MapEntry<String, User>?>((snapshot) {
          final data = snapshot.data();
          return data == null
              ? null
              : MapEntry(uid, ProfileDocument.fromPublicData(uid, data));
        }, onError: (Object _) => null),
    ]);
    return Map.fromEntries(results.whereType<MapEntry<String, User>>());
  }

  @override
  Future<void> deleteProfile(String uid) => _guard(
    () => _firestore.runTransaction<void>((transaction) async {
      final current = await transaction.get(_profileOf(uid));
      final key = ProfileDocument.usernameKey(
        ProfileDocument.fromData(current.data() ?? const {}).username,
      );
      final owner = key.isEmpty ? null : await _ownerOf(transaction, key);
      // Only a name this account holds is ever freed.
      if (owner == uid) transaction.delete(_claimOf(key));
      if (current.exists) transaction.delete(_profileOf(uid));
      // Deleting a public profile that was never published is harmless.
      transaction.delete(_publicOf(uid));
    }),
  );

  /// The uid holding the claim on [key], or null if it is free.
  Future<String?> _ownerOf(Transaction transaction, String key) async {
    final owner = (await transaction.get(_claimOf(key))).data()?['uid'];
    return owner is String ? owner : null;
  }

  /// Runs [action], turning Firestore errors into [ProfileException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ProfileException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ProfileException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your profile could not be opened.',
        _ => 'We could not reach your profile. Try again.',
      });
    } on TypeError {
      throw const ProfileException('Your profile could not be read.');
    } catch (_) {
      throw const ProfileException(
        'We could not reach your profile. Try again.',
      );
    }
  }
}

/// Keeps profiles and username claims in memory, with the same rules as
/// Firestore. Used when Firebase has not been set up, such as in tests.
class DemoProfileRepository implements ProfileRepository {
  /// [profiles] start without claims, like accounts created before claims
  /// existed; [claims] maps usernames (any case) to the uid holding them.
  ///
  /// [profiles] also start without public profiles, like accounts made
  /// before public profiles existed.
  DemoProfileRepository({
    Map<String, User>? profiles,
    Map<String, String>? claims,
    this.isPhoneVerified = true,
  }) : _data = {
         for (final MapEntry(:key, :value) in (profiles ?? {}).entries)
           key: ProfileDocument.toData(key, value),
       },
       _claims = {
         for (final MapEntry(:key, :value) in (claims ?? {}).entries)
           ProfileDocument.usernameKey(key): value,
       };

  // Stored as data so it behaves like Firestore: a saved profile is a copy.
  final Map<String, Map<String, dynamic>> _data;
  final Map<String, String> _claims;
  final Map<String, Map<String, dynamic>> _public = {};

  /// Whether accounts count as verified by phone when published.
  final bool isPhoneVerified;

  /// The uid holding [username], or null if it is free.
  String? ownerOf(String username) =>
      _claims[ProfileDocument.usernameKey(username)];

  /// A copy of what is published for [uid], or null if nothing is.
  Map<String, dynamic>? publicDataOf(String uid) {
    final data = _public[uid];
    return data == null ? null : {...data};
  }

  @override
  Future<Map<String, User>> fetchPublicProfiles(Iterable<String> uids) async =>
      {
        for (final uid in uids)
          if (_public[uid] case final data?)
            uid: ProfileDocument.fromPublicData(uid, data),
      };

  @override
  Future<User?> fetchProfile(String uid) async {
    final data = _data[uid];
    return data == null ? null : ProfileDocument.fromData(data);
  }

  @override
  Future<void> saveProfile(
    String uid,
    User profile, {
    ProfileVisibility visibility = const ProfileVisibility(),
  }) async {
    final stored = _data[uid];
    final oldUsername = stored == null
        ? ''
        : ProfileDocument.fromData(stored).username;
    // Throws before anything changes if the name is taken.
    final change = UsernameChange.plan(
      uid: uid,
      oldUsername: oldUsername,
      newUsername: profile.username,
      newOwner: ownerOf(profile.username),
      oldOwner: ownerOf(oldUsername),
    );
    final claim = change.claim;
    if (claim != null) _claims[claim] = uid;
    _claims.remove(change.release);
    _data[uid] = {...stored ?? {}, ...ProfileDocument.toData(uid, profile)};
    _public[uid] = ProfileDocument.toPublicData(
      uid,
      profile,
      visibility,
      isVerified: isPhoneVerified,
    );
  }

  @override
  Future<void> deleteProfile(String uid) async {
    _public.remove(uid);
    final stored = _data.remove(uid);
    if (stored == null) return;
    final key = ProfileDocument.usernameKey(
      ProfileDocument.fromData(stored).username,
    );
    if (_claims[key] == uid) _claims.remove(key);
  }
}
