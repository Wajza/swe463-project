// Firestore security rules tests for Souq Skills profiles and usernames.
//
// Run from souq_skills/ (starts and stops the emulator, deploys nothing):
//   firebase emulators:exec --only firestore --project demo-souq-skills \
//     "npm --prefix firestore_rules_test test"
//
// saveProfile() and deleteProfile() below make exactly the reads and writes
// of FirebaseProfileRepository in lib/data/profile_repository.dart, using
// the Firebase JS SDK, which is also what FlutterFire uses on the web. Keep
// them in step with the Dart code.

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
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const ME = 'uid-maha';
const OTHER = 'uid-sami';

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
