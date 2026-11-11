// Firestore security rules tests for Souq Skills profiles, usernames and
// listings.
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
  getDoc,
  getDocs,
  limit,
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

const dbAs = (uid) => env.authenticatedContext(uid).firestore();
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

/// Mirrors FirebaseProfileRepository.saveProfile. Resolves to false when
/// the username is taken (nothing written), true when saved.
function saveProfile(db, uid, user) {
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
