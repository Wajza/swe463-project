# Souq Skills

Souq Skills is a Flutter marketplace where members in Saudi Arabia trade skills instead of money. Post what you can teach, propose a swap, schedule a session, complete it, and rate the experience.

**Course:** SWE463, Phase 3 (Git tag: `phase-3`)

## Team

| Name | Student ID | Responsibility |
|---|---:|---|
| Wajd Alghamdi | 202262140 | UI and UX |
| Yasmeen Alshehri | 202271660 | Trade flow |
| Fatimah Alshehab | 202278660 | Backend and data |
| Raghad Almaghrabi | 202156390 | Profile and quality |

## What works

| Area | Features |
|---|---|
| Account | Phone sign-in or sign-up from one entry point with Firebase Authentication (SMS code), first and last name, username unique across all members, location from a list or the device, private location option, editable profile and skills saved to Firestore, code verification for a new phone number, sign out, delete account (also removes the member's listings and saved skills) |
| Discover | Skill feed on Home loaded from Firestore, with pull to refresh, search as you type, filters for category, city and tags, and saved skills kept per member |
| Posting | Solo listings with Online only and Women only tags, shared with all members through Firestore, and group trades, from one page of selections, with edit, pause, and delete by the owner only |
| Trading | Proposals with accept, counter and decline on the proposal card, offering a skill or wallet credits, scheduling, completion, disputes |
| Rating | Star rating with one-tap feedback after an exchange, shown on the profile |
| Profile | Rating, badges earned from real activity, reviews given and received, skills |
| Group trades | Invite only: create, invite by username, accept or decline, group chat, completion, rating |
| Chat | Direct and group chats with one-tap replies |
| Wallet | Balance, credits on hold for active trades, hide or show, credit history |
| Safety | Report a member or trade, send a complaint and get a confirmation, block and unblock, track cases |
| Settings | Edit profile, dark mode, notification and privacy switches on one page |

**Complete end-to-end flow with a stored result:** sign in → open a trade → mark it complete (credits are added) → rate it → see the rating and badges on the profile → restart the app and the result is still there.


## Run the app

Requires the Flutter SDK with Dart 3.13 or newer, and access to the team's Firebase project (`souq-skills`).

```bash
cd souq_skills
flutter pub get
flutter run -d chrome        # or: flutter run -d <android-device-id>
```

**Firebase setup.**

- **Web:** uses `lib/firebase_options.dart`, which is in the repository.
- **Android:** also needs `android/app/google-services.json`. It is deliberately not in Git; download it from the Firebase Console (Project settings → Your apps) or run `flutterfire configure`.
- **Firebase Console:** the Phone sign-in provider must be enabled, and the app's SHA-1 and SHA-256 fingerprints added for Android.

**Signing in.** Press **Get started**, enter a Saudi mobile number without `+966` (for example `5XXXXXXXX`), then enter the 6-digit SMS code. To avoid real SMS while testing, add test numbers and codes under Firebase Console → Authentication → Sign-in method → Phone → *Phone numbers for testing*. A number with no profile yet goes on to **Create account**.

**Security rules.** The Firestore rules are in `firestore.rules`. Only project owners deploy them, after the rules tests pass:

```bash
firebase deploy --only firestore:rules --project souq-skills
```

**Resetting.** To clear what is kept on one device, clear the browser's site data or the app's storage. Accounts, profiles, usernames, listings and saved skills live in Firestore and are removed with **Delete account**.

## Testing

### Automated

```bash
cd souq_skills
flutter analyze
flutter test
```

`flutter test` needs no Firebase connection. Without an initialized Firebase app, sign-in, profiles, listings and saved skills use in-memory stand-ins (`DemoAuthRepository`, `DemoProfileRepository`, `DemoListingRepository`, `DemoSavedListingsRepository`), and the tests that cover Firestore behaviour inject them directly.

| Test file | Covers |
|---|---|
| `test/widget_test.dart` | Welcome screen, phone and code validation, bottom navigation |
| `test/app_flow_test.dart` | Home search and filters, rating flow through to the profile, solo and group posting, form validation, proposal to trade, new accounts |
| `test/profile_and_group_test.dart` | Counteroffers from the card, sign-up validation, unique usernames, device location, phone re-verification, group invitations, listing tags |
| `test/credits_and_complaints_test.dart` | Offering credits, holds, payment on completion, release on cancel, Edit profile location, complaints |
| `test/persistence_test.dart` | Save and restore, corrupt data, loading, load failure with retry, save failure with retry |
| `test/routes_test.dart` | Every route on a phone screen in light and dark themes, one main button per screen, missing arguments |
| `test/profile_repository_test.dart` | Profile data conversion, username claims, case-insensitive uniqueness, renames |
| `test/profile_loading_test.dart` | Loading the profile after sign-in and at start-up, failures, account switching on one device |
| `test/profile_saving_test.dart`, `test/my_skills_saving_test.dart` | Saving profile edits and skills online first, failures, unchanged fields |
| `test/sign_up_username_test.dart` | Claiming a username at sign-up, taken names, releasing it on account deletion |
| `test/listing_repository_test.dart` | Listing data conversion, owner ids, older records, ownership checks |
| `test/listing_writes_test.dart` | Publishing, editing, pausing and deleting online first, failures, ownership, group trades unchanged |
| `test/listing_loading_test.dart` | Loading and refreshing listings, empty and error states, account switching, search and filters on loaded listings |
| `test/saved_listings_repository_test.dart`, `test/saved_listings_test.dart` | Saving per member, failures, rapid taps, refresh, sign-in again, account switching, deleted listings |
| `test/account_deletion_cleanup_test.dart` | Deleting an account removes only its own listings and saved skills, and stops safely if that fails |

### Firestore security rules

The rules in `firestore.rules` are tested against the Firestore emulator. This needs Node.js, Java 21 or newer, and the Firebase CLI. It runs against a local `demo-` project, so nothing reaches the real one.

```bash
cd souq_skills
npm --prefix firestore_rules_test install    # first time only
firebase emulators:exec --only firestore --project demo-souq-skills "npm --prefix firestore_rules_test test"
```

`firestore_rules_test/rules.test.mjs` repeats the app's own Firestore reads and writes. It checks what members may do and what is refused for:

- profiles;
- usernames;
- listings;
- saved listings;
- account deletion cleanup.

### Manual

1. **Sign in** with a Firebase test number (see *Signing in*). Enter `123` first and confirm the validation message.
2. **Search and filter:** on Home, type `oud` and watch the list narrow. Clear it, press the filter button in the search bar, and choose a category.
3. **Post solo:** open Post, press **Publish** with nothing selected and confirm the errors. Choose a category and skill, then publish.
4. **Post group:** open Post, select **Group**, choose a category and several skills, then publish.
5. **Rate:** Profile → My trades → *UI design ⇄ Photography* → **Mark as complete** → choose stars → **Submit rating**. The rating appears on the profile; about 2 seconds later the other member's rating appears too.
6. **Propose and counter:** open any listing → **Propose a trade** → **Send proposal**. In the chat, press **Counter** on the card and send new terms. It is accepted after about 30 seconds, and a notification appears. Noura's proposal in Chats shows **Accept**, **Counter** and **Decline** on the card.
7. **Offer credits:** on a proposal or counteroffer, choose **Credits** under *You offer* and pick an amount. The Wallet shows it on hold, and it is paid when the trade completes.
8. **Complaint:** Profile → Settings → Help and support → **Send a complaint**, pick a topic and send. A message confirms you will get feedback soon, and the complaint appears in the Safety Centre.
9. **Change phone:** Profile → Settings → Edit profile, change the phone number, press **Save**, and verify the code.
10. **Invite to a group:** Profile → Group trades → *Language exchange club* → **Invite**, type `omar`, and pick the member. They join after about 2 seconds.
11. **Persistence:** close and reopen the app. You stay signed in and your changes remain.
12. **Back behaviour:** on Android, Back from any tab returns to Home before leaving the app.
13. **Two accounts:**
    - With account A, post a skill.
    - Sign out and sign in as account B. The listing appears on Home, and opening it shows no owner options (edit, pause, delete).
    - Save it with the heart: it appears under Profile → Saved skills for B only.
    - Sign back in as A: B's saved skills are not shown.
14. **Delete account:** Profile → Settings → **Delete account**. The account's listings disappear for other members, and its username can be taken again.

## Architecture

```text
souq_skills/lib/
├── main.dart, app.dart   # Entry point and app configuration
├── core/                 # Routes, router, theme, validators, options, formatters
├── models/               # Immutable data classes with JSON support
├── data/                 # Firebase access: auth, profiles, listings, saved listings
├── services/             # Business rules, repository, data source
├── screens/              # One folder per feature
└── widgets/              # Reusable design-system components
```

**State ownership.** `Repository` is the single owner of app state and a `ChangeNotifier`. Screens read through services inside `LiveView` or `LiveEntity`, so the interface updates whenever data changes. Only temporary form input lives in a widget's `State`.

**Data sources.** Shared data is kept in Firebase, each part behind an interface in `lib/data/` with a Firebase version and an in-memory one for tests:

| Data | Where | Interface |
|---|---|---|
| Sign-in | Firebase Authentication (phone) | `AuthRepository` |
| Profiles | Firestore `users/{uid}` | `ProfileRepository` |
| Usernames | Firestore `usernames/{username}`, claimed in the same transaction as the profile | `ProfileRepository` |
| Listings | Firestore `listings/{listingId}`, with the owner's uid | `ListingRepository` |
| Saved skills | Firestore `users/{uid}/saved/{listingId}`, private to each member | `SavedListingsRepository` |

Changes to these are saved online first and only then shown on the device. On failure the screen explains what happened, and nothing changes. The services translate between the member's Firebase uid and the app's local id for the current member (`'me'`) at this boundary. A different account signing in on the same device never sees the previous account's data.

Everything else is still kept on the device only: trades, proposals, chats, group trades, wallet, reviews, notifications, safety reports and settings. `AppDataSource` is implemented by `LocalDataSource` using `shared_preferences`, and every change is saved as a JSON snapshot.

| State | Behaviour |
|---|---|
| Loading | `AppGate` shows a spinner while saved data is read |
| Success | The app opens where the member left off |
| Empty | Each list has its own empty message |
| Failure to load | An explanation with **Try again** |
| Failure to save | A banner on every screen with **Try again** |
| Corrupt or outdated data | Falls back to the sample data |

**Reusable components.** All screens are built from `AppPage`, `SouqButton`, `SelectField`, `OptionSheet`, `ChoiceChipRow`, `SkillPostForm`, `ProposalForm`, `IssueForm` and `ConversationView`, among others.

**Secrets.** The repository contains no secrets or service-account keys.

- `lib/firebase_options.dart` holds the Firebase *client* configuration, including API keys. These identify the app to Firebase rather than grant access; access is controlled by the security rules.
- `android/app/google-services.json` and other local files are excluded by `.gitignore`.

### Dependencies

| Package | Purpose |
|---|---|
| `flutter` | Framework and navigation |
| `firebase_core` | Connecting to the Firebase project |
| `firebase_auth` | Phone sign-in with SMS verification |
| `cloud_firestore` | Profiles, usernames, listings and saved skills |
| `shared_preferences` | On-device storage for everything else |
| `geolocator` | Reading the device's location to fill in the nearest city |
| `flutter_test`, `flutter_lints` | Tests and static analysis (development only) |
| `@firebase/rules-unit-testing`, `firebase` (npm, in `firestore_rules_test/`) | Firestore rules tests against the emulator (development only) |

## Known issues and limitations

- **Only part of the data is shared.** Accounts, profiles, usernames, listings and saved skills are in Firebase. Trades, proposals, chats, group trades, the wallet, reviews, notifications and safety reports still stay on one device.
- **Other members are simulated** for the features that stay on the device. `MemberSimulator` accepts proposals after about 30 seconds, and within about 2 seconds replies in chat, accepts group invitations and returns a 5-star rating.
- **Listing cards show "Member" and no rating for real owners,** because member names and ratings are not shared yet.
- **Listings refresh when Home opens and when pulled down,** not live, and all listings are loaded at once.
- **Device location picks the nearest listed city,** even if the member is outside Saudi Arabia.
- **Push notifications are in-app only.**
- **The Public profile switch is stored but has no visible effect,** because there are no other real viewers yet.
- **A manual check on a physical device has not been recorded,** including the device location permission prompt. Automated tests and a web build pass.

## Progress reports

Drawn from the repository's commit history.

| Date | Progress |
|---|---|
| 19 Sep 2026 | Repository created; essential features and team details documented |
| 4 Oct 2026 | Flutter project and web platform files added |
| 17 Oct 2026 | Project structure and basic app; shared widgets refactored; fixes to the post-skill and safety screens |
| 6 Nov 2026 | Provider-based profile, listings, posting, wallet, badges, and safety work on branch `phase3/frontend` |
| 9 Nov 2026 | Screens and services added on `main`; front end rebuilt with working flows and a single design; `phase-3` tag created |
| After 9 Nov 2026 | Selection-first redesign, one main action per screen, on-device data source with loading and failure handling, this documentation |

## Individual contributions

Commit counts come from `git shortlog --all`, including unmerged branches. Commits do not capture design, testing, meetings or report writing.

| Member | Commits | Work visible in Git |
|---|---:|---|
| Raghad Almaghrabi | 23 | Profile, badges, listing details and reviews, skill posting, wallet layout, Safety Centre, notification preferences, widget refactoring |
| Wajd Alghamdi | 6 | Web platform files, screens and services on `main`, front-end rebuild |
| Yasmeen Alshehri | 2 | Essential-features documentation |
| Fatimah Alshehab | 1 | Initial commit |

> **Team: complete before submitting.** Confirm who `xfas51` is, and add each member's work that does not appear in Git.

## AI assistance disclosure

AI assistance (Claude Code) was used to rebuild the front end, implement the data layer, write tests, and draft this README. The team remains responsible for reviewing, testing and submitting the work.
