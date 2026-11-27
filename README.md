# Souq Skills

Souq Skills is a Flutter marketplace where members in Saudi Arabia trade skills instead of money. Post what you can teach, propose a swap, schedule a session, complete it, and rate the experience. The goal is to let people learn and share skills through exchange, without monetary payment.

**Course:** SWE463, Phase 3 (Git tag: `phase-3`)

## Team

| Name | Student ID | Responsibility |
|---|---:|---|
| Wajd Alghamdi | 202262140 | UI and UX |
| Yasmeen Alshehri | 202271660 | Trade flow |
| Fatimah Alshehab | 202278660 | Backend Developer B – Chat, Trades, Wallet, Group Trades, and Notifications |
| Raghad Almaghrabi | 202156390 | Frontend, Profile and quality |

## Implemented Phase 3 features

### Essential features: implemented

| # | Feature | Where it is stored |
|---|---|---|
| 1 | **Create and manage skill listings:** post a solo listing from selections (category, skill offered, skill wanted, city, availability, session length, tags), then edit, pause, resume or delete it as the owner | Firestore `listings` |
| 2 | **View listing details and reviews:** listing details with the owner, and *See all* for every rating the owner has received | Firestore `listings`, `reviews` |
| 3 | **Browse, search and filter listings:** Home feed of other members' active listings, search as you type (title, skill offered, skill wanted), filters for category, city and the Online only / Women only tags, pull to refresh | Firestore `listings` |
| 4 | **Earn and use skill credits through a wallet:** 120 welcome credits, +10 for each completed trade, +15 for each completed group trade; credits can be offered in a proposal, are held while the trade is active, and move to the other member when it completes | Firestore `wallets` |
| 5 | **Propose trades through in-app chat:** real-time direct chat between members, with proposals shown as cards in the chat | Firestore `conversations`, `trades`, `proposals` |
| 6 | **Negotiate trades with counteroffers and confirm agreements:** accept, counter or decline a proposal; the sender can cancel; an accepted proposal becomes an active trade with the agreed terms | Firestore `trades`, `proposals` |
| 7 | **Levels and badges:** XP and a level with a title, shown on the profile with progress to the next level and a breakdown of how XP was earned (see *XP and levels*); six badges worked out from activity, including online group trades | Worked out from Firestore `trades`, `groupTrades`, `reviews` and `listings`; nothing extra is stored |

### Essential features: partially implemented

| Feature | What works | What is missing |
|---|---|---|
| **Confirm completed trades and rate participants** | Scheduling a session; completion only after **both** members confirm, with the wallets settled in the same step; a star rating with feedback tags, saved online | Ratings are not checked against a completed trade, a member can be rated only once, and only one participant of a group trade can be rated (see *Known issues*) |

### Other areas

| Area | Features |
|---|---|
| Account | Phone sign-in or sign-up from one entry point with Firebase Authentication (SMS code), first and last name, username unique across all members, location from a list or the device, private location option, editable profile and skills saved to Firestore, code verification for a new phone number, sign out, delete account after verifying the phone number again (also removes the member's listings, saved skills, blocks, profile, public profile and username; ratings and reports are kept) |
| Discover | Saved skills kept per member |
| Posting | Group trades from the same page of selections |
| Trading | Offering a skill or wallet credits, scheduling and rescheduling a session, completion, disputes |
| Profile | Level and XP progress, rating, badges earned from activity, reviews given and received, skills |
| Group trades | Invite only: create, invite by username, accept or decline, group chat, completion once every member confirms, rating |
| Chat | Direct and group chats with one-tap replies |
| Wallet | Balance, credits on hold for active trades, hide or show, earned and spent totals, transaction history with details |
| Notifications | In-app notifications for messages, proposals, counteroffers, sessions, group invitations and completions, following the notification switches in Settings |
| Safety | Report a member or trade with optional details (sent online, once per member or trade), optionally block the member afterwards, send a complaint and get a confirmation, block and unblock, track cases in the Safety Centre |
| Settings | Edit profile, dark mode, notification and privacy switches on one page |

**End-to-end trade flow with stored results:** Account 2 messages Account 1 from a listing → proposes a trade in the chat → Account 1 sends a counteroffer → Account 2 accepts → a session is scheduled → both members confirm completion → both wallets are updated. Each step is saved in Firestore and seen by both members.

## Run the app

### Requirements

- Flutter SDK with **Dart 3.13.4 or newer** (`pubspec.yaml`: `sdk: ^3.13.4`). The team used Flutter 3.47.9 (stable).
- Git and Google Chrome.

### Steps

```bash
git clone https://github.com/Wajza/swe463-project.git
cd swe463-project/souq_skills
git checkout phase-3
flutter pub get
flutter run -d chrome
```

The app opens on the welcome screen and connects to the team's Firebase project (`souq-skills`).

### Firebase setup

- **Chrome (recommended): no setup and no Firebase Console access are needed.** The web Firebase configuration is in `lib/firebase_options.dart`, which is in the repository. `google-services.json` is not used on the web.
- **Android: extra configuration is needed.**
  - The Android build applies the Google Services Gradle plugin, so it needs `android/app/google-services.json`. This file is deliberately excluded by `.gitignore`; download it from the Firebase Console (Project settings → Your apps) or run `flutterfire configure`.
  - For phone sign-in, the SHA-1 and SHA-256 fingerprints of the machine building the app must be added in the Firebase Console.
  - Without these, run the app in Chrome instead.
- **Project owners only:** the Phone sign-in provider must be enabled in the Firebase Console, and the Firestore rules deployed (see *Security rules*).

### Android release APK

```bash
cd souq_skills
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

- Needs `android/app/google-services.json` (see *Firebase setup*). The application id is `com.example.souq_skills`, the one registered in Firebase; changing it needs a new Android app in the Firebase Console and a new `google-services.json`.
- **Signing:** without `android/key.properties`, the release APK is signed with the debug key. That is fine for installing and testing, but not for the Play Store. To sign with the team's upload key, create `android/key.properties` (never commit it, or the keystore; both are in `android/.gitignore`):

  ```properties
  storeFile=C:/path/to/upload-keystore.jks
  storePassword=...
  keyAlias=upload
  keyPassword=...
  ```

- Phone sign-in on a device needs the SHA-1 and SHA-256 fingerprints of the key that signed the APK (debug or upload key) in the Firebase Console.

### Test accounts

| Account | Phone number (without +966) | Verification code |
|---|---|---|
| Account 1 | `501234567` | `123456` |
| Account 2 | `507654321` | `123456` |

These accounts rely on both numbers being listed, with the code `123456`, under Firebase Console → Authentication → Sign-in method → Phone → *Phone numbers for testing*. Firebase then accepts the code without sending an SMS. (In the offline test mode used by `flutter test`, where Firebase is not initialized, the code `123456` is accepted for any number.)

### Signing in

1. Press **Get started**.
2. Enter the phone number without `+966` and press **Continue**. If a reCAPTCHA check appears, complete it.
3. Enter the 6-digit code and press **Verify**.
4. A number with no account yet goes on to **Create account**: enter a first name, last name, username and location, then press **Create account**.

**Two accounts at the same time:** sign in to Account 1 in a normal Chrome window. Open the app's address (shown by `flutter run`, for example `http://localhost:xxxxx`) in a Chrome **Incognito** window and sign in to Account 2. Tabs of the same window share one sign-in, so they cannot be used for this.

### Security rules

The Firestore rules are in `firestore.rules`. Only project owners deploy them, after the rules tests pass:

```bash
firebase deploy --only firestore:rules --project souq-skills
```

### Resetting

To clear what is kept on one device, clear the browser's site data or the app's storage. Accounts, profiles, public profiles, usernames, listings, saved skills and blocks live in Firestore and are removed with **Delete account**; reports and ratings sent online are kept.

## Final demonstration

The run sheet for the final demonstration, with the order, accounts, suggested presenters and a pre-demo checklist, is in [DEMO.md](DEMO.md).

## Testing

### Automated

```bash
cd souq_skills
flutter analyze
flutter test
```

`flutter test` needs no Firebase connection. Without an initialized Firebase app, the app uses in-memory stand-ins for each Firebase repository (for example `DemoAuthRepository`, `DemoProfileRepository`, `DemoListingRepository`, `DemoTradeRepository`, `DemoWalletRepository`, `DemoChatRepository`), and the tests that cover Firestore behaviour inject them directly. On 27 Nov 2026, all 552 tests passed.

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
| `test/account_deletion_reauth_test.dart` | Verifying the phone number again before deleting: success, a wrong code, going back, a code that cannot be sent, the time limit, and that no account data is removed until it succeeds |
| `test/public_profile_repository_test.dart` | What a public profile shares (never the phone), hidden profiles and locations, reading other members |
| `test/public_profile_test.dart` | Publishing at sign-up, edits and the *Public profile* switch, owner names on listings, fetching each member once, failures, account switching, publishing older accounts at sign-in |
| `test/blocked_members_repository_test.dart`, `test/blocking_test.dart` | Blocking and unblocking online first, what a block hides (Home, Saved skills, listing details, profiles), the Blocked members screen, load failures with retry, account switching, account deletion, and chat and group-invite filters |
| `test/report_repository_test.dart`, `test/reports_test.dart` | What a report stores, fixed ids and duplicates, reporting members, trades and complaints online first, failures and retry, optional details and blocking afterwards, the online dispute method, the Safety Centre states, account switching, and keeping reports after account deletion |
| `test/review_repository_test.dart` | What a rating stores (no profile data), its fixed id, refusing self-ratings, invalid stars or tags and duplicates, hidden profiles |
| `test/ratings_test.dart` | Rating a real member online first, failures and retry, rating once, loading and refreshing ratings, visibility, deleted accounts, rating badges |
| `test/chat_test.dart` | Conversation ids and message validation, both members seeing the same chat, live replies, unread counts and notifications, blocking, account switching, demo members |
| `test/trades_test.dart` | Proposals, counteroffers, accepting, declining and cancelling between two members, sessions, completion only after both confirm, live updates, blocking, demo members, offline mode |
| `test/wallet_test.dart` | Opening a wallet with the welcome credits, settlement on completion, who pays, short balances, no double payment, both members or one member confirming at the same time, refused completions changing nothing, members outside a trade, group rewards claimed at once, the ledger always adding up to the balance, countering a credit offer, live balance, account switching |
| `test/group_trades_test.dart` | Group trades online: invitations, completion once every member confirms, rewards, leaving and removal, the group chat, the Community Builder badge count, account switching |
| `test/account_switch_and_trade_action_test.dart` | Demo-member replies never reaching the next account; trade changes showing progress, refusing a second tap, explaining failures in words and never staying stuck loading |
| `test/notifications_test.dart` | Notifications for group trades, proposals, counteroffers, sessions and completions; settings and blocks respected; opening and marking notifications read |
| `test/trade_details_reschedule_test.dart` | Rescheduling a session from the trade's session card |
| `test/frontend_a_integration_test.dart` | Skill credits explanation, wallet totals and transaction details, listing reviews page, published screen, profile skills, Safety Centre |

### Firestore security rules

The rules in `firestore.rules` are tested against the Firestore emulator. This needs Node.js, Java 21 or newer, and the Firebase CLI. It runs against a local `demo-` project, so nothing reaches the real one. On 27 Nov 2026, all 218 rules tests passed (0 failed), including both members confirming a trade at the same time and stale confirmations.

```bash
cd souq_skills
npm --prefix firestore_rules_test install    # first time only
firebase emulators:exec --only firestore --project demo-souq-skills "npm --prefix firestore_rules_test test"
```

`firestore_rules_test/rules.test.mjs` repeats the app's own Firestore reads and writes. It checks what members may do and what is refused for:

- profiles and public profiles;
- usernames;
- listings;
- saved listings;
- blocked members;
- reports;
- reviews, and the *Public profile* switch that hides them;
- account deletion cleanup;
- direct chats and their messages;
- trades and proposals;
- wallets and their transactions;
- group trades and their chat.

### Manual

These steps use the two test accounts. Account 1 offers **Baking** and Account 2 offers **Piano**. Run them in order: the wallet step needs an accepted, scheduled and completed trade.

1. **Sign in** as Account 1 (see *Signing in*). Enter `123` first and confirm the validation message.
2. **Create and manage a listing (Account 1):** press **Post** and press **Publish** with nothing selected to see the errors. Choose **Cooking** and **Baking**, then **Piano** as *Skill you want in exchange* and **Riyadh** as the city, and press **Publish**. Press **View listing** → **Edit listing**, change the session length and press **Save changes**. Open **Edit listing** again and use the **⋮** menu to **Pause listing**, then **Resume listing**. Post a second listing and delete it from the **⋮** menu (**Delete listing** → **Delete**).
3. **Browse, search and filter (Account 2):** sign in as Account 2 in an Incognito window. On Home, type `baking`; only matching listings remain. Clear it, press **Filter**, choose **Cooking**, then **Riyadh**, then change the city to **Jeddah**; Account 1's listing disappears.
4. **Listing details and reviews (Account 2):** open Account 1's listing. Its details, owner and **Propose a trade** are shown. Press **See all** next to Reviews to see the owner's ratings, or "No reviews yet".
5. **Propose through chat (Account 2):** on the listing, choose **Message member** from the **⋮** menu and send a message. In the chat, press the **Propose a trade** icon, choose *You offer* → **My skill** (Piano) and *You want* → **Baking**, then press **Send proposal**. Account 1 sees the message and the proposal card in **Chats**.
6. **Counteroffer (Account 1):** press **Counter** on the card, change the session length (for example 60 → 90 min) and press **Send counteroffer**.
7. **Accept (Account 2):** press **Accept** on the counteroffer card. Both accounts see the trade in **Profile → My trades** with the agreed terms.
8. **Decline (optional):** send another proposal from Account 2; Account 1 presses **Decline** and confirms. It can no longer be accepted.
9. **Offer credits, schedule and complete:**
   - Note both wallet balances (120 for a new account).
   - Account 2 sends a new proposal with *You offer* → **Credits** and **20 credits**; Account 1 presses **Accept**. Account 2's wallet shows the 20 credits on hold.
   - Open the trade (**View trade**), press **Schedule session**, pick a future date and time, and press **Save session**.
   - One account presses **Mark as complete**; the other presses **Confirm completion**.
10. **Wallet:** open **Wallet** on both accounts. Account 1 has 150 credits (+10 reward, +20 payment) and Account 2 has 110 (+10 reward, −20), each listed under *Activity*.
11. **Rate (partially implemented):** on the completed trade, press **Rate this experience**, choose stars and tags, and press **Submit rating**. The trade then shows *Your rating*.
12. **Complaint:** Profile → Settings → Help and support → **Send a complaint**, pick a topic and send. A message confirms you will get feedback soon, and the complaint appears in the Safety Centre.
13. **Change phone:** Profile → Settings → Edit profile, change the phone number, press **Save**, and verify the code.
14. **Persistence:** close and reopen the app. You stay signed in and your changes remain.
15. **Back behaviour:** on Android, Back from any tab returns to Home before leaving the app.
16. **Delete account:** Profile → Settings → **Delete account**, then enter the code sent to the account's phone number. The account's listings disappear for other members, and its username can be taken again.

## Architecture

```text
souq_skills/lib/
├── main.dart, app.dart   # Entry point and app configuration
├── core/                 # Routes, router, theme, validators, options, formatters
├── models/               # Immutable data classes with JSON support
├── data/                 # Firebase access: auth, profiles, listings, saved listings, blocked members,
│                         # reports, reviews, chats, trades and proposals, group trades, wallets
├── services/             # Business rules, repository, data source, live online data
├── screens/              # One folder per feature
└── widgets/              # Reusable design-system components
```

**State ownership.** `Repository` is the single owner of app state and a `ChangeNotifier`. Screens read through services inside `LiveView` or `LiveEntity`, so the interface updates whenever data changes. Only temporary form input lives in a widget's `State`.

### Data source

Shared data is kept in Firebase, each part behind an interface in `lib/data/` with a Firebase version and an in-memory one for tests:

| Data | Where | Interface |
|---|---|---|
| Sign-in | Firebase Authentication (phone) | `AuthRepository` |
| Profiles | Firestore `users/{uid}`, private to the member | `ProfileRepository` |
| Public profiles | Firestore `publicProfiles/{uid}`: names, username and, unless *Public profile* or the location is off, city, bio, skills and availability; never the phone. Saved in the same transaction as the profile, readable by signed-in members one at a time | `ProfileRepository`, `MemberService` |
| Usernames | Firestore `usernames/{username}`, claimed in the same transaction as the profile | `ProfileRepository` |
| Listings | Firestore `listings/{listingId}`, with the owner's uid | `ListingRepository` |
| Saved skills | Firestore `users/{uid}/saved/{listingId}`, private to each member | `SavedListingsRepository` |
| Blocked members | Firestore `users/{uid}/blocked/{blockedUid}`, private to the member who blocked; only real accounts, never oneself. Blocks of the built-in demo members stay on the device | `BlockedMembersRepository`, `SafetyService` |
| Reports | Firestore `reports/{reportId}`; see *Reports* below | `ReportRepository`, `SafetyService` |
| Reviews | Firestore `reviews/{reviewId}`; see *Ratings and badges* below | `ReviewRepository`, `ReviewService` |
| Direct chats with real members | Firestore `conversations/{dm_smallerUid_largerUid}` with the latest message and each member's read time, and its `messages/{messageId}` by uid only, including proposal cards. Readable by the two members only; messages are never changed or deleted. Live while signed in | `ChatRepository`, `ChatService` |
| Trades and proposals with real members | Firestore `trades/{tradeId}` and `proposals/{proposalId}`, by uid only; a proposal and its trade are written together, and a counteroffer is a new proposal on the same trade. Readable and changeable by the two members only. Scheduled sessions are saved on the trade, which completes only once both members confirm. Live while signed in | `TradeRepository`, `OnlineTrades`, `TradeService`, `ProposalService` |
| Group trades | Firestore `groupTrades/{groupId}`, readable by its members and invited members, and its `messages/{messageId}` group chat. A group completes once every member confirms. Live while signed in | `GroupTradeRepository`, `OnlineGroups`, `GroupTradeService` |
| Wallets | Firestore `wallets/{uid}` (the balance) and its `transactions/{entryId}` ledger. Opened once with 120 welcome credits; a trade's completion settles both wallets in the same transaction (+10 each, and any credits offered move from the payer to the other member); +15 for each member of a completed group trade. The rules allow only these exact changes | `WalletRepository`, `OnlineWallet`, `WalletService` |

**Reports.** Each report is one document in the top-level `reports` collection:

| Field | Value |
|---|---|
| `reporterId` | The reporter's Firebase uid |
| `kind` | `memberReport`, `tradeReport`, `tradeDispute` or `complaint` |
| `reason` | One of the fixed reasons offered (at most 60 characters) |
| `details` | Optional, at most 500 characters; left out when empty |
| `memberId` | Member reports only: the reported member's uid |
| `tradeId` | Trade reports and disputes only: the trade's id as the reporter's app knows it |
| `listingId` | Optional, when a listing is involved |
| `status` | `submitted` when sent |
| `createdAt` | Server time |

- **One report per target.** A member report, trade report or dispute has the fixed id `{reporterUid}_{kind}_{targetId}`, so the same member or trade can be reported once per kind, even after it is resolved. The app says "You already reported this member" (or trade), and the rules refuse a second one too. Complaints get a new id each.
- **Security.** Only the reporter can read their own reports, and lists must be filtered by their `reporterId`. Nobody can change or delete a report from the app. Reports cannot be sent as someone else, about oneself, or about an account that does not exist (demo ids included).
- **Moderation.** Changing a report's status needs trusted server-side access (the Admin SDK or the Firebase Console); the app only reads it.
- **Account deletion keeps reports.** They stay for moderation after the reporter or the reported member deletes their account.
- **Demo members.** Reports about the built-in demo members, and every report in the offline demo, stay on the device, with the same once-per-target rule.
- **Sent first, shown after.** A report is only shown as received, and the Safety Centre only lists it, once it has been saved online. After reporting a member, blocking them is offered but never done automatically; if blocking fails, the report still counts.

**Ratings and badges.** Each rating of a real member is one document in the top-level `reviews` collection, by uid only:

| Field | Value |
|---|---|
| `reviewerId` | The reviewer's Firebase uid |
| `subjectId` | The rated member's Firebase uid; never the reviewer |
| `rating` | A whole number from 1 to 5 |
| `tags` | Up to five of the fixed feedback options, each once (there is no free-text comment) |
| `contextId` | The trade or group trade's id |
| `contextKind` | `trade` or `groupTrade` |
| `skillTitle` | Optional, at most 100 characters |
| `createdAt` | Server time |

- **Once per member, for now.** The id is `{reviewerUid}_{subjectUid}`, so each member can rate another member once; the app says "You already rated this member", and the rules refuse a second one. This could become once per completed trade (for example `{tradeId}_{reviewerUid}`), checked by the server.
- **Security.** Ratings cannot be sent as someone else, about oneself, about an account that does not exist (demo ids included), with a rating outside 1–5, unknown tags or extra fields. Nobody can change or delete a rating from the app.
- **Visibility.** A member's ratings follow their *Public profile* switch, which is stored as `profileVisible` in `publicProfiles/{uid}`; when it is off, the rules also require the rest of the public profile to be blank. Others can only list a member's ratings while it is on, and see "Ratings are private" otherwise. The member always sees the ratings they received, and each reviewer the ratings they wrote. Hiding never deletes ratings.
- **Sent first, shown after.** *Submit rating* shows *Saving…* and ignores further taps; the rating is only kept on the device, and shown, once saved online. On failure the screen explains what happened, keeps the stars and tags, and offers *Try again*. A rating that finishes after another account signed in is not shown.
- **Loading.** `ReviewService.refreshReviews` loads the member's own given and received ratings, and other members' ratings once per account in the background when listings load or a profile opens. The *Ratings and reviews* screen loads again each time it opens and on pull to refresh, with loading, empty and error states. Ratings loaded for one account are never shown to another.
- **Account deletion keeps ratings,** both given and received, so nobody can erase bad ratings by deleting their account. A deleted reviewer is shown as "Member". A deleted member's public profile is gone, so their received ratings are no longer shown to others.
- **Deleting an account asks for the phone number again.** Firebase only deletes an account that signed in recently, so *Delete account* first sends a code to the account's own number. Nothing is deleted until it is verified; a wrong code, going back, or a code that cannot be sent leaves the member signed in with all their data. The check counts for four minutes, within Firebase's five, and only for the account that passed it. The offline demo deletes without it.
- **Demo members.** Ratings of the built-in demo members, and every rating in the offline demo, stay on the device, once per exchange as before, and the demo member still rates back.
- **Badges** are worked out from activity and never stored online; they are taken away if the activity no longer qualifies (for example, fewer ratings after a refresh). Each badge is announced once per account. *Top Rated* and *Helpful Reviewer* count the ratings received and given, online ones included; *First Exchange* and *Trusted Trader* count completed trades, online ones included; *Skill Sharer* counts the member's listings; *Community Builder* counts group trades on the device only.

Changes to these are saved online first and only then shown on the device. On failure the screen explains what happened, and nothing changes. The services translate between the member's Firebase uid and the app's local id for the current member (`'me'`) at this boundary. A different account signing in on the same device never sees the previous account's data.

**Kept on the device only:** in-app notifications, app settings (such as dark mode), and everything about the built-in demo members (their trades, chats, group trades, reviews, blocks and reports). `AppDataSource` is implemented by `LocalDataSource` using `shared_preferences`, and every change is saved as a JSON snapshot.

| State | Behaviour |
|---|---|
| Loading | `AppGate` shows a spinner while saved data is read |
| Success | The app opens where the member left off |
| Empty | Each list has its own empty message |
| Failure to load | An explanation with **Try again** |
| Failure to save | A banner on every screen with **Try again** |
| Corrupt or outdated data | Falls back to the sample data |

Screens that show online data use the load state of the service they read, so an empty list or a zero is never shown before the data has arrived:

| Screen | Loading | Failure |
|---|---|---|
| Home, My listings, Saved skills, Blocked members | Spinner | Error card with **Try again** |
| My Trades | "Loading your trades…" instead of the empty message | Error card with **Try again** |
| Wallet | Spinner in the balance card instead of 0, and "Loading your wallet…" | Error card with **Try again**; the balance shows "—" |
| Profile | "…" for Trades and Credits, "Loading your level…" | Error card with **Try again** for the level |
| Trade, proposal, group, listing and case details opened directly (for example from a notification) | "Loading…" instead of *Page not found* | "Could not load this page" with **Try again** |
| Offering credits in a proposal | "Loading your credits…" instead of "not enough credits" | **Try again** |

**Reusable components.** All screens are built from `AppPage`, `SouqButton`, `SelectField`, `OptionSheet`, `ChoiceChipRow`, `SkillPostForm`, `ProposalForm`, `IssueForm` and `ConversationView`, among others.

**Secrets.** The repository contains no secrets or service-account keys.

- `lib/firebase_options.dart` holds the Firebase *client* configuration, including API keys. These identify the app to Firebase rather than grant access; access is controlled by the security rules.
- `android/app/google-services.json` and other local files are excluded by `.gitignore`.

### XP and levels

XP is worked out by `ExperienceService` from records the backend already verifies, so it cannot be raised from the app and nothing extra needs storing or protecting:

| Source | XP | Why it can be trusted |
|---|---|---|
| Completed trade | 100 each | Completed only once both members confirm, settled in Firestore together with the wallets |
| Completed group trade | 150 each | Completed once every member confirms |
| Rating received | 20 each | The rules allow one rating per member |
| Published listing | 25 each, up to 5 | Capped so posting many listings cannot be used to farm XP |

Every 250 XP is a new level. Titles: *Newcomer* (levels 1–2), *Skill Swapper* (3–5), *Trusted Trader* (6–9) and *Community Guide* (10 and above). The profile shows the level on the avatar and a progress card; tapping the card lists each source with the member's own counts. Until trades, group trades, listings and ratings have loaded, the card shows a spinner rather than a low level. Only the member's own level is shown, because other members' trades are private.

### Packages, their purpose and licenses

| Package | Version | Purpose | License |
|---|---|---|---|
| `flutter` | SDK | Framework and navigation | BSD 3-Clause |
| `firebase_core` | 5.1.0 | Connecting to the Firebase project | BSD 3-Clause |
| `firebase_auth` | 7.0.1 | Phone sign-in with SMS verification | BSD 3-Clause |
| `cloud_firestore` | 7.1.0 | Profiles, public profiles, usernames, listings, saved skills, blocks, reports, reviews, chats, trades, proposals, group trades and wallets | BSD 3-Clause |
| `shared_preferences` | 2.5.6 | On-device storage for notifications, app settings and the built-in demo members' data, saved as a JSON snapshot | BSD 3-Clause |
| `geolocator` | 14.1.2 | Reading the device's location to fill in the nearest city | MIT |
| `flutter_test` | SDK | Widget and unit tests (development only) | BSD 3-Clause |
| `flutter_lints` | 6.0.0 | Static analysis rules (development only) | BSD 3-Clause |
| `@firebase/rules-unit-testing` (npm) | 6.0.0 | Firestore rules tests against the emulator, in `firestore_rules_test/` (development only) | Apache 2.0 |
| `firebase` (npm) | 13.2.0 | Firebase client used by the rules tests, in `firestore_rules_test/` (development only) | Apache 2.0 |

Versions are those locked in `pubspec.lock` and `firestore_rules_test/package-lock.json`. Each license was read from the package's own license file, or for npm from its lock entry. All are permissive open-source licenses that allow use in this project. They require keeping the copyright notice when the code is redistributed, and the Apache 2.0 packages also require keeping their NOTICE files. The packages these depend on have their own licenses, listed on each package's page on pub.dev or npm.

## Known issues and limitations

- **Notifications about matching listings are not implemented.**
- **Other members' levels are not shown,** because their trades are private to them.
- **Ratings are not tied to a verified trade.** The rules do not check that the trade in `contextId` exists, is completed, or includes both members, so any signed-in member can rate any real member once. Server-side trade checks are still needed.
- **One rating per member, not per trade.** Rating the same member after a second exchange is refused, so the trade screen does not offer *Rate* for that exchange.
- **Only one participant of a group trade can be rated:** the organizer, or for the organizer the first other member.
- **Trade ids in reports are not checked.** A trade report or dispute stores the trade id, but the rules do not confirm that the trade exists or that the reporter took part.
- **The built-in demo members are simulated** on the device; real members are never simulated. `MemberSimulator` accepts proposals after about 30 seconds, and within about 2 seconds replies in chat, accepts group invitations and returns a 5-star rating.
- **Other members' ratings are loaded once per account;** new ratings of others show after the app is restarted, while the member's own show when the Ratings screen opens.
- A member whose public profile is not published yet (an older account before it next signs in) is shown as "Member".
- **Listings refresh when Home opens and when pulled down,** not live, and all listings are loaded at once; search and filters run on the device.
- **Device location picks the nearest listed city,** even if the member is outside Saudi Arabia.
- **Notifications are local in-app notifications only.** They are generated while the app is open; background and push notifications are not supported.
- **Other members' public profiles are fetched once and then kept on the device;** changes they make show after the app is restarted on a new account or the copy is refreshed.
- **Blocking is one-way and silent.** A blocked member is not told, and still sees the listings of the member who blocked them. Blocking hides their listings on Home and in Saved skills, and on their listing and profile it offers only Unblock. Direct chats are checked on the server: neither member can message the other while either has blocked them, and the sender is only told the message could not be sent.
- **Android needs extra Firebase configuration** that is not in the repository (see *Firebase setup*).
- **A manual check on physical devices with two real accounts has not been recorded,** including the device location permission prompt.

## Progress reports

Drawn from the repository's commit history.

| Date | Progress |
|---|---|
| 19 Sep 2026 | Repository created; essential features and team details documented |
| 4 Oct 2026 | Flutter project and web platform files added |
| 17 Oct 2026 | Project structure and basic app; shared widgets refactored; fixes to the post-skill and safety screens |
| 6 Nov 2026 | Provider-based profile, listings, posting, wallet, badges, and safety work on branch `phase3/frontend` |
| 9 Nov 2026 | Screens and services added on `main`; front end rebuilt with working flows and a single design; selection-first redesign with an on-device data source |
| 10–11 Nov 2026 | Firebase project configured; phone authentication, profiles and skills, unique usernames, listings, public profiles, blocking, reports and ratings in Firestore, with security rules (pull request #2) |
| 11–13 Nov 2026 | Real-time chat, trades and proposals, wallet and credits, online group trades and in-app notifications in Firebase |
| 14 Nov 2026 | Frontend features from `phase3/frontend` integrated (pull request #3) |
| 26 Nov 2026 | Feedback fixes: loading and error states for My Trades, Wallet, the profile and screens opened directly; XP and levels; disputes sent online; Community Builder counts online group trades; *Rate* offered only when a rating can be saved |

## Contribution record

Based on the November 2026 commits and pull requests. Merge commits are cited as evidence only. Commits do not capture design, testing, meetings or report writing.

| Member | Assigned task | Completed work | Evidence |
|---|---|---|---|
| Yasmeen Alshehri (202271660) | Rating eligibility, per-trade ratings, profile and listing integrity, privacy preferences, and automated testing (Phase 4). | Implemented Phase 4 rating eligibility and per-trade ratings, allowing members to rate each other once per completed trade, including group trades. Updated Firestore security rules to validate rating eligibility while preserving older ratings. Improved privacy preference persistence, profile validation, and listing publishing requirements. Fixed profile refreshing, rating page loading, and accepted proposal cards to display accurate trade statuses. Added regression tests and updated README documentation. The rating data also supports the existing XP system, although the XP and levels logic was implemented separately. | **Commits:** `c66e23a`, `1a5ab02`, `284d87a`, `8f73981`, `f8d1ecd`, `acb5a47`, `238f593`, `d8f5854`, `cb5f182`, `2323350`, `9f4119b`.<br>**PRs:** #4 and #5.<br>**Testing:** At `9f4119b`, 533 Flutter tests and 216 Firestore rules tests passed. `flutter analyze` reported no issues. |
| Fatimah Alshehab (202278660) | Backend Development | Firebase real-time chat; trades and proposals in Firebase; wallet and credits; online group trades; in-app notifications | Commits `80db108`, `b4783f7`, `f53b9dd`, `82450d8`, `85bf3c4` (Git name `xfas51`, linked on GitHub to Fatimah-Alshehab) |
| Wajd Alghamdi (202262140) | Frontend Development | Screens and services for trading and support; front-end rebuild with working flows and one design; selection-first redesign with on-device persistence | Commits `571dc10`, `00f3c80`, `a01d22c` |
| Raghad Almaghrabi (202156390) | Frontend Development | Profile display and shared profile state; badges screen; wallet balance toggle, transaction details and credit guide; listing details and reviews page; skill posting forms and editing owned listings; My Trades; Safety Centre guidance; notification preferences. Built on branch `phase3/frontend`; parts were integrated into `main` in `3529049` | 16 commits on `phase3/frontend` (6 Nov), from `f50079c` to `91bbf2a`; co-author of `3529049` |

**Frontend A integration.** Commit `3529049` (pull request #3) integrates the Frontend A features from branch `phase3/frontend` into `main`. It was co-authored with Raghad Almaghrabi. The integrated features are Raghad's original work, listed in her row above; they are not part of the Backend Developer B work.

## AI assistance disclosure

AI assistance (Claude Code, by Anthropic) was used to rebuild the front end, implement the data layer, write tests, and draft this README. It was also used for debugging, code review (feature, security and requirements audits), and documentation, such as the testing instructions. Some of the commits made with its help are marked `Co-Authored-By: Claude`. The team remains responsible for reviewing, testing and submitting the work.
