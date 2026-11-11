// Firestore security rules tests for Souq Skills profiles, usernames,
// listings, blocks, reports, reviews, chats, trades and wallets.
//
// Run from souq_skills/ (starts and stops the emulator, deploys nothing):
//   firebase emulators:exec --only firestore --project demo-souq-skills \
//     "npm --prefix firestore_rules_test test"
//
// saveProfile() and deleteProfile() below make exactly the reads and writes
// of FirebaseProfileRepository in lib/data/profile_repository.dart, and
// createListing(), updateListing() and deleteListing() those of
// FirebaseListingRepository in lib/data/listing_repository.dart, using the
// Firebase JS SDK, which is also what FlutterFire uses on the web. Keep them
// in step with the Dart code.

import { readFileSync } from 'node:fs';
import { after, afterEach, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  increment,
  limit,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const ME = 'uid-maha';
const OTHER = 'uid-sami';
const THIRD = 'uid-lina';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-souq-skills',
    firestore: {
      // RULES_FILE lets a changed copy of the rules be tried instead.
      rules: readFileSync(
        process.env.RULES_FILE ?? new URL('../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });
});

afterEach(() => env.clearFirestore());

after(() => env.cleanup());

/// Members sign in with a phone number, as in the app.
const dbAs = (uid) =>
  env.authenticatedContext(uid, { phone_number: '+966500000000' }).firestore();
/// A signed-in account without a phone number, e.g. another sign-in method.
const dbWithoutPhoneAs = (uid) => env.authenticatedContext(uid).firestore();
const anonymousDb = () => env.unauthenticatedContext().firestore();

/// What User.toJson() produces, as saved by ProfileDocument.toData.
function profile(username, extra = {}) {
  return {
    firstName: 'Maha',
    lastName: 'Alzahrani',
    username,
    city: 'Jeddah',
    bio: '',
    phone: '512345678',
    isVerified: true,
    skillsOffered: ['Calligraphy'],
    skillsWanted: [],
    availability: '',
    ...extra,
  };
}

/// Writes documents directly, as data created before these rules.
async function seed(docs) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [path, data] of Object.entries(docs)) {
      await setDoc(doc(db, path), data);
    }
  });
}

async function read(path) {
  let data;
  await env.withSecurityRulesDisabled(async (context) => {
    const snapshot = await getDoc(doc(context.firestore(), path));
    data = snapshot.exists() ? snapshot.data() : undefined;
  });
  return data;
}

const usernameKey = (name) => name.trim().toLowerCase();

/// Mirrors ProfileDocument.toPublicData.
function publicData(uid, user, { showProfile = true, showLocation = true, isVerified = true } = {}) {
  return {
    uid,
    firstName: user.firstName,
    lastName: user.lastName,
    username: user.username,
    city: showProfile && showLocation ? user.city : '',
    bio: showProfile ? user.bio : '',
    skillsOffered: showProfile ? user.skillsOffered : [],
    skillsWanted: showProfile ? user.skillsWanted : [],
    availability: showProfile ? user.availability : '',
    isVerified,
    profileVisible: showProfile,
  };
}

/// Mirrors FirebaseProfileRepository.saveProfile. Resolves to false when
/// the username is taken (nothing written), true when saved. [visibility]
/// is passed to publicData; [publish] false leaves out the public profile,
/// as app versions from before public profiles did.
function saveProfile(db, uid, user, visibility = {}, { publish = true } = {}) {
  return runTransaction(db, async (transaction) => {
    const userRef = doc(db, 'users', uid);
    const current = await transaction.get(userRef);
    const oldUsername = current.exists() ? current.data().username ?? '' : '';
    const newKey = usernameKey(user.username);
    const oldKey = usernameKey(oldUsername);
    const ownerOf = async (key) =>
      (await transaction.get(doc(db, 'usernames', key))).data()?.uid ?? null;
    const newOwner = newKey === '' ? null : await ownerOf(newKey);
    const oldOwner = oldKey === '' || oldKey === newKey ? null : await ownerOf(oldKey);

    // UsernameChange.plan
    if (newKey !== '' && newOwner !== null && newOwner !== uid) return false;
    const claim = newKey === '' || newOwner === uid ? null : newKey;
    const release =
      oldKey !== '' && oldKey !== newKey && oldOwner === uid ? oldKey : null;

    if (claim !== null) {
      transaction.set(doc(db, 'usernames', claim), {
        uid,
        username: user.username.trim(),
        claimedAt: serverTimestamp(),
      });
    }
    if (release !== null) transaction.delete(doc(db, 'usernames', release));
    transaction.set(
      userRef,
      {
        ...user,
        id: uid,
        ...(current.exists() ? {} : { createdAt: serverTimestamp() }),
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
    if (publish) {
      transaction.set(doc(db, 'publicProfiles', uid), {
        ...publicData(uid, user, visibility),
        updatedAt: serverTimestamp(),
      });
    }
    return true;
  });
}

/// Mirrors FirebaseProfileRepository.deleteProfile.
function deleteProfile(db, uid) {
  return runTransaction(db, async (transaction) => {
    const userRef = doc(db, 'users', uid);
    const current = await transaction.get(userRef);
    const key = usernameKey(current.exists() ? current.data().username ?? '' : '');
    const owner =
      key === ''
        ? null
        : (await transaction.get(doc(db, 'usernames', key))).data()?.uid ?? null;
    if (owner === uid) transaction.delete(doc(db, 'usernames', key));
    if (current.exists()) transaction.delete(userRef);
    transaction.delete(doc(db, 'publicProfiles', uid));
  });
}

describe('app flows the rules must allow', () => {
  test('sign-up creates the profile and claims the username', async () => {
    assert.equal(await assertSucceeds(saveProfile(dbAs(ME), ME, profile('Maha_Z'))), true);

    assert.equal((await read('usernames/maha_z')).uid, ME);
    assert.equal((await read('usernames/maha_z')).username, 'Maha_Z');
    const saved = await read(`users/${ME}`);
    assert.equal(saved.username, 'Maha_Z');
    assert.ok(saved.createdAt, 'createdAt is set on sign-up');
  });

  test('a taken username is refused by the app without any write', async () => {
    await saveProfile(dbAs(OTHER), OTHER, profile('maha_z', { firstName: 'Sami' }));

    assert.equal(await assertSucceeds(saveProfile(dbAs(ME), ME, profile('MAHA_Z'))), false);
    assert.equal(await read(`users/${ME}`), undefined);
    assert.equal((await read('usernames/maha_z')).uid, OTHER);
  });

  test('editing the profile and My Skills keep the claim', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));
    const createdAt = (await read(`users/${ME}`)).createdAt;

    await assertSucceeds(saveProfile(db, ME, profile('maha_z', { bio: 'New bio' })));
    await assertSucceeds(
      saveProfile(db, ME, profile('maha_z', { bio: 'New bio', skillsOffered: ['Calligraphy', 'Baking'] })),
    );

    const saved = await read(`users/${ME}`);
    assert.deepEqual(saved.skillsOffered, ['Calligraphy', 'Baking']);
    assert.equal(saved.bio, 'New bio');
    assert.ok(saved.createdAt.isEqual(createdAt), 'createdAt is kept');
    assert.equal((await read('usernames/maha_z')).uid, ME);
  });

  test('changing only the capitalisation keeps the same claim', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertSucceeds(saveProfile(db, ME, profile('Maha_Z')));

    assert.equal((await read(`users/${ME}`)).username, 'Maha_Z');
    assert.equal((await read('usernames/maha_z')).uid, ME);
  });

  test('a rename claims the new name and frees the old one', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertSucceeds(saveProfile(db, ME, profile('maha_2')));

    assert.equal((await read('usernames/maha_2')).uid, ME);
    assert.equal(await read('usernames/maha_z'), undefined);
    // The freed name can now be taken by someone else.
    assert.equal(
      await assertSucceeds(saveProfile(dbAs(OTHER), OTHER, profile('maha_z', { firstName: 'Sami' }))),
      true,
    );
  });

  test('an account from before claims claims its name on its next save', async () => {
    await seed({ [`users/${ME}`]: { ...profile('maha_z'), id: ME, createdAt: new Date(2026, 0, 1) } });

    await assertSucceeds(saveProfile(dbAs(ME), ME, profile('maha_z', { bio: 'Updated' })));

    assert.equal((await read('usernames/maha_z')).uid, ME);
  });

  test('an old account whose name was claimed by another can rename', async () => {
    await seed({
      [`users/${ME}`]: { ...profile('sami'), id: ME },
      'usernames/sami': { uid: OTHER, username: 'sami' },
    });

    await assertSucceeds(saveProfile(dbAs(ME), ME, profile('maha_z')));

    assert.equal((await read('usernames/maha_z')).uid, ME);
    assert.equal((await read('usernames/sami')).uid, OTHER);
  });

  test('deleting the account removes the profile and frees the name', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertSucceeds(deleteProfile(db, ME));

    assert.equal(await read(`users/${ME}`), undefined);
    assert.equal(await read('usernames/maha_z'), undefined);
  });

  test('deleting an account from before claims works', async () => {
    await seed({ [`users/${ME}`]: { ...profile('maha_z'), id: ME } });

    await assertSucceeds(deleteProfile(dbAs(ME), ME));

    assert.equal(await read(`users/${ME}`), undefined);
  });

  test('a member reads their own profile and checks claims', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertSucceeds(getDoc(doc(db, 'users', ME)));
    await assertSucceeds(getDoc(doc(db, 'usernames', 'maha_z')));
    await assertSucceeds(getDoc(doc(db, 'usernames', 'free_name')));
  });
});

describe('privacy', () => {
  test('nobody else can read a profile, including the phone number', async () => {
    await saveProfile(dbAs(ME), ME, profile('maha_z'));

    await assertFails(getDoc(doc(dbAs(OTHER), 'users', ME)));
    await assertFails(getDoc(doc(anonymousDb(), 'users', ME)));
  });

  test('profiles and claims cannot be listed', async () => {
    await saveProfile(dbAs(ME), ME, profile('maha_z'));

    await assertFails(getDocs(collection(dbAs(ME), 'users')));
    await assertFails(getDocs(collection(dbAs(ME), 'usernames')));
  });

  test('signed-out visitors cannot check or make claims', async () => {
    await assertFails(getDoc(doc(anonymousDb(), 'usernames', 'maha_z')));
    await assertFails(
      setDoc(doc(anonymousDb(), 'usernames', 'maha_z'), { uid: ME, username: 'maha_z', claimedAt: serverTimestamp() }),
    );
  });
});

describe('writes the rules must refuse', () => {
  test('a profile cannot be written for another account', async () => {
    await assertFails(saveProfile(dbAs(OTHER), ME, profile('maha_z')));
    await saveProfile(dbAs(ME), ME, profile('maha_z'));
    await assertFails(updateDoc(doc(dbAs(OTHER), 'users', ME), { bio: 'Hacked' }));
    await assertFails(deleteDoc(doc(dbAs(OTHER), 'users', ME)));
  });

  // The hand-written batches below each change one thing in this one,
  // which the rules allow, so each refusal is down to that one change.
  test('control: a hand-written valid claim and profile are allowed', async () => {
    const db = dbAs(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'maha_z'), { uid: ME, username: 'maha_z', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users', ME), { ...profile('maha_z'), id: ME });
    await assertSucceeds(batch.commit());
  });

  test('a profile must store its own uid as its id', async () => {
    const db = dbAs(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'maha_z'), { uid: ME, username: 'maha_z', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users', ME), { ...profile('maha_z'), id: OTHER });
    await assertFails(batch.commit());
  });

  test('a profile cannot use a username without claiming it', async () => {
    await assertFails(setDoc(doc(dbAs(ME), 'users', ME), { ...profile('maha_z'), id: ME }));
  });

  test('a profile cannot use a username claimed by another account', async () => {
    await saveProfile(dbAs(OTHER), OTHER, profile('sami'));
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertFails(updateDoc(doc(db, 'users', ME), { username: 'sami' }));
    await assertFails(updateDoc(doc(db, 'users', ME), { username: 'SAMI' }));
  });

  test('an account without a claim cannot take a claimed username', async () => {
    await saveProfile(dbAs(OTHER), OTHER, profile('sami'));
    const db = dbAs(ME);

    // A new profile, and an account from before claims, with nothing to
    // release: only the claim check stands in the way.
    await assertFails(setDoc(doc(db, 'users', ME), { ...profile('Sami'), id: ME }));
    await seed({ [`users/${ME}`]: { ...profile('maha_z'), id: ME } });
    await assertFails(updateDoc(doc(db, 'users', ME), { username: 'sami' }));
  });

  test('a claim held by another account cannot be overwritten', async () => {
    await saveProfile(dbAs(OTHER), OTHER, profile('sami'));
    const db = dbAs(ME);

    // Writing the claim and profile together, skipping the app's check.
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'sami'), { uid: ME, username: 'sami', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users', ME), { ...profile('sami'), id: ME });
    await assertFails(batch.commit());
    assert.equal((await read('usernames/sami')).uid, OTHER);
  });

  test('claims cannot be transferred by updating them', async () => {
    await saveProfile(dbAs(ME), ME, profile('maha_z'));

    await assertFails(updateDoc(doc(dbAs(ME), 'usernames', 'maha_z'), { uid: OTHER }));
    await assertFails(updateDoc(doc(dbAs(OTHER), 'usernames', 'maha_z'), { uid: OTHER }));
  });

  test('a claim can only be made for the caller', async () => {
    const db = dbAs(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'maha_z'), { uid: OTHER, username: 'maha_z', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users', ME), { ...profile('maha_z'), id: ME });
    await assertFails(batch.commit());
  });

  test('a claim must match the username in the resulting profile', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    // Reserving a second name the profile does not use.
    await assertFails(
      setDoc(doc(db, 'usernames', 'spare_name'), { uid: ME, username: 'spare_name', claimedAt: serverTimestamp() }),
    );
    // A claim whose stored username differs from its key.
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'maha_2'), { uid: ME, username: 'other', claimedAt: serverTimestamp() });
    batch.delete(doc(db, 'usernames', 'maha_z'));
    batch.set(doc(db, 'users', ME), { username: 'maha_2' }, { merge: true });
    await assertFails(batch.commit());
  });

  test('claim keys must be lower-case and 3-20 letters, digits or _', async () => {
    for (const [key, username] of [
      ['Maha_Z', 'Maha_Z'],
      ['ab', 'ab'],
      ['bad-name', 'bad-name'],
      ['a'.repeat(21), 'a'.repeat(21)],
    ]) {
      const db = dbAs(ME);
      const batch = writeBatch(db);
      batch.set(doc(db, 'usernames', key), { uid: ME, username, claimedAt: serverTimestamp() });
      batch.set(doc(db, 'users', ME), { ...profile(username), id: ME });
      await assertFails(batch.commit(), `key ${key} must be refused`);
    }
  });

  test('a claim cannot carry extra fields or a made-up time', async () => {
    const db = dbAs(ME);
    for (const claim of [
      { uid: ME, username: 'maha_z', claimedAt: serverTimestamp(), admin: true },
      { uid: ME, username: 'maha_z', claimedAt: new Date(2020, 0, 1) },
    ]) {
      const batch = writeBatch(db);
      batch.set(doc(db, 'usernames', 'maha_z'), claim);
      batch.set(doc(db, 'users', ME), { ...profile('maha_z'), id: ME });
      await assertFails(batch.commit());
    }
  });

  test('a rename cannot keep the old name reserved', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', 'maha_2'), { uid: ME, username: 'maha_2', claimedAt: serverTimestamp() });
    batch.set(doc(db, 'users', ME), { username: 'maha_2' }, { merge: true });
    await assertFails(batch.commit());
  });

  test('a claim cannot be given up while the profile still uses it', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertFails(deleteDoc(doc(db, 'usernames', 'maha_z')));
  });

  test("another account's claim cannot be deleted", async () => {
    await saveProfile(dbAs(OTHER), OTHER, profile('sami'));

    await assertFails(deleteDoc(doc(dbAs(ME), 'usernames', 'sami')));
  });

  test('a profile cannot be deleted while keeping its claim', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, profile('maha_z'));

    await assertFails(deleteDoc(doc(db, 'users', ME)));
  });
});

// ---------------------------------------------------------------------------
// Listings

/// What ListingDocument.toData stores for a listing owned by [owner].
function listingData(owner, extra = {}) {
  return {
    ownerId: owner,
    category: 'Design',
    title: 'Learn Arabic calligraphy',
    offers: 'Arabic calligraphy',
    wants: 'Photography',
    distance: '',
    description: 'Practical Arabic calligraphy sessions, exchanged for Photography.',
    city: 'Jeddah',
    availability: 'Weekends',
    sessionsMinutes: 60,
    onlineOnly: false,
    womenOnly: true,
    isPaused: false,
    ...extra,
  };
}

/// Mirrors FirebaseListingRepository.createListing. Resolves to the new id.
async function createListing(db, data) {
  const ref = doc(collection(db, 'listings'));
  await setDoc(ref, {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return ref.id;
}

/// Mirrors FirebaseListingRepository.updateListing: read and check the
/// owner, then merge every listing field and the update time.
function updateListing(db, uid, id, data) {
  return runTransaction(db, async (transaction) => {
    const ref = doc(db, 'listings', id);
    const current = await transaction.get(ref);
    if (!current.exists()) return 'notFound';
    if (current.data().ownerId !== uid) return 'notYours';
    transaction.set(ref, { ...data, updatedAt: serverTimestamp() }, { merge: true });
    return null;
  });
}

/// Mirrors FirebaseListingRepository.deleteListing.
function deleteListing(db, uid, id) {
  return runTransaction(db, async (transaction) => {
    const ref = doc(db, 'listings', id);
    const current = await transaction.get(ref);
    if (!current.exists()) return 'notFound';
    if (current.data().ownerId !== uid) return 'notYours';
    transaction.delete(ref);
    return null;
  });
}

/// A listing by [owner], created through the app's own write.
const ownListing = (owner = ME) => createListing(dbAs(owner), listingData(owner));

describe('listings: app flows the rules must allow', () => {
  test('a member publishes a listing of their own', async () => {
    const id = await assertSucceeds(ownListing());

    const stored = await read(`listings/${id}`);
    assert.equal(stored.ownerId, ME);
    assert.ok(stored.createdAt && stored.updatedAt, 'timestamps are set');
    assert.equal('isSaved' in stored, false);
  });

  test('any signed-in member can open one listing or browse them all', async () => {
    const id = await ownListing();
    await ownListing(OTHER);

    await assertSucceeds(getDoc(doc(dbAs(OTHER), 'listings', id)));
    await assertSucceeds(getDocs(collection(dbAs(OTHER), 'listings')));
    // Opening a deleted listing reads nothing, without an error.
    await assertSucceeds(getDoc(doc(dbAs(OTHER), 'listings', 'missing')));
  });

  test('the owner edits, pauses and resumes their listing', async () => {
    const db = dbAs(ME);
    const id = await ownListing();
    const createdAt = (await read(`listings/${id}`)).createdAt;

    const edited = listingData(ME, { city: 'Riyadh', sessionsMinutes: 90 });
    assert.equal(await assertSucceeds(updateListing(db, ME, id, edited)), null);
    await assertSucceeds(updateListing(db, ME, id, { ...edited, isPaused: true }));
    await assertSucceeds(updateListing(db, ME, id, { ...edited, isPaused: false }));

    const stored = await read(`listings/${id}`);
    assert.equal(stored.city, 'Riyadh');
    assert.equal(stored.sessionsMinutes, 90);
    assert.equal(stored.isPaused, false);
    assert.ok(stored.createdAt.isEqual(createdAt), 'createdAt is kept');
  });

  test('saving without changes is allowed', async () => {
    const id = await ownListing();

    await assertSucceeds(updateListing(dbAs(ME), ME, id, listingData(ME)));
  });

  test('the owner deletes their listing', async () => {
    const id = await ownListing();

    assert.equal(await assertSucceeds(deleteListing(dbAs(ME), ME, id)), null);
    assert.equal(await read(`listings/${id}`), undefined);
  });

  test('an older listing with leftover and missing fields can be edited', async () => {
    await seed({
      'listings/old': {
        ownerId: ME,
        category: 'Cooking',
        offers: 'Baking',
        isSaved: true,
        sessionsMinutes: 60,
      },
    });

    // The app writes every listing field, completing the old record.
    await assertSucceeds(
      updateListing(dbAs(ME), ME, 'old', listingData(ME, { category: 'Cooking', offers: 'Baking' })),
    );

    const stored = await read('listings/old');
    assert.equal(stored.title, 'Learn Arabic calligraphy');
    assert.equal(stored.isSaved, true, 'the leftover field is untouched');
  });
});

describe('listings: access the rules must refuse', () => {
  test('signed-out visitors can neither read nor write listings', async () => {
    const id = await ownListing();
    const db = anonymousDb();

    await assertFails(getDoc(doc(db, 'listings', id)));
    await assertFails(getDocs(collection(db, 'listings')));
    await assertFails(createListing(db, listingData(ME)));
    await assertFails(updateDoc(doc(db, 'listings', id), { title: 'Changed' }));
    await assertFails(deleteDoc(doc(db, 'listings', id)));
  });

  test('a listing cannot be published for another member', async () => {
    await assertFails(createListing(dbAs(ME), listingData(OTHER)));
    await assertFails(createListing(dbAs(ME), listingData('')));
  });

  test('another member cannot edit or delete the listing', async () => {
    const id = await ownListing();
    const db = dbAs(OTHER);

    // As the app would (it stops itself), and as writes that skip the check.
    assert.equal(await updateListing(db, OTHER, id, listingData(OTHER)), 'notYours');
    assert.equal(await deleteListing(db, OTHER, id), 'notYours');
    await assertFails(updateListing(db, ME, id, listingData(ME, { title: 'Hijacked' })));
    await assertFails(
      updateDoc(doc(db, 'listings', id), { title: 'Hijacked', updatedAt: serverTimestamp() }),
    );
    await assertFails(deleteListing(db, ME, id));
    await assertFails(deleteDoc(doc(db, 'listings', id)));

    assert.equal((await read(`listings/${id}`)).title, 'Learn Arabic calligraphy');
  });

  test('another member cannot take over a listing by naming themselves', async () => {
    const id = await ownListing();

    await assertFails(
      updateDoc(doc(dbAs(OTHER), 'listings', id), {
        ownerId: OTHER,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('the owner cannot hand the listing to someone else', async () => {
    const id = await ownListing();

    await assertFails(updateListing(dbAs(ME), ME, id, listingData(OTHER)));
    await assertFails(
      updateDoc(doc(dbAs(ME), 'listings', id), { ownerId: OTHER, updatedAt: serverTimestamp() }),
    );
    assert.equal((await read(`listings/${id}`)).ownerId, ME);
  });

  test('a member cannot overwrite a listing that is not theirs', async () => {
    const id = await ownListing();

    // A plain set over an existing listing is an update by a non-owner.
    await assertFails(
      setDoc(doc(dbAs(OTHER), 'listings', id), {
        ...listingData(OTHER),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('listings: data the rules must refuse', () => {
  test('isSaved is never stored on a shared listing', async () => {
    await assertFails(createListing(dbAs(ME), listingData(ME, { isSaved: true })));
    await assertFails(createListing(dbAs(ME), listingData(ME, { isSaved: false })));

    const id = await ownListing();
    await assertFails(updateListing(dbAs(ME), ME, id, listingData(ME, { isSaved: true })));
    await assertFails(
      updateDoc(doc(dbAs(ME), 'listings', id), { isSaved: true, updatedAt: serverTimestamp() }),
    );
  });

  test('only the listing fields can be stored', async () => {
    await assertFails(createListing(dbAs(ME), listingData(ME, { featured: true })));
    await assertFails(createListing(dbAs(ME), listingData(ME, { id: 'l-1' })));

    const id = await ownListing();
    await assertFails(updateListing(dbAs(ME), ME, id, listingData(ME, { featured: true })));
  });

  test('every listing field is required', async () => {
    for (const field of ['category', 'title', 'offers', 'wants', 'city', 'sessionsMinutes', 'isPaused']) {
      const data = listingData(ME);
      delete data[field];
      await assertFails(createListing(dbAs(ME), data), `missing ${field} must be refused`);
    }
  });

  test('fields must have the right types', async () => {
    for (const bad of [
      { category: 7 },
      { title: ['Learn'] },
      { offers: null },
      { wants: true },
      { distance: 2 },
      { description: { text: 'x' } },
      { city: 1 },
      { availability: 5 },
      { sessionsMinutes: '60' },
      { sessionsMinutes: 60.5 },
      { onlineOnly: 'yes' },
      { womenOnly: 1 },
      { isPaused: 'no' },
    ]) {
      await assertFails(
        createListing(dbAs(ME), listingData(ME, bad)),
        `${JSON.stringify(bad)} must be refused`,
      );
    }
  });

  test('text and session length must be within bounds', async () => {
    for (const bad of [
      { category: '' },
      { title: '' },
      { title: 'x'.repeat(101) },
      { offers: '' },
      { offers: 'x'.repeat(61) },
      { wants: '' },
      { city: '' },
      { description: 'x'.repeat(1001) },
      { sessionsMinutes: 10 },
      { sessionsMinutes: 481 },
    ]) {
      await assertFails(
        createListing(dbAs(ME), listingData(ME, bad)),
        `${JSON.stringify(bad)} must be refused`,
      );
    }
    // The longest allowed values are still accepted.
    await assertSucceeds(
      createListing(dbAs(ME), listingData(ME, { title: 'x'.repeat(100), sessionsMinutes: 480 })),
    );
  });

  test('an edit must keep the fields valid', async () => {
    const id = await ownListing();
    const db = dbAs(ME);

    await assertFails(updateListing(db, ME, id, listingData(ME, { sessionsMinutes: 'long' })));
    await assertFails(updateListing(db, ME, id, listingData(ME, { title: '' })));
    await assertFails(
      updateDoc(doc(db, 'listings', id), { onlineOnly: 'yes', updatedAt: serverTimestamp() }),
    );
  });

  test('timestamps come from the server and createdAt never changes', async () => {
    const madeUp = new Date(2020, 0, 1);
    await assertFails(
      setDoc(doc(collection(dbAs(ME), 'listings')), {
        ...listingData(ME),
        createdAt: madeUp,
        updatedAt: serverTimestamp(),
      }),
    );
    // Without the timestamps at all.
    await assertFails(setDoc(doc(collection(dbAs(ME), 'listings')), listingData(ME)));

    const id = await ownListing();
    await assertFails(
      updateDoc(doc(dbAs(ME), 'listings', id), {
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(dbAs(ME), 'listings', id), { title: 'No time', updatedAt: madeUp }));
    await assertFails(updateDoc(doc(dbAs(ME), 'listings', id), { title: 'No time' }));
  });
});

// ---------------------------------------------------------------------------
// Saved listings: users/{uid}/saved/{listingId}

const savedRef = (db, uid, listingId) => doc(db, 'users', uid, 'saved', listingId);

/// Mirrors FirebaseSavedListingsRepository.save.
const saveListing = (db, uid, listingId) =>
  setDoc(savedRef(db, uid, listingId), { listingId, savedAt: serverTimestamp() });

/// Mirrors FirebaseSavedListingsRepository.unsave.
const unsaveListing = (db, uid, listingId) => deleteDoc(savedRef(db, uid, listingId));

/// Mirrors FirebaseSavedListingsRepository.fetchSavedIds.
async function fetchSavedIds(db, uid) {
  const snapshot = await getDocs(collection(db, 'users', uid, 'saved'));
  return snapshot.docs.map((item) => item.id).sort();
}

describe('saved listings: what the rules must allow', () => {
  test('a member saves a listing, sees it, and unsaves it', async () => {
    const id = await ownListing(OTHER);
    const db = dbAs(ME);

    await assertSucceeds(saveListing(db, ME, id));
    assert.deepEqual(await assertSucceeds(fetchSavedIds(db, ME)), [id]);
    await assertSucceeds(getDoc(savedRef(db, ME, id)));
    const stored = await read(`users/${ME}/saved/${id}`);
    assert.deepEqual(Object.keys(stored).sort(), ['listingId', 'savedAt']);

    await assertSucceeds(unsaveListing(db, ME, id));
    assert.deepEqual(await fetchSavedIds(db, ME), []);
  });

  test('saving the same listing again is allowed', async () => {
    const id = await ownListing(OTHER);

    await saveListing(dbAs(ME), ME, id);
    await assertSucceeds(saveListing(dbAs(ME), ME, id));
  });

  test('each member has their own saved listings', async () => {
    const first = await ownListing(OTHER);
    const second = await ownListing(OTHER);

    await saveListing(dbAs(ME), ME, first);
    await saveListing(dbAs(THIRD), THIRD, second);

    assert.deepEqual(await fetchSavedIds(dbAs(ME), ME), [first]);
    assert.deepEqual(await fetchSavedIds(dbAs(THIRD), THIRD), [second]);
  });

  test('a saved listing that was deleted can still be unsaved', async () => {
    const id = await ownListing(OTHER);
    await saveListing(dbAs(ME), ME, id);
    await deleteListing(dbAs(OTHER), OTHER, id);

    await assertSucceeds(unsaveListing(dbAs(ME), ME, id));
    // Unsaving something not saved is harmless too.
    await assertSucceeds(unsaveListing(dbAs(ME), ME, 'never-saved'));
  });

  test('saving never touches the shared listing', async () => {
    const id = await ownListing(OTHER);
    const before = await read(`listings/${id}`);

    await saveListing(dbAs(ME), ME, id);

    const after = await read(`listings/${id}`);
    assert.equal('isSaved' in after, false);
    assert.ok(after.updatedAt.isEqual(before.updatedAt));
  });
});

describe('saved listings: what the rules must refuse', () => {
  test('signed-out visitors can do nothing with saved listings', async () => {
    const id = await ownListing(OTHER);
    await saveListing(dbAs(ME), ME, id);
    const db = anonymousDb();

    await assertFails(getDoc(savedRef(db, ME, id)));
    await assertFails(getDocs(collection(db, 'users', ME, 'saved')));
    await assertFails(saveListing(db, ME, id));
    await assertFails(unsaveListing(db, ME, id));
  });

  test("another member cannot read, add, change or remove someone's saved listings", async () => {
    const id = await ownListing(OTHER);
    await saveListing(dbAs(ME), ME, id);
    const db = dbAs(THIRD);

    await assertFails(getDoc(savedRef(db, ME, id)));
    await assertFails(getDocs(collection(db, 'users', ME, 'saved')));
    await assertFails(saveListing(db, ME, await ownListing(OTHER)));
    await assertFails(saveListing(db, ME, id));
    await assertFails(unsaveListing(db, ME, id));
    // Even the listing's owner has no say over who saved it.
    await assertFails(unsaveListing(dbAs(OTHER), ME, id));

    assert.deepEqual(await fetchSavedIds(dbAs(ME), ME), [id]);
  });

  test('a saved listing holds only its id and the server time', async () => {
    const id = await ownListing(OTHER);
    const db = dbAs(ME);

    for (const bad of [
      { listingId: id, savedAt: serverTimestamp(), note: 'x' },
      { listingId: id, savedAt: serverTimestamp(), isSaved: true },
      { listingId: id },
      { savedAt: serverTimestamp() },
      { listingId: 'another-listing', savedAt: serverTimestamp() },
      { listingId: 42, savedAt: serverTimestamp() },
      { listingId: id, savedAt: new Date(2020, 0, 1) },
    ]) {
      await assertFails(setDoc(savedRef(db, ME, id), bad), `${JSON.stringify(bad)} must be refused`);
    }
    // And the same rules hold when overwriting an existing save.
    await saveListing(db, ME, id);
    await assertFails(setDoc(savedRef(db, ME, id), { listingId: id, savedAt: serverTimestamp(), note: 'x' }));
  });

  test('only existing listings can be saved', async () => {
    await assertFails(saveListing(dbAs(ME), ME, 'no-such-listing'));
  });
});

// ---------------------------------------------------------------------------
// Account deletion cleanup

/// The batch size used by the repositories, below Firestore's 500 writes.
const DELETE_BATCH_SIZE = 400;

/// Deletes the documents [pageQuery] finds, a batch at a time, until none
/// are left: the loop shared by
/// FirebaseListingRepository.deleteAllListingsOf and
/// FirebaseSavedListingsRepository.unsaveAll. Resolves to the batch count.
async function deleteInBatches(db, pageQuery) {
  let batches = 0;
  while (true) {
    const page = await getDocs(query(pageQuery, limit(DELETE_BATCH_SIZE)));
    if (page.empty) return batches;
    const batch = writeBatch(db);
    page.docs.forEach((item) => batch.delete(item.ref));
    await batch.commit();
    batches++;
  }
}

/// Mirrors FirebaseListingRepository.deleteAllListingsOf.
const deleteAllListingsOf = (db, uid) =>
  deleteInBatches(db, query(collection(db, 'listings'), where('ownerId', '==', uid)));

/// Mirrors FirebaseSavedListingsRepository.unsaveAll.
const unsaveAll = (db, uid) => deleteInBatches(db, collection(db, 'users', uid, 'saved'));

/// Writes [count] listings of [owner] directly, as earlier sessions would
/// have, and returns their ids.
async function seedListings(owner, count) {
  const docs = {};
  for (let i = 0; i < count; i++) {
    docs[`listings/${owner}-${i}`] = { ...listingData(owner), createdAt: new Date(), updatedAt: new Date() };
  }
  await seed(docs);
  return Object.keys(docs).map((path) => path.split('/')[1]);
}

describe('account deletion cleanup', () => {
  test("the owner deletes all their listings, over several batches, and no one else's", async () => {
    await seedListings(ME, 450);
    const others = await seedListings(OTHER, 3);

    const batches = await assertSucceeds(deleteAllListingsOf(dbAs(ME), ME));

    assert.equal(batches, 2, 'more than one batch was needed');
    let remaining;
    await env.withSecurityRulesDisabled(async (context) => {
      remaining = (await getDocs(collection(context.firestore(), 'listings'))).docs.map((d) => d.id);
    });
    assert.deepEqual(remaining.sort(), others.sort());
  });

  test('the owner removes all their saved listings, over several batches, and no one else\'s', async () => {
    const [listingId] = await seedListings(OTHER, 1);
    const docs = {};
    for (let i = 0; i < 450; i++) {
      docs[`users/${ME}/saved/saved-${i}`] = { listingId: `saved-${i}`, savedAt: new Date() };
    }
    docs[`users/${THIRD}/saved/${listingId}`] = { listingId, savedAt: new Date() };
    await seed(docs);

    const batches = await assertSucceeds(unsaveAll(dbAs(ME), ME));

    assert.equal(batches, 2);
    assert.deepEqual(await fetchSavedIds(dbAs(ME), ME), []);
    assert.deepEqual(await fetchSavedIds(dbAs(THIRD), THIRD), [listingId]);
  });

  test('running the cleanup again after it finished is harmless', async () => {
    await seedListings(ME, 2);
    await deleteAllListingsOf(dbAs(ME), ME);

    assert.equal(await assertSucceeds(deleteAllListingsOf(dbAs(ME), ME)), 0);
    assert.equal(await assertSucceeds(unsaveAll(dbAs(ME), ME)), 0);
  });

  test("a batch reaching into another member's data is refused as a whole", async () => {
    const [mine] = await seedListings(ME, 1);
    const [theirs] = await seedListings(OTHER, 1);
    const db = dbAs(ME);

    const listingsBatch = writeBatch(db);
    listingsBatch.delete(doc(db, 'listings', mine));
    listingsBatch.delete(doc(db, 'listings', theirs));
    await assertFails(listingsBatch.commit());
    assert.ok(await read(`listings/${mine}`), 'nothing in the batch was deleted');
    assert.ok(await read(`listings/${theirs}`));

    await seed({ [`users/${OTHER}/saved/${mine}`]: { listingId: mine, savedAt: new Date() } });
    await assertFails(unsaveAll(db, OTHER));
    assert.ok(await read(`users/${OTHER}/saved/${mine}`));
  });

  test('signed-out visitors cannot run the cleanup', async () => {
    await seedListings(ME, 1);

    await assertFails(deleteAllListingsOf(anonymousDb(), ME));
    await assertFails(unsaveAll(anonymousDb(), ME));
  });
});

// ---------------------------------------------------------------------------
// Public profiles: publicProfiles/{uid}

const publicRef = (db, uid) => doc(db, 'publicProfiles', uid);

/// Writes only the public profile, as a client skipping the app would.
const writePublicOnly = (db, uid, data) =>
  setDoc(publicRef(db, uid), { ...data, updatedAt: serverTimestamp() });

/// A rich private profile, so hidden fields have something to hide.
const fullProfile = (username, extra = {}) =>
  profile(username, {
    bio: 'Teaches calligraphy.',
    skillsWanted: ['Piano'],
    availability: 'Weekends',
    ...extra,
  });

describe('public profiles: what the rules must allow', () => {
  test('signing up publishes a public profile without the phone', async () => {
    await assertSucceeds(saveProfile(dbAs(ME), ME, fullProfile('maha_z')));

    const shown = await read(`publicProfiles/${ME}`);
    assert.equal('phone' in shown, false);
    assert.equal('createdAt' in shown, false);
    assert.equal(shown.username, 'maha_z');
    assert.equal(shown.city, 'Jeddah');
    assert.deepEqual(shown.skillsWanted, ['Piano']);
    assert.equal(shown.isVerified, true);
  });

  test('any signed-in member can open a public profile', async () => {
    await saveProfile(dbAs(ME), ME, fullProfile('maha_z'));

    await assertSucceeds(getDoc(publicRef(dbAs(OTHER), ME)));
    await assertSucceeds(getDoc(publicRef(dbAs(ME), ME)));
    await assertSucceeds(getDoc(publicRef(dbAs(OTHER), 'nobody')));
  });

  test('edits, skills and renames update the public profile with the private one', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    await assertSucceeds(
      saveProfile(db, ME, fullProfile('maha_z', { bio: 'New bio', skillsOffered: ['Calligraphy', 'Baking'] })),
    );
    await assertSucceeds(saveProfile(db, ME, fullProfile('Maha_Z')));
    await assertSucceeds(saveProfile(db, ME, fullProfile('maha_2')));

    const shown = await read(`publicProfiles/${ME}`);
    assert.equal(shown.username, 'maha_2');
    assert.equal(shown.bio, 'Teaches calligraphy.');
    assert.equal((await read('usernames/maha_2')).uid, ME);
  });

  test('a hidden profile shares only names and username', async () => {
    await assertSucceeds(saveProfile(dbAs(ME), ME, fullProfile('maha_z'), { showProfile: false }));

    const shown = await read(`publicProfiles/${ME}`);
    assert.equal(shown.firstName, 'Maha');
    assert.equal(shown.lastName, 'Alzahrani');
    assert.equal(shown.username, 'maha_z');
    assert.equal(shown.city, '');
    assert.equal(shown.bio, '');
    assert.deepEqual(shown.skillsOffered, []);
    assert.deepEqual(shown.skillsWanted, []);
    assert.equal(shown.availability, '');
  });

  test('a private location leaves the city out', async () => {
    await assertSucceeds(saveProfile(dbAs(ME), ME, fullProfile('maha_z'), { showLocation: false }));

    const shown = await read(`publicProfiles/${ME}`);
    assert.equal(shown.city, '');
    assert.equal(shown.bio, 'Teaches calligraphy.');
  });

  test('an account from before public profiles publishes on its next save', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'), {}, { publish: false });
    assert.equal(await read(`publicProfiles/${ME}`), undefined);

    await assertSucceeds(saveProfile(db, ME, fullProfile('maha_z')));

    assert.ok(await read(`publicProfiles/${ME}`));
  });

  test('deleting the account removes the public profile with the rest', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    await assertSucceeds(deleteProfile(db, ME));

    assert.equal(await read(`publicProfiles/${ME}`), undefined);
    assert.equal(await read(`users/${ME}`), undefined);
    assert.equal(await read('usernames/maha_z'), undefined);
  });

  test('an account that never published can still be deleted', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'), {}, { publish: false });

    await assertSucceeds(deleteProfile(db, ME));
  });

  test('without a phone sign-in, the profile is published as not verified', async () => {
    await assertSucceeds(
      saveProfile(dbWithoutPhoneAs(ME), ME, fullProfile('maha_z'), { isVerified: false }),
    );

    assert.equal((await read(`publicProfiles/${ME}`)).isVerified, false);
  });
});

describe('public profiles: what the rules must refuse', () => {
  test('signed-out visitors cannot read, and nobody can list, public profiles', async () => {
    await saveProfile(dbAs(ME), ME, fullProfile('maha_z'));

    await assertFails(getDoc(publicRef(anonymousDb(), ME)));
    await assertFails(getDocs(collection(dbAs(OTHER), 'publicProfiles')));
    await assertFails(getDocs(collection(dbAs(ME), 'publicProfiles')));
  });

  test('no public profile without a private profile', async () => {
    await assertFails(writePublicOnly(dbAs(ME), ME, publicData(ME, fullProfile('maha_z'))));
  });

  test('no public profile for a private profile that holds no claimed username', async () => {
    // A private profile written before claims, whose name nobody claimed.
    await seed({ [`users/${ME}`]: { ...fullProfile('maha_z'), id: ME } });

    await assertFails(writePublicOnly(dbAs(ME), ME, publicData(ME, fullProfile('maha_z'))));
  });

  test('once the private profile is valid, the public one may be republished on its own', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    await assertSucceeds(
      writePublicOnly(db, ME, publicData(ME, fullProfile('maha_z'), { showProfile: false })),
    );
  });

  test('the phone, or anything extra, is never published', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));
    const shown = publicData(ME, fullProfile('maha_z'));

    await assertFails(writePublicOnly(db, ME, { ...shown, phone: '512345678' }));
    await assertFails(writePublicOnly(db, ME, { ...shown, createdAt: new Date() }));
    await assertFails(writePublicOnly(db, ME, { ...shown, admin: true }));
    const { bio, ...withoutBio } = shown;
    assert.equal(bio, 'Teaches calligraphy.');
    await assertFails(writePublicOnly(db, ME, withoutBio));
  });

  test('nothing can be shown that the private profile does not hold', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));
    await saveProfile(dbAs(OTHER), OTHER, fullProfile('sami'));
    const shown = publicData(ME, fullProfile('maha_z'));

    for (const bad of [
      { firstName: 'Sami' },
      { lastName: 'Someone' },
      { username: 'sami' },
      { username: 'MAHA_Z' },
      { city: 'Riyadh' },
      { bio: 'Made up.' },
      { skillsOffered: ['Flutter'] },
      { skillsWanted: ['Piano', 'Oud lessons'] },
      { availability: 'Mornings' },
      { uid: OTHER },
      { firstName: 7 },
      { skillsOffered: 'Calligraphy' },
    ]) {
      await assertFails(writePublicOnly(db, ME, { ...shown, ...bad }), `${JSON.stringify(bad)} must be refused`);
    }
  });

  test("a member cannot write or delete someone else's public profile", async () => {
    await saveProfile(dbAs(ME), ME, fullProfile('maha_z'));
    const db = dbAs(OTHER);

    await assertFails(writePublicOnly(db, ME, publicData(ME, fullProfile('maha_z'), { showProfile: false })));
    await assertFails(deleteDoc(publicRef(db, ME)));
    assert.equal((await read(`publicProfiles/${ME}`)).bio, 'Teaches calligraphy.');
  });

  test('verified only means signed in with a phone number', async () => {
    const shown = publicData(ME, fullProfile('maha_z'));
    await saveProfile(dbAs(ME), ME, fullProfile('maha_z'));

    await assertFails(writePublicOnly(dbWithoutPhoneAs(ME), ME, { ...shown, isVerified: true }));
    await assertFails(writePublicOnly(dbAs(ME), ME, { ...shown, isVerified: false }));
    await assertFails(writePublicOnly(dbAs(ME), ME, { ...shown, isVerified: 'yes' }));
  });

  test('the update time comes from the server', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    await assertFails(
      setDoc(publicRef(db, ME), { ...publicData(ME, fullProfile('maha_z')), updatedAt: new Date(2020, 0, 1) }),
    );
    await assertFails(setDoc(publicRef(db, ME), publicData(ME, fullProfile('maha_z'))));
  });

  test('the private profile cannot be deleted while the public one stays', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    // Everything but the public profile, in one write.
    const batch = writeBatch(db);
    batch.delete(doc(db, 'usernames', 'maha_z'));
    batch.delete(doc(db, 'users', ME));
    await assertFails(batch.commit());
    assert.ok(await read(`users/${ME}`));
  });

  test('in one transaction, the public profile can only show the private one after it', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));

    // Publishing a new bio while the private profile keeps the old one.
    await assertFails(
      runTransaction(db, async (transaction) => {
        await transaction.get(doc(db, 'users', ME));
        transaction.set(doc(db, 'users', ME), { bio: 'Teaches calligraphy.' }, { merge: true });
        transaction.set(publicRef(db, ME), {
          ...publicData(ME, fullProfile('maha_z', { bio: 'Newer bio' })),
          updatedAt: serverTimestamp(),
        });
      }),
    );
    // The same change made to both in one transaction is fine.
    await assertSucceeds(
      runTransaction(db, async (transaction) => {
        await transaction.get(doc(db, 'users', ME));
        transaction.set(doc(db, 'users', ME), { bio: 'Newer bio' }, { merge: true });
        transaction.set(publicRef(db, ME), {
          ...publicData(ME, fullProfile('maha_z', { bio: 'Newer bio' })),
          updatedAt: serverTimestamp(),
        });
      }),
    );
  });
});

// ---------------------------------------------------------------------------
// Blocking: users/{uid}/blocked/{blockedUid}

const blockedRef = (db, uid, blockedUid) => doc(db, 'users', uid, 'blocked', blockedUid);

/// Mirrors FirebaseBlockedMembersRepository.block.
const blockMember = (db, uid, blockedUid) =>
  setDoc(blockedRef(db, uid, blockedUid), { blockedUid, blockedAt: serverTimestamp() });

/// Mirrors FirebaseBlockedMembersRepository.unblock.
const unblockMember = (db, uid, blockedUid) => deleteDoc(blockedRef(db, uid, blockedUid));

/// Mirrors FirebaseBlockedMembersRepository.fetchBlockedIds.
async function fetchBlockedIds(db, uid) {
  const snapshot = await getDocs(collection(db, 'users', uid, 'blocked'));
  return snapshot.docs.map((item) => item.id).sort();
}

/// Mirrors FirebaseBlockedMembersRepository.unblockAll.
const unblockAll = (db, uid) => deleteInBatches(db, collection(db, 'users', uid, 'blocked'));

/// Real accounts for [uids], as their private profiles.
async function seedAccounts(...uids) {
  const docs = {};
  for (const uid of uids) docs[`users/${uid}`] = { ...profile(`user_${uid.slice(-4)}`), id: uid };
  await seed(docs);
}

describe('blocking: what the rules must allow', () => {
  test('a member blocks, lists and unblocks someone', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    await assertSucceeds(blockMember(db, ME, OTHER));
    assert.deepEqual(await assertSucceeds(fetchBlockedIds(db, ME)), [OTHER]);
    await assertSucceeds(getDoc(blockedRef(db, ME, OTHER)));
    const stored = await read(`users/${ME}/blocked/${OTHER}`);
    assert.deepEqual(Object.keys(stored).sort(), ['blockedAt', 'blockedUid']);

    await assertSucceeds(unblockMember(db, ME, OTHER));
    assert.deepEqual(await fetchBlockedIds(db, ME), []);
  });

  test('blocking again is allowed', async () => {
    await seedAccounts(ME, OTHER);

    await blockMember(dbAs(ME), ME, OTHER);
    await assertSucceeds(blockMember(dbAs(ME), ME, OTHER));
  });

  test('each member has their own block list', async () => {
    await seedAccounts(ME, OTHER, THIRD);

    await blockMember(dbAs(ME), ME, OTHER);
    await blockMember(dbAs(THIRD), THIRD, ME);

    assert.deepEqual(await fetchBlockedIds(dbAs(ME), ME), [OTHER]);
    assert.deepEqual(await fetchBlockedIds(dbAs(THIRD), THIRD), [ME]);
  });

  test('someone whose account is gone can still be unblocked', async () => {
    await seedAccounts(ME, OTHER);
    await blockMember(dbAs(ME), ME, OTHER);
    await env.withSecurityRulesDisabled((context) =>
      deleteDoc(doc(context.firestore(), 'users', OTHER)),
    );

    await assertSucceeds(unblockMember(dbAs(ME), ME, OTHER));
    await assertSucceeds(unblockMember(dbAs(ME), ME, 'never-blocked'));
  });

  test('blocking never touches the blocked member or their data', async () => {
    await seedAccounts(ME, OTHER);
    const before = await read(`users/${OTHER}`);

    await blockMember(dbAs(ME), ME, OTHER);

    assert.deepEqual(await read(`users/${OTHER}`), before);
    assert.deepEqual(await fetchBlockedIds(dbAs(OTHER), OTHER), []);
  });
});

describe('blocking: what the rules must refuse', () => {
  test('signed-out visitors can do nothing with block lists', async () => {
    await seedAccounts(ME, OTHER);
    await blockMember(dbAs(ME), ME, OTHER);
    const db = anonymousDb();

    await assertFails(getDoc(blockedRef(db, ME, OTHER)));
    await assertFails(getDocs(collection(db, 'users', ME, 'blocked')));
    await assertFails(blockMember(db, ME, OTHER));
    await assertFails(unblockMember(db, ME, OTHER));
  });

  test("another member cannot read, add to, change or remove someone's block list", async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await blockMember(dbAs(ME), ME, OTHER);

    for (const db of [dbAs(OTHER), dbAs(THIRD)]) {
      await assertFails(getDoc(blockedRef(db, ME, OTHER)));
      await assertFails(getDocs(collection(db, 'users', ME, 'blocked')));
      await assertFails(blockMember(db, ME, THIRD));
      await assertFails(blockMember(db, ME, OTHER));
      await assertFails(unblockMember(db, ME, OTHER));
    }
    assert.deepEqual(await fetchBlockedIds(dbAs(ME), ME), [OTHER]);
  });

  test('a member cannot block themselves', async () => {
    await seedAccounts(ME);

    await assertFails(blockMember(dbAs(ME), ME, ME));
  });

  test('only real accounts can be blocked', async () => {
    await seedAccounts(ME);

    await assertFails(blockMember(dbAs(ME), ME, 'no-such-account'));
    await assertFails(blockMember(dbAs(ME), ME, 'm-sami'));
    await assertFails(blockMember(dbAs(ME), ME, 'me'));
  });

  test('a block holds only the blocked uid and the server time', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const db = dbAs(ME);

    for (const bad of [
      { blockedUid: OTHER, blockedAt: serverTimestamp(), note: 'x' },
      { blockedUid: OTHER },
      { blockedAt: serverTimestamp() },
      { blockedUid: THIRD, blockedAt: serverTimestamp() },
      { blockedUid: 42, blockedAt: serverTimestamp() },
      { blockedUid: OTHER, blockedAt: new Date(2020, 0, 1) },
    ]) {
      await assertFails(setDoc(blockedRef(db, ME, OTHER), bad), `${JSON.stringify(bad)} must be refused`);
    }
    // The same holds when overwriting an existing block.
    await blockMember(db, ME, OTHER);
    await assertFails(
      setDoc(blockedRef(db, ME, OTHER), { blockedUid: OTHER, blockedAt: serverTimestamp(), note: 'x' }),
    );
  });

  test('an overlong id is refused', async () => {
    await seedAccounts(ME);
    const long = 'x'.repeat(129);
    await seed({ [`users/${long}`]: { ...profile('long_one'), id: long } });

    await assertFails(blockMember(dbAs(ME), ME, long));
  });
});

describe('blocking: account deletion cleanup', () => {
  test('removes all of the member\'s 450 blocks, over several batches, and no one else\'s', async () => {
    const docs = {};
    for (let i = 0; i < 450; i++) {
      docs[`users/${ME}/blocked/blocked-${i}`] = { blockedUid: `blocked-${i}`, blockedAt: new Date() };
    }
    docs[`users/${OTHER}/blocked/${ME}`] = { blockedUid: ME, blockedAt: new Date() };
    docs[`users/${THIRD}/blocked/${OTHER}`] = { blockedUid: OTHER, blockedAt: new Date() };
    await seed(docs);

    const batches = await assertSucceeds(unblockAll(dbAs(ME), ME));

    assert.equal(batches, 2, 'more than one batch was needed');
    assert.deepEqual(await fetchBlockedIds(dbAs(ME), ME), []);
    // Others' block lists, including blocks of the deleted member, remain.
    assert.deepEqual(await fetchBlockedIds(dbAs(OTHER), OTHER), [ME]);
    assert.deepEqual(await fetchBlockedIds(dbAs(THIRD), THIRD), [OTHER]);
  });

  test('running it again is harmless, and it cannot reach another list', async () => {
    await seed({ [`users/${OTHER}/blocked/${THIRD}`]: { blockedUid: THIRD, blockedAt: new Date() } });

    assert.equal(await assertSucceeds(unblockAll(dbAs(ME), ME)), 0);
    await assertFails(unblockAll(dbAs(ME), OTHER));
    assert.deepEqual(await fetchBlockedIds(dbAs(OTHER), OTHER), [THIRD]);
  });
});

// ---------------------------------------------------------------------------
// Reports: reports/{reportId}

const reportsOf = (db) => collection(db, 'reports');

/// Mirrors ReportDocument.reportIdFor: fixed for member and trade reports.
function reportIdFor(uid, report) {
  const target = report.kind === 'memberReport' ? report.memberId : report.tradeId;
  return report.kind === 'complaint' ? null : `${uid}_${report.kind}_${target}`;
}

/// Mirrors ReportDocument.toData plus the server time.
function reportData(uid, report) {
  return { reporterId: uid, status: 'submitted', ...report, createdAt: serverTimestamp() };
}

/// Mirrors FirebaseReportRepository.createReport: looks for a duplicate
/// among the reporter's own reports, then writes. Resolves to the id, or
/// 'duplicate' when found.
async function createReport(db, uid, report) {
  const id = reportIdFor(uid, report);
  let ref;
  if (id === null) {
    ref = doc(reportsOf(db));
  } else {
    const field = report.kind === 'memberReport' ? 'memberId' : 'tradeId';
    const existing = await getDocs(
      query(
        reportsOf(db),
        where('reporterId', '==', uid),
        where('kind', '==', report.kind),
        where(field, '==', report[field]),
        limit(1),
      ),
    );
    if (!existing.empty) return 'duplicate';
    ref = doc(db, 'reports', id);
  }
  await setDoc(ref, reportData(uid, report));
  return ref.id;
}

/// Mirrors FirebaseReportRepository.fetchMyReports.
async function fetchMyReports(db, uid) {
  const snapshot = await getDocs(query(reportsOf(db), where('reporterId', '==', uid), limit(200)));
  return snapshot.docs.map((item) => item.id).sort();
}

const memberReport = (memberId, extra = {}) => ({ kind: 'memberReport', reason: 'Spam or scam', memberId, ...extra });
const tradeReport = (tradeId, kind = 'tradeReport') => ({ kind, reason: 'Member did not attend', tradeId });
const complaint = (extra = {}) => ({ kind: 'complaint', reason: 'A trade', ...extra });

/// Writes [data] straight to reports/[id], skipping the app's own checks.
const writeReport = (db, id, data) => setDoc(doc(db, 'reports', id), data);

describe('reports: what the rules must allow', () => {
  test('a member reports another member, then reads and lists it', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    const id = await assertSucceeds(createReport(db, ME, memberReport(OTHER, { details: 'Asked for money.' })));

    assert.equal(id, `${ME}_memberReport_${OTHER}`);
    await assertSucceeds(getDoc(doc(db, 'reports', id)));
    assert.deepEqual(await assertSucceeds(fetchMyReports(db, ME)), [id]);
    const stored = await read(`reports/${id}`);
    assert.equal(stored.reporterId, ME);
    assert.equal(stored.status, 'submitted');
    assert.equal(stored.details, 'Asked for money.');
    assert.ok(stored.createdAt);
  });

  test('trade reports, disputes and complaints can be sent', async () => {
    await seedAccounts(ME);
    const db = dbAs(ME);

    assert.equal(await assertSucceeds(createReport(db, ME, tradeReport('t-sami'))), `${ME}_tradeReport_t-sami`);
    assert.equal(
      await assertSucceeds(createReport(db, ME, tradeReport('t-sami', 'tradeDispute'))),
      `${ME}_tradeDispute_t-sami`,
    );
    const first = await assertSucceeds(createReport(db, ME, complaint()));
    const second = await assertSucceeds(createReport(db, ME, complaint({ details: 'Again.' })));
    assert.notEqual(first, second, 'complaints get their own ids');
    assert.equal((await fetchMyReports(db, ME)).length, 4);
  });

  test('each member only finds their own reports', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await createReport(dbAs(ME), ME, memberReport(THIRD));
    await createReport(dbAs(OTHER), OTHER, memberReport(THIRD));

    assert.deepEqual(await fetchMyReports(dbAs(ME), ME), [`${ME}_memberReport_${THIRD}`]);
    assert.deepEqual(await fetchMyReports(dbAs(OTHER), OTHER), [`${OTHER}_memberReport_${THIRD}`]);
  });

  test('reports stay after the reporter and the reported member are gone', async () => {
    await seedAccounts(ME, OTHER);
    const id = await createReport(dbAs(ME), ME, memberReport(OTHER));
    await env.withSecurityRulesDisabled(async (context) => {
      await deleteDoc(doc(context.firestore(), 'users', ME));
      await deleteDoc(doc(context.firestore(), 'users', OTHER));
    });

    assert.ok(await read(`reports/${id}`));
  });
});

describe('reports: what the rules must refuse', () => {
  test('an unfiltered list of reports', async () => {
    await seedAccounts(ME, OTHER);
    await createReport(dbAs(ME), ME, memberReport(OTHER));

    await assertFails(getDocs(reportsOf(dbAs(ME))));
    await assertFails(getDocs(query(reportsOf(dbAs(ME)), limit(5))));
  });

  test('looking a report up by id cannot tell whether it exists', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await createReport(dbAs(OTHER), OTHER, memberReport(THIRD));

    // Someone else's report, and one that does not exist, are both refused,
    // so nobody can find out who reported whom by guessing ids.
    await assertFails(getDoc(doc(dbAs(ME), 'reports', `${OTHER}_memberReport_${THIRD}`)));
    await assertFails(getDoc(doc(dbAs(ME), 'reports', `${OTHER}_memberReport_${ME}`)));
    await assertFails(
      getDocs(query(reportsOf(dbAs(ME)), where(documentId(), '==', `${OTHER}_memberReport_${THIRD}`))),
    );
  });

  test("another member cannot read, list, change or delete someone's reports", async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const id = await createReport(dbAs(ME), ME, memberReport(THIRD));
    const db = dbAs(OTHER);

    await assertFails(getDoc(doc(db, 'reports', id)));
    await assertFails(getDocs(query(reportsOf(db), where('reporterId', '==', ME))));
    await assertFails(updateDoc(doc(db, 'reports', id), { status: 'resolved' }));
    await assertFails(deleteDoc(doc(db, 'reports', id)));
    // The reported member cannot see it either.
    await assertFails(getDoc(doc(dbAs(THIRD), 'reports', id)));
  });

  test('signed-out visitors can do nothing with reports', async () => {
    await seedAccounts(ME, OTHER);
    const id = await createReport(dbAs(ME), ME, memberReport(OTHER));
    const db = anonymousDb();

    await assertFails(getDoc(doc(db, 'reports', id)));
    await assertFails(getDocs(query(reportsOf(db), where('reporterId', '==', ME))));
    await assertFails(writeReport(db, 'anything', reportData(ME, complaint())));
  });

  test('the reporter can neither change nor delete their own report', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    const id = await createReport(db, ME, memberReport(OTHER));

    await assertFails(updateDoc(doc(db, 'reports', id), { status: 'resolved' }));
    await assertFails(updateDoc(doc(db, 'reports', id), { details: 'Changed my mind.' }));
    await assertFails(deleteDoc(doc(db, 'reports', id)));
  });

  test('a second report of the same target is refused', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    await createReport(db, ME, memberReport(OTHER));
    await createReport(db, ME, tradeReport('t-sami'));

    // The app finds it first; a direct write over it is refused too.
    assert.equal(await createReport(db, ME, memberReport(OTHER)), 'duplicate');
    await assertFails(
      writeReport(db, `${ME}_memberReport_${OTHER}`, reportData(ME, memberReport(OTHER, { reason: 'Harassment' }))),
    );
    await assertFails(writeReport(db, `${ME}_tradeReport_t-sami`, reportData(ME, tradeReport('t-sami'))));
  });

  test('a report must be sent as oneself', async () => {
    await seedAccounts(ME, OTHER, THIRD);

    await assertFails(
      writeReport(dbAs(ME), `${OTHER}_memberReport_${THIRD}`, reportData(OTHER, memberReport(THIRD))),
    );
    await assertFails(writeReport(dbAs(ME), 'forged-complaint', reportData(OTHER, complaint())));
  });

  test('nobody can report themselves', async () => {
    await seedAccounts(ME);

    await assertFails(writeReport(dbAs(ME), `${ME}_memberReport_${ME}`, reportData(ME, memberReport(ME))));
  });

  test('only real accounts can be reported, never demo or made-up ids', async () => {
    await seedAccounts(ME);
    const db = dbAs(ME);

    for (const member of ['no-such-account', 'm-sami', 'me']) {
      await assertFails(
        writeReport(db, `${ME}_memberReport_${member}`, reportData(ME, memberReport(member))),
        `${member} must be refused`,
      );
    }
  });

  test('member and trade reports must use their fixed id', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    await assertFails(writeReport(db, 'any-id', reportData(ME, memberReport(OTHER))));
    await assertFails(writeReport(db, `${ME}_memberReport_${THIRD}`, reportData(ME, memberReport(OTHER))));
    await assertFails(writeReport(db, `${ME}_tradeReport_t-other`, reportData(ME, tradeReport('t-sami'))));
    await assertFails(
      writeReport(db, `${ME}_tradeReport_t-sami`, reportData(ME, tradeReport('t-sami', 'tradeDispute'))),
    );
  });

  test('unknown kinds and mismatched targets are refused', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    await assertFails(writeReport(db, 'odd', reportData(ME, { kind: 'praise', reason: 'Lovely' })));
    await assertFails(
      writeReport(db, `${ME}_memberReport_${OTHER}`, reportData(ME, memberReport(OTHER, { tradeId: 't-sami' }))),
    );
    await assertFails(writeReport(db, 'complaint-1', reportData(ME, complaint({ memberId: OTHER }))));
    await assertFails(writeReport(db, 'complaint-2', reportData(ME, complaint({ tradeId: 't-sami' }))));
    await assertFails(writeReport(db, `${ME}_tradeReport_bad id`, reportData(ME, tradeReport('bad id'))));
  });

  test('only the report fields, with valid values, are accepted', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    const id = `${ME}_memberReport_${OTHER}`;

    for (const bad of [
      { priority: 'high' },
      { details: 42 },
      { details: 'x'.repeat(501) },
      { reason: '' },
      { reason: 'x'.repeat(61) },
      { reason: 7 },
      { status: 'resolved' },
      { createdAt: new Date(2020, 0, 1) },
      { listingId: 'bad listing id' },
    ]) {
      await assertFails(
        writeReport(db, id, { ...reportData(ME, memberReport(OTHER)), ...bad }),
        `${JSON.stringify(bad)} must be refused`,
      );
    }
    const { createdAt, ...withoutTime } = reportData(ME, memberReport(OTHER));
    assert.ok(createdAt);
    await assertFails(writeReport(db, id, withoutTime));
    // The longest details and a listing id are fine.
    await assertSucceeds(
      writeReport(db, id, reportData(ME, memberReport(OTHER, { details: 'x'.repeat(500), listingId: 'sami-1' }))),
    );
  });
});

// ---------------------------------------------------------------------------
// Public profile switch on public profiles

describe('public profiles: the Public profile switch', () => {
  test('a hidden profile is published with the switch off', async () => {
    await assertSucceeds(saveProfile(dbAs(ME), ME, fullProfile('maha_z'), { showProfile: false }));

    assert.equal((await read(`publicProfiles/${ME}`)).profileVisible, false);
  });

  test('the switch is required, and a hidden profile cannot show more', async () => {
    const db = dbAs(ME);
    await saveProfile(db, ME, fullProfile('maha_z'));
    const shown = publicData(ME, fullProfile('maha_z'));
    const { profileVisible, ...withoutSwitch } = shown;
    assert.equal(profileVisible, true);

    await assertFails(writePublicOnly(db, ME, withoutSwitch));
    await assertFails(writePublicOnly(db, ME, { ...shown, profileVisible: 'yes' }));
    // Switched off, yet still showing the bio and skills.
    await assertFails(writePublicOnly(db, ME, { ...shown, profileVisible: false }));
    await assertSucceeds(
      writePublicOnly(db, ME, publicData(ME, fullProfile('maha_z'), { showProfile: false })),
    );
  });
});

// ---------------------------------------------------------------------------
// Reviews: reviews/{reviewId}

const reviewsOf = (db) => collection(db, 'reviews');

/// What ReviewDocument.toData stores, plus the server time.
function reviewData(uid, subjectId, extra = {}) {
  return {
    reviewerId: uid,
    subjectId,
    rating: 5,
    tags: ['On time', 'Friendly'],
    contextId: 't-sami',
    contextKind: 'trade',
    skillTitle: 'UI design',
    ...extra,
    createdAt: serverTimestamp(),
  };
}

/// Mirrors FirebaseReviewRepository.createReview: looks for the reviewer's
/// own earlier review of the same member, then writes it. Resolves to the
/// id, or 'duplicate'.
async function createReview(db, uid, subjectId, extra = {}) {
  const existing = await getDocs(
    query(reviewsOf(db), where('reviewerId', '==', uid), where('subjectId', '==', subjectId), limit(1)),
  );
  if (!existing.empty) return 'duplicate';
  const id = `${uid}_${subjectId}`;
  await setDoc(doc(db, 'reviews', id), reviewData(uid, subjectId, extra));
  return id;
}

/// Mirrors FirebaseReviewRepository.fetchReviewsAbout.
async function fetchReviewsAbout(db, subjectId) {
  const snapshot = await getDocs(query(reviewsOf(db), where('subjectId', '==', subjectId), limit(200)));
  return snapshot.docs.map((item) => item.id).sort();
}

/// Mirrors FirebaseReviewRepository.fetchReviewsBy.
async function fetchReviewsBy(db, uid) {
  const snapshot = await getDocs(query(reviewsOf(db), where('reviewerId', '==', uid), limit(200)));
  return snapshot.docs.map((item) => item.id).sort();
}

/// Publishes [uid]'s profile, with the Public profile switch on or off.
async function publishProfile(uid, username, { visible = true } = {}) {
  await saveProfile(dbAs(uid), uid, fullProfile(username), { showProfile: visible });
}

describe('reviews: what the rules must allow', () => {
  test('a member rates another member, once each way', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a');

    assert.equal(await assertSucceeds(createReview(dbAs(ME), ME, OTHER)), `${ME}_${OTHER}`);
    assert.equal(await assertSucceeds(createReview(dbAs(OTHER), OTHER, ME)), `${OTHER}_${ME}`);

    const stored = await read(`reviews/${ME}_${OTHER}`);
    assert.deepEqual(Object.keys(stored).sort(), [
      'contextId', 'contextKind', 'createdAt', 'rating', 'reviewerId', 'skillTitle', 'subjectId', 'tags',
    ]);
    assert.equal('phone' in stored, false);
  });

  test("anyone signed in can read a public member's reviews", async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a');
    await seedAccounts(THIRD);
    await createReview(dbAs(ME), ME, OTHER);

    assert.deepEqual(await assertSucceeds(fetchReviewsAbout(dbAs(THIRD), OTHER)), [`${ME}_${OTHER}`]);
    await assertSucceeds(getDoc(doc(dbAs(THIRD), 'reviews', `${ME}_${OTHER}`)));
  });

  test('a hidden member can still read their own reviews, and the reviewer theirs', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a', { visible: false });
    await createReview(dbAs(ME), ME, OTHER);

    assert.deepEqual(await assertSucceeds(fetchReviewsAbout(dbAs(OTHER), OTHER)), [`${ME}_${OTHER}`]);
    assert.deepEqual(await assertSucceeds(fetchReviewsBy(dbAs(ME), ME)), [`${ME}_${OTHER}`]);
    await assertSucceeds(getDoc(doc(dbAs(ME), 'reviews', `${ME}_${OTHER}`)));
  });

  test('reviews stay after either account is deleted', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a');
    await createReview(dbAs(ME), ME, OTHER);
    await createReview(dbAs(OTHER), OTHER, ME);

    await deleteProfile(dbAs(ME), ME);

    assert.ok(await read(`reviews/${ME}_${OTHER}`));
    assert.ok(await read(`reviews/${OTHER}_${ME}`));
  });
});

describe('reviews: what the rules must refuse', () => {
  test("others cannot read a hidden member's reviews", async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a', { visible: false });
    await seedAccounts(THIRD);
    await createReview(dbAs(ME), ME, OTHER);
    const db = dbAs(THIRD);

    await assertFails(fetchReviewsAbout(db, OTHER));
    await assertFails(getDoc(doc(db, 'reviews', `${ME}_${OTHER}`)));
  });

  test('reviews of a member without a public profile cannot be read by others', async () => {
    await publishProfile(ME, 'maha_z');
    await seedAccounts(OTHER, THIRD);
    await createReview(dbAs(ME), ME, OTHER);

    await assertFails(fetchReviewsAbout(dbAs(THIRD), OTHER));
  });

  test('switching the profile off hides reviews it showed before', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a');
    await seedAccounts(THIRD);
    await createReview(dbAs(ME), ME, OTHER);
    await assertSucceeds(fetchReviewsAbout(dbAs(THIRD), OTHER));

    await publishProfile(OTHER, 'sami_a', { visible: false });

    await assertFails(fetchReviewsAbout(dbAs(THIRD), OTHER));
  });

  test('unfiltered or unrelated lists of reviews', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a', { visible: false });
    await createReview(dbAs(ME), ME, OTHER);

    await assertFails(getDocs(reviewsOf(dbAs(THIRD))));
    await assertFails(getDocs(query(reviewsOf(dbAs(THIRD)), where('reviewerId', '==', ME))));
  });

  test('signed-out visitors can do nothing with reviews', async () => {
    await publishProfile(ME, 'maha_z');
    await publishProfile(OTHER, 'sami_a');
    await createReview(dbAs(ME), ME, OTHER);
    const db = anonymousDb();

    await assertFails(fetchReviewsAbout(db, OTHER));
    await assertFails(getDoc(doc(db, 'reviews', `${ME}_${OTHER}`)));
    await assertFails(setDoc(doc(db, 'reviews', `${ME}_${OTHER}`), reviewData(ME, OTHER)));
  });

  test('a review must be written as oneself, never about oneself', async () => {
    await seedAccounts(ME, OTHER, THIRD);

    await assertFails(setDoc(doc(dbAs(ME), 'reviews', `${OTHER}_${THIRD}`), reviewData(OTHER, THIRD)));
    // Under one's own id, but naming someone else as the reviewer.
    await assertFails(setDoc(doc(dbAs(ME), 'reviews', `${ME}_${THIRD}`), reviewData(OTHER, THIRD)));
    await assertFails(setDoc(doc(dbAs(ME), 'reviews', `${ME}_${ME}`), reviewData(ME, ME)));
  });

  test('only real accounts can be rated, never demo or made-up ids', async () => {
    await seedAccounts(ME);
    const db = dbAs(ME);

    for (const subject of ['no-such-account', 'm-sami', 'me']) {
      await assertFails(
        setDoc(doc(db, 'reviews', `${ME}_${subject}`), reviewData(ME, subject)),
        `${subject} must be refused`,
      );
    }
  });

  test('the id must be the reviewer and the rated member', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const db = dbAs(ME);

    await assertFails(setDoc(doc(db, 'reviews', 'any-id'), reviewData(ME, OTHER)));
    await assertFails(setDoc(doc(db, 'reviews', `${ME}_${THIRD}`), reviewData(ME, OTHER)));
    await assertFails(setDoc(doc(db, 'reviews', `${OTHER}_${ME}`), reviewData(ME, OTHER)));
  });

  test('a second review of the same member is refused', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    await createReview(db, ME, OTHER);

    assert.equal(await createReview(db, ME, OTHER, { rating: 1 }), 'duplicate');
    await assertFails(setDoc(doc(db, 'reviews', `${ME}_${OTHER}`), reviewData(ME, OTHER, { rating: 1 })));
    assert.equal((await read(`reviews/${ME}_${OTHER}`)).rating, 5);
  });

  test('ratings must be whole stars from 1 to 5', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    for (const rating of [0, 6, -1, 4.5, '5', null]) {
      await assertFails(
        setDoc(doc(db, 'reviews', `${ME}_${OTHER}`), reviewData(ME, OTHER, { rating })),
        `${rating} must be refused`,
      );
    }
    await assertSucceeds(setDoc(doc(db, 'reviews', `${ME}_${OTHER}`), reviewData(ME, OTHER, { rating: 1 })));
  });

  test('tags must be the offered ones, at most five, without repeats', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);

    for (const tags of [
      ['Rude'],
      ['On time', 'On time'],
      'On time',
      ['Great teacher', 'On time', 'Friendly', 'Well prepared', 'Would trade again', 'Extra'],
      [7],
    ]) {
      await assertFails(
        setDoc(doc(db, 'reviews', `${ME}_${OTHER}`), reviewData(ME, OTHER, { tags })),
        `${JSON.stringify(tags)} must be refused`,
      );
    }
    await assertSucceeds(
      setDoc(
        doc(db, 'reviews', `${ME}_${OTHER}`),
        reviewData(ME, OTHER, { tags: ['Great teacher', 'On time', 'Friendly', 'Well prepared', 'Would trade again'] }),
      ),
    );
  });

  test('only the review fields, with valid values, are accepted', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    const ref = doc(db, 'reviews', `${ME}_${OTHER}`);

    for (const bad of [
      { comment: 'Lovely' },
      { phone: '512345678' },
      { contextKind: 'listing' },
      { contextId: 'bad id' },
      { skillTitle: 'x'.repeat(101) },
      { createdAt: new Date(2020, 0, 1) },
    ]) {
      await assertFails(setDoc(ref, { ...reviewData(ME, OTHER), ...bad }), `${JSON.stringify(bad)} must be refused`);
    }
    const { contextId, ...withoutContext } = reviewData(ME, OTHER);
    assert.ok(contextId);
    await assertFails(setDoc(ref, withoutContext));
  });

  test('nobody can change or delete a review', async () => {
    await seedAccounts(ME, OTHER);
    await createReview(dbAs(ME), ME, OTHER);
    const ref = (db) => doc(db, 'reviews', `${ME}_${OTHER}`);

    for (const db of [dbAs(ME), dbAs(OTHER)]) {
      await assertFails(updateDoc(ref(db), { rating: 1 }));
      await assertFails(deleteDoc(ref(db)));
    }
  });
});

// Chats: conversations/{conversationId} and conversations/{id}/messages

const conversationIdOf = (a, b) => (a < b ? `dm_${a}_${b}` : `dm_${b}_${a}`);
const conversationRef = (db, a, b) => doc(db, 'conversations', conversationIdOf(a, b));

/// Mirrors FirebaseChatRepository.sendMessage: the message and its
/// conversation in one batch, the conversation merged. [message] and
/// [conversation] replace fields, and [conversationId] the chat written to,
/// for what must be refused. Resolves to the message id.
async function sendMessage(db, uid, memberId, text = 'Hello', { message = {}, conversation = {}, conversationId } = {}) {
  const chat = conversationId ? doc(db, 'conversations', conversationId) : conversationRef(db, uid, memberId);
  const messageRef = doc(collection(chat, 'messages'));
  const batch = writeBatch(db);
  batch.set(messageRef, { senderId: uid, text, kind: 'text', createdAt: serverTimestamp(), ...message });
  batch.set(
    chat,
    {
      kind: 'direct',
      participantIds: [uid, memberId].sort(),
      lastMessage: text,
      lastMessageId: messageRef.id,
      lastSenderId: uid,
      lastAt: serverTimestamp(),
      lastReadAt: { [uid]: serverTimestamp() },
      ...conversation,
    },
    { merge: true },
  );
  await batch.commit();
  return messageRef.id;
}

/// Mirrors FirebaseChatRepository.watchConversations (one snapshot of it).
async function fetchConversations(db, uid) {
  const snapshot = await getDocs(
    query(collection(db, 'conversations'), where('participantIds', 'array-contains', uid), limit(200)),
  );
  return snapshot.docs.map((item) => item.id).sort();
}

/// Mirrors FirebaseChatRepository.watchMessages (one snapshot of it):
/// the texts, oldest first.
async function fetchMessages(db, uid, memberId) {
  const snapshot = await getDocs(
    query(collection(conversationRef(db, uid, memberId), 'messages'), orderBy('createdAt', 'desc'), limit(200)),
  );
  return snapshot.docs.map((item) => item.data().text).reverse();
}

/// Mirrors FirebaseChatRepository.markConversationRead.
const markRead = (db, uid, memberId) =>
  updateDoc(conversationRef(db, uid, memberId), { [`lastReadAt.${uid}`]: serverTimestamp() });

const chatPath = (a, b) => `conversations/${conversationIdOf(a, b)}`;

describe('chats: what the rules must allow', () => {
  test('a member starts a chat, and both members can read it', async () => {
    await seedAccounts(ME, OTHER);
    await assertSucceeds(sendMessage(dbAs(ME), ME, OTHER, 'Hello'));

    assert.deepEqual(await fetchConversations(dbAs(ME), ME), [conversationIdOf(ME, OTHER)]);
    assert.deepEqual(await fetchConversations(dbAs(OTHER), OTHER), [conversationIdOf(ME, OTHER)]);
    assert.deepEqual(await fetchMessages(dbAs(OTHER), OTHER, ME), ['Hello']);
    await assertSucceeds(getDoc(conversationRef(dbAs(OTHER), OTHER, ME)));

    const stored = await read(chatPath(ME, OTHER));
    assert.deepEqual(stored.participantIds, [ME, OTHER].sort());
    assert.equal(stored.lastSenderId, ME);
    assert.deepEqual(Object.keys(stored.lastReadAt), [ME]);
  });

  test('the other member replies in the same chat, in order', async () => {
    await seedAccounts(ME, OTHER);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    await assertSucceeds(sendMessage(dbAs(OTHER), OTHER, ME, 'Hi back'));
    await assertSucceeds(sendMessage(dbAs(ME), ME, OTHER, 'How are you?'));

    assert.deepEqual(await fetchMessages(dbAs(ME), ME, OTHER), ['Hello', 'Hi back', 'How are you?']);
    const stored = await read(chatPath(ME, OTHER));
    assert.equal(stored.lastMessage, 'How are you?');
    assert.equal(stored.lastSenderId, ME);
    assert.deepEqual(Object.keys(stored.lastReadAt).sort(), [ME, OTHER].sort());
  });

  test('each member marks the chat read, changing only their own time', async () => {
    await seedAccounts(ME, OTHER);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    const before = await read(chatPath(ME, OTHER));

    await assertSucceeds(markRead(dbAs(OTHER), OTHER, ME));
    await assertSucceeds(markRead(dbAs(ME), ME, OTHER));

    const after = await read(chatPath(ME, OTHER));
    assert.ok(after.lastReadAt[OTHER]);
    assert.equal(after.lastMessage, before.lastMessage);
    assert.equal(after.lastMessageId, before.lastMessageId);
  });

  test('trade notes and proposal cards with safe references', async () => {
    await seedAccounts(ME, OTHER);
    await assertSucceeds(
      sendMessage(dbAs(ME), ME, OTHER, 'Session scheduled.', { message: { kind: 'system', tradeId: 'trade1' } }),
    );
    await assertSucceeds(
      sendMessage(dbAs(OTHER), OTHER, ME, 'Trade proposal', {
        message: { kind: 'proposal', proposalId: 'proposal1', tradeId: 'trade1' },
      }),
    );
  });

  test('a message of 1000 characters', async () => {
    await seedAccounts(ME, OTHER);
    await assertSucceeds(sendMessage(dbAs(ME), ME, OTHER, 'x'.repeat(1000)));
  });
});

describe('chats: what the rules must refuse', () => {
  test('nobody else can read a chat or its messages', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');

    const outsider = dbAs(THIRD);
    await assertFails(getDoc(conversationRef(outsider, ME, OTHER)));
    await assertFails(getDocs(collection(outsider, 'conversations')));
    await assertFails(getDocs(query(collection(outsider, 'conversations'), where('participantIds', 'array-contains', ME))));
    await assertFails(getDocs(collection(conversationRef(outsider, ME, OTHER), 'messages')));
    assert.deepEqual(await fetchConversations(outsider, THIRD), []);

    const anonymous = anonymousDb();
    await assertFails(getDoc(conversationRef(anonymous, ME, OTHER)));
    await assertFails(getDocs(collection(conversationRef(anonymous, ME, OTHER), 'messages')));
  });

  test('nobody can send as another member', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    // Another account writes the whole message as ME.
    await assertFails(sendMessage(dbAs(THIRD), ME, OTHER, 'Hello'));
    // A member writes a message signed by the other member.
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { message: { senderId: OTHER } }));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversation: { lastSenderId: OTHER } }));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversation: { lastReadAt: { [OTHER]: serverTimestamp() } } }));
    assert.equal(await read(chatPath(ME, OTHER)), undefined);
  });

  test('nobody can write into a chat they are not in', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    const theirs = conversationIdOf(ME, OTHER);

    // Into the existing chat of two others.
    await assertFails(sendMessage(dbAs(THIRD), THIRD, OTHER, 'Hi', { conversationId: theirs }));
    await assertFails(
      sendMessage(dbAs(THIRD), THIRD, OTHER, 'Hi', {
        conversationId: theirs,
        conversation: { participantIds: [ME, OTHER].sort() },
      }),
    );
    assert.deepEqual(await fetchMessages(dbAs(ME), ME, OTHER), ['Hello']);
  });

  test('a chat id is "dm_" and the two members sorted uids', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const [first, second] = [ME, OTHER].sort();
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversationId: `dm_${second}_${first}` }));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversationId: 'chat1' }));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversation: { participantIds: [second, first] } }));
    await assertFails(
      sendMessage(dbAs(ME), ME, OTHER, 'Hello', {
        conversationId: `dm_${first}_${second}_${THIRD}`,
        conversation: { participantIds: [first, second, THIRD] },
      }),
    );
    await assertFails(sendMessage(dbAs(ME), ME, ME, 'Hello', { conversationId: `dm_${ME}_${ME}` }));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello', { conversation: { kind: 'group' } }));
  });

  test('only real accounts can be messaged', async () => {
    await seedAccounts(ME);
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello'));
    await assertFails(sendMessage(dbAs(ME), ME, 'me', 'Hello'));
  });

  test('blocked members cannot message each other, either way', async () => {
    await seedAccounts(ME, OTHER);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');

    await seed({ [`users/${OTHER}/blocked/${ME}`]: { blockedUid: ME, blockedAt: new Date() } });
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Are you there?'));
    await assertFails(sendMessage(dbAs(OTHER), OTHER, ME, 'Bye'));

    await env.clearFirestore();
    await seedAccounts(ME, OTHER);
    await seed({ [`users/${ME}/blocked/${OTHER}`]: { blockedUid: OTHER, blockedAt: new Date() } });
    await assertFails(sendMessage(dbAs(OTHER), OTHER, ME, 'Hello'));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Hello'));
  });

  test('a deleted account cannot be messaged any more', async () => {
    await seedAccounts(ME, OTHER);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    await env.withSecurityRulesDisabled((context) => deleteDoc(doc(context.firestore(), 'users', OTHER)));
    await assertFails(sendMessage(dbAs(ME), ME, OTHER, 'Still there?'));
  });

  test('invalid message content is refused', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    for (const [text, change] of [
      ['', {}],
      ['   ', {}],
      ['x'.repeat(1001), {}],
      ['Hello', { message: { kind: 'image' } }],
      ['Hello', { message: { kind: 'proposal' } }],
      ['Hello', { message: { proposalId: 'proposal1' } }],
      ['Hello', { message: { tradeId: 'trade1' } }],
      ['Hello', { message: { kind: 'proposal', proposalId: 'bad id' } }],
      ['Hello', { message: { kind: 'system', tradeId: 'bad/id' } }],
      ['Hello', { message: { senderName: 'Maha' } }],
      ['Hello', { message: { phone: '512345678' } }],
      ['Hello', { message: { text: 42 } }],
      ['Hello', { message: { createdAt: new Date(2020, 0, 1) } }],
      ['Hello', { conversation: { lastAt: new Date(2020, 0, 1) } }],
      ['Hello', { conversation: { title: 'Maha and Sami' } }],
    ]) {
      await assertFails(sendMessage(db, ME, OTHER, text, change), `${JSON.stringify([text.slice(0, 10), change])} must be refused`);
    }
    assert.equal(await read(chatPath(ME, OTHER)), undefined);
  });

  test('a message is only sent together with its conversation', async () => {
    await seedAccounts(ME, OTHER);
    const db = dbAs(ME);
    const chat = conversationRef(db, ME, OTHER);
    const alone = (text) =>
      setDoc(doc(collection(chat, 'messages')), { senderId: ME, text, kind: 'text', createdAt: serverTimestamp() });

    // Before the chat exists, and after.
    await assertFails(alone('Hello'));
    const firstId = await sendMessage(db, ME, OTHER, 'Hello');
    await assertFails(alone('Sneaky'));
    // The conversation showing another text than the message's.
    await assertFails(sendMessage(db, ME, OTHER, 'Hello', { conversation: { lastMessage: 'Something else' } }));
    // Or pointing back at an older message.
    await assertFails(
      updateDoc(chat, {
        lastMessage: 'Hello',
        lastMessageId: firstId,
        lastSenderId: ME,
        lastAt: serverTimestamp(),
        [`lastReadAt.${ME}`]: serverTimestamp(),
      }),
    );
    assert.deepEqual(await fetchMessages(db, ME, OTHER), ['Hello']);
  });

  test('messages cannot be edited or deleted', async () => {
    await seedAccounts(ME, OTHER);
    const id = await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    for (const db of [dbAs(ME), dbAs(OTHER)]) {
      const message = doc(collection(conversationRef(db, ME, OTHER), 'messages'), id);
      await assertFails(updateDoc(message, { text: 'Edited' }));
      await assertFails(deleteDoc(message));
    }
    assert.deepEqual(await fetchMessages(dbAs(ME), ME, OTHER), ['Hello']);
  });

  test('only your own read time can be changed, and only to now', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await sendMessage(dbAs(ME), ME, OTHER, 'Hello');
    const chat = (db) => conversationRef(db, ME, OTHER);

    await assertFails(updateDoc(chat(dbAs(OTHER)), { [`lastReadAt.${ME}`]: serverTimestamp() }));
    await assertFails(updateDoc(chat(dbAs(ME)), { [`lastReadAt.${ME}`]: new Date(2020, 0, 1) }));
    await assertFails(updateDoc(chat(dbAs(THIRD)), { [`lastReadAt.${THIRD}`]: serverTimestamp() }));
    await assertFails(
      updateDoc(chat(dbAs(ME)), { [`lastReadAt.${ME}`]: serverTimestamp(), participantIds: [ME, THIRD].sort() }),
    );
    await assertFails(updateDoc(chat(dbAs(ME)), { [`lastReadAt.${ME}`]: serverTimestamp(), kind: 'group' }));
    await assertFails(updateDoc(chat(dbAs(ME)), { lastMessage: 'Rewritten' }));
    for (const db of [dbAs(ME), dbAs(OTHER)]) await assertFails(deleteDoc(chat(db)));

    const stored = await read(chatPath(ME, OTHER));
    assert.equal(stored.lastMessage, 'Hello');
    assert.deepEqual(stored.participantIds, [ME, OTHER].sort());
  });
});

// Trades: trades/{tradeId} and proposals/{proposalId}

const TOMORROW = () => new Date(Date.now() + 24 * 60 * 60 * 1000);

const terms = (extra = {}) => ({
  offeredSkill: 'Baking',
  requestedSkill: 'Flutter',
  sessionsMinutes: 60,
  deliveryMethod: 'Online',
  creditsOffered: 0,
  ...extra,
});

/// Mirrors FirebaseTradeRepository.sendProposal: the trade and its first
/// proposal in one batch. [trade] and [proposal] replace fields. Resolves
/// to { tradeId, proposalId }.
async function sendProposal(db, uid, memberId, { trade = {}, proposal = {} } = {}) {
  const tradeRef = doc(collection(db, 'trades'));
  const proposalRef = doc(collection(db, 'proposals'));
  const participantIds = [uid, memberId].sort();
  const batch = writeBatch(db);
  batch.set(tradeRef, {
    participantIds,
    proposerId: uid,
    termsBy: uid,
    proposalId: proposalRef.id,
    status: 'pending',
    ...terms(),
    completedBy: {},
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    ...trade,
  });
  batch.set(proposalRef, {
    tradeId: tradeRef.id,
    participantIds,
    senderId: uid,
    receiverId: memberId,
    ...terms(),
    notes: '',
    status: 'pending',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...proposal,
  });
  await batch.commit();
  return { tradeId: tradeRef.id, proposalId: proposalRef.id };
}

/// Mirrors respondToProposal: the proposal and its trade together.
function respond(db, uid, { tradeId, proposalId }, status, tradeStatus = status) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'proposals', proposalId), { status, updatedAt: serverTimestamp() });
  batch.update(doc(db, 'trades', tradeId), {
    status: tradeStatus,
    updatedAt: serverTimestamp(),
    updatedBy: uid,
  });
  return batch.commit();
}

/// Mirrors counterProposal: old proposal countered, a new one by [uid]
/// (to [memberId]) becoming the trade's terms. Resolves to the new id.
async function counter(db, uid, memberId, { tradeId, proposalId }, newTerms = terms({ offeredSkill: 'Flutter', requestedSkill: 'Bread' })) {
  const next = doc(collection(db, 'proposals'));
  const batch = writeBatch(db);
  batch.update(doc(db, 'proposals', proposalId), { status: 'countered', updatedAt: serverTimestamp() });
  batch.set(next, {
    tradeId,
    participantIds: [uid, memberId].sort(),
    senderId: uid,
    receiverId: memberId,
    ...newTerms,
    notes: '',
    status: 'pending',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.update(doc(db, 'trades', tradeId), {
    ...newTerms,
    termsBy: uid,
    proposalId: next.id,
    updatedAt: serverTimestamp(),
    updatedBy: uid,
  });
  await batch.commit();
  return next.id;
}

/// Mirrors scheduleSession.
const schedule = (db, uid, tradeId, scheduledAt = TOMORROW()) =>
  updateDoc(doc(db, 'trades', tradeId), {
    session: { scheduledAt, method: 'Online', locationOrLink: '', notes: '' },
    updatedAt: serverTimestamp(),
    updatedBy: uid,
  });

/// Mirrors confirmCompletion: the caller's wallet is opened, then the
/// confirmation is decided in a transaction from what is stored, and the
/// completing one pays both wallets (see settlementOf below). [status]
/// forces the stored status and [tamper] changes the wallet writes, for
/// what must be refused.
const confirm = async (db, uid, tradeId, { status, tamper = (members) => members } = {}) => {
  await openWallet(db, uid);
  return runTransaction(db, async (transaction) => {
    const ref = doc(db, 'trades', tradeId);
    const trade = (await transaction.get(ref)).data();
    const completedBy = { ...trade.completedBy, [uid]: serverTimestamp() };
    const done = trade.participantIds.every((id) => id in completedBy);
    if (done) await transaction.get(walletRef(db, uid));
    transaction.update(ref, {
      completedBy,
      ...(status ? { status } : done ? { status: 'completed' } : {}),
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });
    if (done) applySettlement(transaction, db, tradeId, tamper(settlementOf(tradeId, trade)));
  });
};

// Wallets: wallets/{uid} and wallets/{uid}/transactions/{entryId}

const WELCOME = 120;
const REWARD = 10;

const walletRef = (db, uid) => doc(db, 'wallets', uid);
const entryRef = (db, uid, id) => doc(db, 'wallets', uid, 'transactions', id);

/// Mirrors FirebaseWalletRepository.openWallet.
const openWallet = (db, uid) =>
  runTransaction(db, async (transaction) => {
    if ((await transaction.get(walletRef(db, uid))).exists()) return;
    transaction.set(walletRef(db, uid), { uid, balance: WELCOME, updatedAt: serverTimestamp() });
    transaction.set(entryRef(db, uid, 'welcome'), {
      kind: 'welcome',
      amount: WELCOME,
      createdAt: serverTimestamp(),
    });
  });

const paymentOf = (uid, trade) => (trade.termsBy === uid ? -trade.creditsOffered : trade.creditsOffered);

/// Mirrors WalletDocument.settle: for each member, the change to their
/// balance and the ledger entries for it.
function settlementOf(tradeId, trade) {
  return trade.participantIds.map((uid) => {
    const counterpartyId = trade.participantIds.find((id) => id !== uid);
    const entries = {
      [`${tradeId}_reward`]: { kind: 'tradeReward', amount: REWARD, tradeId, counterpartyId, createdAt: serverTimestamp() },
    };
    if (trade.creditsOffered > 0) {
      entries[`${tradeId}_payment`] = {
        kind: trade.termsBy === uid ? 'tradePayment' : 'tradeIncome',
        amount: paymentOf(uid, trade),
        tradeId,
        counterpartyId,
        createdAt: serverTimestamp(),
      };
    }
    return { uid, delta: REWARD + paymentOf(uid, trade), entries };
  });
}

/// Mirrors FirebaseWalletRepository.applySettlement. A member with
/// `skipWallet` has only their entries written.
function applySettlement(transaction, db, tradeId, members) {
  for (const member of members) {
    if (!member.skipWallet) {
      transaction.update(walletRef(db, member.uid), {
        balance: increment(member.delta),
        lastTradeId: tradeId,
        updatedAt: serverTimestamp(),
      });
    }
    for (const [id, data] of Object.entries(member.entries)) {
      transaction.set(entryRef(db, member.uid, id), data);
    }
  }
}

async function fetchTradeIds(db, uid) {
  const snapshot = await getDocs(
    query(collection(db, 'trades'), where('participantIds', 'array-contains', uid), limit(200)),
  );
  return snapshot.docs.map((item) => item.id);
}

/// A trade [ME] proposed and [OTHER] accepted, with a session booked.
async function acceptedTrade() {
  await seedAccounts(ME, OTHER, THIRD);
  const sent = await sendProposal(dbAs(ME), ME, OTHER);
  await respond(dbAs(OTHER), OTHER, sent, 'accepted');
  await schedule(dbAs(ME), ME, sent.tradeId);
  return sent;
}

describe('trades: what the rules must allow', () => {
  test('a member proposes, and only the two members can read it', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const sent = await assertSucceeds(sendProposal(dbAs(ME), ME, OTHER));

    assert.deepEqual(await fetchTradeIds(dbAs(ME), ME), [sent.tradeId]);
    assert.deepEqual(await fetchTradeIds(dbAs(OTHER), OTHER), [sent.tradeId]);
    await assertSucceeds(getDoc(doc(dbAs(OTHER), 'proposals', sent.proposalId)));
    await assertFails(getDoc(doc(dbAs(THIRD), 'trades', sent.tradeId)));
    await assertFails(getDoc(doc(dbAs(THIRD), 'proposals', sent.proposalId)));
    await assertFails(getDocs(collection(dbAs(THIRD), 'trades')));
  });

  test('the receiver accepts, a session is booked and rescheduled', async () => {
    const sent = await acceptedTrade();
    await assertSucceeds(schedule(dbAs(OTHER), OTHER, sent.tradeId, new Date(Date.now() + 3 * 86400000)));
    const stored = await read(`trades/${sent.tradeId}`);
    assert.equal(stored.status, 'accepted');
    assert.equal(stored.updatedBy, OTHER);
  });

  test('a trade completes once both members confirmed', async () => {
    const sent = await acceptedTrade();
    await assertSucceeds(confirm(dbAs(ME), ME, sent.tradeId));
    assert.equal((await read(`trades/${sent.tradeId}`)).status, 'accepted');

    await assertSucceeds(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    const stored = await read(`trades/${sent.tradeId}`);
    assert.equal(stored.status, 'completed');
    assert.deepEqual(Object.keys(stored.completedBy).sort(), [ME, OTHER].sort());
  });

  test('either member counters, and the other answers the new terms', async () => {
    await seedAccounts(ME, OTHER);
    const sent = await sendProposal(dbAs(ME), ME, OTHER);
    const counterId = await assertSucceeds(counter(dbAs(OTHER), OTHER, ME, sent));
    assert.equal((await read(`proposals/${sent.proposalId}`)).status, 'countered');
    assert.equal((await read(`trades/${sent.tradeId}`)).termsBy, OTHER);

    await assertSucceeds(respond(dbAs(ME), ME, { ...sent, proposalId: counterId }, 'accepted'));
  });

  test('the receiver declines; the sender cancels', async () => {
    await seedAccounts(ME, OTHER);
    const first = await sendProposal(dbAs(ME), ME, OTHER);
    await assertSucceeds(respond(dbAs(OTHER), OTHER, first, 'declined'));
    const second = await sendProposal(dbAs(ME), ME, OTHER);
    await assertSucceeds(respond(dbAs(ME), ME, second, 'cancelled'));
  });

  test('a trade with a blocked member can still be confirmed', async () => {
    const sent = await acceptedTrade();
    await seed({ [`users/${OTHER}/blocked/${ME}`]: { blockedUid: ME, blockedAt: new Date() } });
    await assertSucceeds(confirm(dbAs(ME), ME, sent.tradeId));
    await assertFails(schedule(dbAs(ME), ME, sent.tradeId));
  });

  test('accepted trades can be disputed by either member', async () => {
    const sent = await acceptedTrade();
    await assertSucceeds(
      updateDoc(doc(dbAs(OTHER), 'trades', sent.tradeId), {
        status: 'disputed',
        updatedAt: serverTimestamp(),
        updatedBy: OTHER,
      }),
    );
  });
});

describe('trades: what the rules must refuse', () => {
  test('a trade for someone else, with "me", or without its proposal', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    await assertFails(sendProposal(dbAs(THIRD), ME, OTHER));
    await assertFails(sendProposal(dbAs(ME), ME, OTHER, { trade: { proposerId: OTHER } }));
    await assertFails(sendProposal(dbAs(ME), ME, 'me'));
    await assertFails(sendProposal(dbAs(ME), ME, ME));
    await assertFails(sendProposal(dbAs(ME), ME, 'uid-nobody'));
    await assertFails(sendProposal(dbAs(ME), ME, OTHER, { trade: { status: 'accepted' } }));
    await assertFails(sendProposal(dbAs(ME), ME, OTHER, { proposal: { requestedSkill: 'Other' } }));
    await assertFails(sendProposal(dbAs(ME), ME, OTHER, { proposal: { senderId: OTHER, receiverId: ME } }));
    await assertFails(sendProposal(dbAs(ME), ME, OTHER, { trade: { offeredSkill: '', creditsOffered: 0 }, proposal: { offeredSkill: '', creditsOffered: 0 } }));
    const tradeOnly = doc(collection(dbAs(ME), 'trades'));
    await assertFails(
      setDoc(tradeOnly, {
        participantIds: [ME, OTHER].sort(), proposerId: ME, termsBy: ME, proposalId: 'missing',
        status: 'pending', ...terms(), completedBy: {}, createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(), updatedBy: ME,
      }),
    );
  });

  test('the sender accepting, or anyone else answering', async () => {
    await seedAccounts(ME, OTHER, THIRD);
    const sent = await sendProposal(dbAs(ME), ME, OTHER);
    await assertFails(respond(dbAs(ME), ME, sent, 'accepted'));
    await assertFails(respond(dbAs(ME), ME, sent, 'declined'));
    await assertFails(respond(dbAs(OTHER), OTHER, sent, 'cancelled'));
    await assertFails(respond(dbAs(THIRD), THIRD, sent, 'accepted'));
    // A trade status that does not match the answer.
    await assertFails(respond(dbAs(OTHER), OTHER, sent, 'accepted', 'completed'));
    await assertFails(respond(dbAs(OTHER), OTHER, sent, 'declined', 'accepted'));
  });

  test('answering twice or answering a countered proposal', async () => {
    await seedAccounts(ME, OTHER);
    const sent = await sendProposal(dbAs(ME), ME, OTHER);
    await counter(dbAs(OTHER), OTHER, ME, sent);
    await assertFails(respond(dbAs(OTHER), OTHER, sent, 'accepted'));

    const second = await sendProposal(dbAs(ME), ME, OTHER);
    await respond(dbAs(OTHER), OTHER, second, 'declined');
    await assertFails(respond(dbAs(OTHER), OTHER, second, 'accepted'));
  });

  test('completing with one confirmation, twice, or for the other member', async () => {
    const sent = await acceptedTrade();
    await assertFails(confirm(dbAs(ME), ME, sent.tradeId, { status: 'completed' }));
    await assertFails(
      updateDoc(doc(dbAs(ME), 'trades', sent.tradeId), {
        [`completedBy.${OTHER}`]: serverTimestamp(),
        updatedAt: serverTimestamp(),
        updatedBy: ME,
      }),
    );
    await confirm(dbAs(ME), ME, sent.tradeId);
    await assertFails(confirm(dbAs(ME), ME, sent.tradeId));
    await assertFails(confirm(dbAs(THIRD), THIRD, sent.tradeId));
  });

  test('confirming before a session, or scheduling too early or in the past', async () => {
    await seedAccounts(ME, OTHER);
    const sent = await sendProposal(dbAs(ME), ME, OTHER);
    await assertFails(schedule(dbAs(ME), ME, sent.tradeId));
    await respond(dbAs(OTHER), OTHER, sent, 'accepted');
    await assertFails(confirm(dbAs(ME), ME, sent.tradeId));
    await assertFails(schedule(dbAs(ME), ME, sent.tradeId, new Date(Date.now() - 3600000)));
  });

  test('proposing to, accepting or scheduling with a blocked member', async () => {
    await seedAccounts(ME, OTHER);
    const sent = await sendProposal(dbAs(ME), ME, OTHER);
    await seed({ [`users/${OTHER}/blocked/${ME}`]: { blockedUid: ME, blockedAt: new Date() } });
    await assertFails(sendProposal(dbAs(ME), ME, OTHER));
    await assertFails(respond(dbAs(OTHER), OTHER, sent, 'accepted'));
    await assertSucceeds(respond(dbAs(OTHER), OTHER, sent, 'declined'));
  });

  test('changing members or terms directly, or deleting', async () => {
    const sent = await acceptedTrade();
    const tradeRef = doc(dbAs(ME), 'trades', sent.tradeId);
    await assertFails(updateDoc(tradeRef, { participantIds: [ME, THIRD].sort(), updatedAt: serverTimestamp(), updatedBy: ME }));
    await assertFails(updateDoc(tradeRef, { creditsOffered: 500, updatedAt: serverTimestamp(), updatedBy: ME }));
    await assertFails(updateDoc(tradeRef, { status: 'pending', updatedAt: serverTimestamp(), updatedBy: ME }));
    await assertFails(deleteDoc(tradeRef));
    await assertFails(deleteDoc(doc(dbAs(ME), 'proposals', sent.proposalId)));
  });
});

/// A trade where [payer] offers [credits] (instead of a skill) to [payee],
/// accepted with a session booked, and both wallets open.
async function creditTrade(payer, payee, credits) {
  await seedAccounts(ME, OTHER, THIRD);
  const paid = { offeredSkill: '', creditsOffered: credits };
  const sent = await sendProposal(dbAs(payer), payer, payee, { trade: paid, proposal: paid });
  await respond(dbAs(payee), payee, sent, 'accepted');
  await schedule(dbAs(payer), payer, sent.tradeId);
  await openWallet(dbAs(ME), ME);
  await openWallet(dbAs(OTHER), OTHER);
  return sent;
}

const balanceOf = async (uid) => (await read(`wallets/${uid}`))?.balance;

async function ledgerOf(uid) {
  let entries;
  await env.withSecurityRulesDisabled(async (context) => {
    const snapshot = await getDocs(collection(context.firestore(), 'wallets', uid, 'transactions'));
    entries = Object.fromEntries(snapshot.docs.map((item) => [item.id, item.data()]));
  });
  return entries;
}

/// Changes only [uid]'s settlement with [change], in a copy of [members].
const changeMember = (uid, change) => (members) =>
  members.map((member) => (member.uid === uid ? change(member) : member));

/// Changes only [uid]'s entry [id] with [change].
const changeEntry = (uid, id, change) =>
  changeMember(uid, (member) => ({ ...member, entries: { ...member.entries, [id]: change(member.entries[id]) } }));

describe('wallets: what the rules must allow', () => {
  test('a member opens their wallet once, with the welcome credits', async () => {
    await seedAccounts(ME, OTHER);
    await assertSucceeds(openWallet(dbAs(ME), ME));
    await assertSucceeds(openWallet(dbAs(ME), ME));
    assert.equal(await balanceOf(ME), WELCOME);
    assert.deepEqual(Object.keys(await ledgerOf(ME)), ['welcome']);

    await assertSucceeds(getDoc(walletRef(dbAs(ME), ME)));
    await assertSucceeds(getDocs(collection(dbAs(ME), 'wallets', ME, 'transactions')));
  });

  test('completing a trade rewards both members once', async () => {
    const sent = await acceptedTrade();
    await openWallet(dbAs(OTHER), OTHER);
    await assertSucceeds(confirm(dbAs(ME), ME, sent.tradeId));
    assert.equal(await balanceOf(ME), WELCOME, 'nothing before both confirmed');

    await assertSucceeds(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    assert.equal((await read(`trades/${sent.tradeId}`)).status, 'completed');
    for (const [uid, other] of [[ME, OTHER], [OTHER, ME]]) {
      assert.equal(await balanceOf(uid), WELCOME + REWARD);
      const ledger = await ledgerOf(uid);
      assert.deepEqual(Object.keys(ledger).sort(), [`${sent.tradeId}_reward`, 'welcome'].sort());
      assert.equal(ledger[`${sent.tradeId}_reward`].counterpartyId, other);
    }
  });

  test("the payer's credits go to the other member, whoever confirms last", async () => {
    for (const last of [OTHER, ME]) {
      await env.clearFirestore();
      const sent = await creditTrade(ME, OTHER, 30);
      const first = last === ME ? OTHER : ME;
      await confirm(dbAs(first), first, sent.tradeId);
      await assertSucceeds(confirm(dbAs(last), last, sent.tradeId));

      assert.equal(await balanceOf(ME), WELCOME + REWARD - 30);
      assert.equal(await balanceOf(OTHER), WELCOME + REWARD + 30);
      const paid = (await ledgerOf(ME))[`${sent.tradeId}_payment`];
      const received = (await ledgerOf(OTHER))[`${sent.tradeId}_payment`];
      assert.deepEqual([paid.kind, paid.amount], ['tradePayment', -30]);
      assert.deepEqual([received.kind, received.amount], ['tradeIncome', 30]);
    }
  });

  test('a payer can spend all their credits', async () => {
    const sent = await creditTrade(OTHER, ME, WELCOME + REWARD);
    await confirm(dbAs(ME), ME, sent.tradeId);
    await assertSucceeds(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    assert.equal(await balanceOf(OTHER), 0);
  });
});

describe('wallets: what the rules must refuse', () => {
  test("reading another member's wallet or ledger", async () => {
    await seedAccounts(ME, OTHER);
    await openWallet(dbAs(ME), ME);
    await assertFails(getDoc(walletRef(dbAs(OTHER), ME)));
    await assertFails(getDoc(entryRef(dbAs(OTHER), ME, 'welcome')));
    await assertFails(getDocs(collection(dbAs(OTHER), 'wallets', ME, 'transactions')));
    await assertFails(getDocs(collection(dbAs(ME), 'wallets')));
    await assertFails(getDoc(walletRef(anonymousDb(), ME)));
  });

  test('opening a wallet with other credits, for someone else, or twice', async () => {
    await seedAccounts(ME, OTHER);
    const welcome = (amount) => ({ kind: 'welcome', amount, createdAt: serverTimestamp() });
    const open = (db, uid, balance, entry = welcome(balance)) => {
      const batch = writeBatch(db);
      batch.set(walletRef(db, uid), { uid, balance, updatedAt: serverTimestamp() });
      if (entry) batch.set(entryRef(db, uid, 'welcome'), entry);
      return batch.commit();
    };
    await assertFails(open(dbAs(ME), ME, 1000));
    await assertFails(open(dbAs(ME), ME, WELCOME, null));
    await assertFails(open(dbAs(ME), ME, WELCOME, welcome(1000)));
    await assertFails(open(dbAs(ME), OTHER, WELCOME));
    await assertFails(
      setDoc(walletRef(dbAs(ME), ME), { uid: ME, balance: WELCOME, lastTradeId: 'x', updatedAt: serverTimestamp() }),
    );

    await openWallet(dbAs(ME), ME);
    // Opening again is an update, and a second welcome entry is refused.
    await assertFails(open(dbAs(ME), ME, WELCOME));
    await assertFails(setDoc(entryRef(dbAs(ME), ME, 'welcome'), welcome(WELCOME)));
    assert.equal(await balanceOf(ME), WELCOME);
  });

  test('opening a wallet with the balance 120.0 rather than 120', async () => {
    await seedAccounts(ME);
    // The JS SDK sends 120.0 as an integer, so this is the wire format a
    // modified client could send: the same write as openWallet, with the
    // balance as a doubleValue or, to show the request is otherwise
    // allowed, an integerValue.
    const { host, port } = env.emulators.firestore;
    const documents = 'projects/demo-souq-skills/databases/(default)/documents';
    const now = Math.floor(Date.now() / 1000);
    const token = [
      { alg: 'none', typ: 'JWT' },
      {
        iss: 'https://securetoken.google.com/demo-souq-skills',
        aud: 'demo-souq-skills',
        sub: ME,
        user_id: ME,
        phone_number: '+966500000000',
        firebase: { sign_in_provider: 'phone' },
        auth_time: now,
        iat: now,
        exp: now + 3600,
      },
    ].map((part) => Buffer.from(JSON.stringify(part)).toString('base64url')).join('.') + '.';
    const create = (path, fields, timeField) => ({
      update: { name: `${documents}/${path}`, fields },
      currentDocument: { exists: false },
      updateTransforms: [{ fieldPath: timeField, setToServerValue: 'REQUEST_TIME' }],
    });
    const openWith = (balance) =>
      fetch(`http://${host}:${port}/v1/${documents}:commit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          writes: [
            create(`wallets/${ME}`, { uid: { stringValue: ME }, balance }, 'updatedAt'),
            create(
              `wallets/${ME}/transactions/welcome`,
              { kind: { stringValue: 'welcome' }, amount: { integerValue: String(WELCOME) } },
              'createdAt',
            ),
          ],
        }),
      });

    const asDouble = await openWith({ doubleValue: WELCOME });
    assert.equal(asDouble.status, 403);
    assert.equal(await read(`wallets/${ME}`), undefined);

    const asInteger = await openWith({ integerValue: String(WELCOME) });
    assert.equal(asInteger.status, 200);
    assert.equal(await balanceOf(ME), WELCOME);
  });

  test('changing a balance or the ledger directly, or deleting them', async () => {
    await seedAccounts(ME, OTHER);
    await openWallet(dbAs(ME), ME);
    await openWallet(dbAs(OTHER), OTHER);
    const mine = walletRef(dbAs(ME), ME);
    await assertFails(updateDoc(mine, { balance: 100000, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(mine, { balance: increment(50), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(walletRef(dbAs(ME), OTHER), { balance: increment(-50), updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(mine));
    await assertFails(updateDoc(entryRef(dbAs(ME), ME, 'welcome'), { amount: 100000 }));
    await assertFails(deleteDoc(entryRef(dbAs(ME), ME, 'welcome')));
    await assertFails(
      setDoc(entryRef(dbAs(ME), ME, 'gift'), { kind: 'tradeReward', amount: 50, createdAt: serverTimestamp() }),
    );
    await assertFails(
      setDoc(entryRef(dbAs(ME), OTHER, 'gift'), { kind: 'welcome', amount: WELCOME, createdAt: serverTimestamp() }),
    );
    assert.equal(await balanceOf(ME), WELCOME);
    assert.equal(await balanceOf(OTHER), WELCOME);
  });

  test('completing a trade without paying both wallets, or paying without completing', async () => {
    const sent = await creditTrade(ME, OTHER, 30);
    await confirm(dbAs(ME), ME, sent.tradeId);
    const as = (tamper) => confirm(dbAs(OTHER), OTHER, sent.tradeId, { tamper });
    const reward = `${sent.tradeId}_reward`;
    // Completed without any payment, as before wallets.
    await assertFails(as(() => []));
    // Only one wallet paid.
    await assertFails(as((members) => members.filter((member) => member.uid === OTHER)));
    // A wallet changed without its entries, or entries without the wallet.
    await assertFails(as(changeMember(ME, (member) => ({ ...member, entries: {} }))));
    await assertFails(as(changeMember(ME, (member) => ({ ...member, skipWallet: true }))));
    // The payment entries left out.
    await assertFails(as((members) => members.map((member) => ({ ...member, entries: { [reward]: member.entries[reward] } }))));
    // Paid while the trade stays accepted.
    const db = dbAs(OTHER);
    await assertFails(
      runTransaction(db, async (transaction) => {
        const trade = (await transaction.get(doc(db, 'trades', sent.tradeId))).data();
        applySettlement(transaction, db, sent.tradeId, settlementOf(sent.tradeId, trade));
      }),
    );
    assert.equal((await read(`trades/${sent.tradeId}`)).status, 'accepted');
    assert.equal(await balanceOf(ME), WELCOME);
    assert.equal(await balanceOf(OTHER), WELCOME);
  });

  test('paying other amounts, kinds or members than the trade says', async () => {
    const sent = await creditTrade(ME, OTHER, 30);
    await confirm(dbAs(ME), ME, sent.tradeId);
    await openWallet(dbAs(THIRD), THIRD);
    const as = (tamper) => confirm(dbAs(OTHER), OTHER, sent.tradeId, { tamper });
    const reward = `${sent.tradeId}_reward`;
    const payment = `${sent.tradeId}_payment`;
    // The receiver takes more, or the payer pays less.
    await assertFails(as(changeMember(OTHER, (member) => ({ ...member, delta: member.delta + 100 }))));
    await assertFails(as(changeMember(ME, (member) => ({ ...member, delta: REWARD }))));
    // Entries that do not match the trade.
    await assertFails(as(changeEntry(OTHER, reward, (entry) => ({ ...entry, amount: 50 }))));
    await assertFails(as(changeEntry(ME, payment, (entry) => ({ ...entry, amount: 30, kind: 'tradeIncome' }))));
    await assertFails(as(changeEntry(OTHER, payment, (entry) => ({ ...entry, kind: 'tradePayment' }))));
    await assertFails(as(changeEntry(OTHER, reward, (entry) => ({ ...entry, counterpartyId: THIRD }))));
    await assertFails(as(changeEntry(OTHER, reward, (entry) => ({ ...entry, extra: true }))));
    // An extra entry, a third member's wallet, or one member paid as another.
    await assertFails(as(changeEntry(OTHER, `${sent.tradeId}_bonus`, () => ({ kind: 'tradeReward', amount: REWARD, tradeId: sent.tradeId, counterpartyId: ME, createdAt: serverTimestamp() }))));
    await assertFails(as((members) => [...members, { uid: THIRD, delta: REWARD, entries: { [reward]: members[0].entries[reward] } }]));
    await assertFails(as(changeMember(OTHER, (member) => ({ ...member, uid: THIRD }))));

    assert.equal(await balanceOf(ME), WELCOME);
    assert.equal(await balanceOf(OTHER), WELCOME);
    assert.equal(await balanceOf(THIRD), WELCOME);
    await assertSucceeds(as((members) => members));
  });

  test('paying or rewarding a completed trade again', async () => {
    const sent = await creditTrade(ME, OTHER, 30);
    await confirm(dbAs(ME), ME, sent.tradeId);
    await confirm(dbAs(OTHER), OTHER, sent.tradeId);
    const balances = [await balanceOf(ME), await balanceOf(OTHER)];
    const trade = await read(`trades/${sent.tradeId}`);

    for (const db of [dbAs(ME), dbAs(OTHER)]) {
      await assertFails(
        runTransaction(db, async (transaction) =>
          applySettlement(transaction, db, sent.tradeId, settlementOf(sent.tradeId, trade))),
      );
      await assertFails(
        updateDoc(walletRef(db, OTHER), { balance: increment(40), lastTradeId: 'another', updatedAt: serverTimestamp() }),
      );
    }
    await assertFails(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    assert.deepEqual([await balanceOf(ME), await balanceOf(OTHER)], balances);
  });

  test('completing when the payer cannot pay, or without the other wallet', async () => {
    const sent = await creditTrade(ME, OTHER, 200);
    await confirm(dbAs(ME), ME, sent.tradeId);
    // The payee cannot see the payer's balance; the rules refuse it.
    await assertFails(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    assert.equal((await read(`trades/${sent.tradeId}`)).status, 'accepted');
    assert.equal(await balanceOf(OTHER), WELCOME);

    await env.clearFirestore();
    const second = await acceptedTrade();
    await confirm(dbAs(ME), ME, second.tradeId);
    // Without confirm's own opening of OTHER's wallet.
    const db = dbAs(OTHER);
    await assertFails(
      runTransaction(db, async (transaction) => {
        const ref = doc(db, 'trades', second.tradeId);
        const trade = (await transaction.get(ref)).data();
        transaction.update(ref, {
          completedBy: { ...trade.completedBy, [OTHER]: serverTimestamp() },
          status: 'completed',
          updatedAt: serverTimestamp(),
          updatedBy: OTHER,
        });
        applySettlement(transaction, db, second.tradeId, settlementOf(second.tradeId, trade));
      }),
    );
  });

  test('a member outside the trade, or a disputed trade, is never paid', async () => {
    const sent = await creditTrade(ME, OTHER, 30);
    await openWallet(dbAs(THIRD), THIRD);
    const trade = await read(`trades/${sent.tradeId}`);
    const db = dbAs(THIRD);
    await assertFails(
      runTransaction(db, async (transaction) =>
        applySettlement(transaction, db, sent.tradeId, [
          { uid: THIRD, delta: 40, entries: settlementOf(sent.tradeId, trade)[1].entries },
        ])),
    );
    await updateDoc(doc(dbAs(OTHER), 'trades', sent.tradeId), {
      status: 'disputed',
      updatedAt: serverTimestamp(),
      updatedBy: OTHER,
    });
    await assertFails(confirm(dbAs(OTHER), OTHER, sent.tradeId));
    assert.equal(await balanceOf(OTHER), WELCOME);
    assert.equal(await balanceOf(THIRD), WELCOME);
  });
});
