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
| Account | Phone sign-in or sign-up from one entry point, code verification, first and last name, unique username, location from a list or the device, private location option, editable profile with code verification for a new phone number, sign out, delete account |
| Discover | Skill feed on Home with search as you type, filters for category, city and tags, saved skills |
| Posting | Solo listings with Online only and Women only tags, and group trades, from one page of selections, with edit, pause, and delete |
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

Requires the Flutter SDK with Dart 3.13 or newer.

```bash
cd souq_skills
flutter pub get
flutter run -d chrome        # or: flutter run -d <android-device-id>
```

**Demo account:** press **Get started**, enter `501234567`, then press **Verify** (the code fills in automatically, as if read from an SMS). Any other valid number starting with 5 creates a new, empty account.

To reset the demo, clear the site data in the browser or the app storage on the device.

## Testing

### Automated

```bash
cd souq_skills
flutter analyze
flutter test
```

| Test file | Covers |
|---|---|
| `test/widget_test.dart` | Welcome screen, phone and code validation, bottom navigation |
| `test/app_flow_test.dart` | Home search and filters, rating flow through to the profile, solo and group posting, form validation, proposal to trade, new accounts |
| `test/profile_and_group_test.dart` | Counteroffers from the card, sign-up validation, unique usernames, device location, phone re-verification, group invitations, listing tags |
| `test/credits_and_complaints_test.dart` | Offering credits, holds, payment on completion, release on cancel, Edit profile location, complaints |
| `test/persistence_test.dart` | Save and restore, corrupt data, loading, load failure with retry, save failure with retry |
| `test/routes_test.dart` | Every route on a phone screen in light and dark themes, one main button per screen, missing arguments |

### Manual

1. **Sign in** with the demo account. Enter `123` first and confirm the validation message.
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

## Architecture

```text
souq_skills/lib/
├── main.dart, app.dart   # Entry point and app configuration
├── core/                 # Routes, router, theme, validators, options, formatters
├── models/               # Immutable data classes with JSON support
├── services/             # Business rules, repository, data source
├── screens/              # One folder per feature
└── widgets/              # Reusable design-system components
```

**State ownership.** `Repository` is the single owner of app state and a `ChangeNotifier`. Screens read through services inside `LiveView` or `LiveEntity`, so the interface updates whenever data changes. Only temporary form input lives in a widget's `State`.

**Data source.** `AppDataSource` is an interface, implemented by `LocalDataSource` using `shared_preferences`. Every change is saved as a JSON snapshot.

| State | Behaviour |
|---|---|
| Loading | `AppGate` shows a spinner while saved data is read |
| Success | The app opens where the member left off |
| Empty | Each list has its own empty message |
| Failure to load | An explanation with **Try again** |
| Failure to save | A banner on every screen with **Try again** |
| Corrupt or outdated data | Falls back to the sample data |

**Reusable components.** All screens are built from `AppPage`, `SouqButton`, `SelectField`, `OptionSheet`, `ChoiceChipRow`, `SkillPostForm`, `ProposalForm`, `IssueForm` and `ConversationView`, among others.

**Secrets.** The project contains no API keys or credentials.

### Dependencies

| Package | Purpose |
|---|---|
| `flutter` | Framework and navigation |
| `shared_preferences` | On-device storage |
| `geolocator` | Reading the device's location to fill in the nearest city |
| `flutter_test`, `flutter_lints` | Tests and static analysis (development only) |

## Known issues and limitations

- **Data stays on one device.** There is no server yet, so members cannot see each other's data across devices. The proposal listed Firebase; `AppDataSource` is the place to connect it.
- **Other members are simulated.** `MemberSimulator` accepts proposals after about 30 seconds, and within about 2 seconds replies in chat, accepts group invitations and returns a 5-star rating.
- **Verification is simulated.** No SMS is sent, the code fills in automatically, and any 6-digit code is accepted.
- **Device location picks the nearest listed city,** even if the member is outside Saudi Arabia.
- **Usernames are unique on this device only,** because there is no shared server yet.
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
