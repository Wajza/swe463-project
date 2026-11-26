# Final demonstration plan

A run sheet for presenting Souq Skills in about 12 minutes. Presenters are suggested from each member's responsibility in the README; swap them as the team agrees.

## Before the demo

- [ ] Pull `main`, then run `flutter pub get` and `flutter test` (all should pass).
- [ ] Both test numbers, `501234567` and `507654321`, are listed with code `123456` under Firebase Console → Authentication → Sign-in method → Phone → *Phone numbers for testing*.
- [ ] The latest `firestore.rules` are deployed (`firebase deploy --only firestore:rules --project souq-skills`).
- [ ] Run `flutter run -d chrome`. Sign in to **Account 1** in a normal Chrome window, and to **Account 2** in an **Incognito** window at the same address.
- [ ] Account 1 has at least one listing (to receive a proposal), and Account 2 has enough credits to offer some.
- [ ] Place the two windows side by side so the audience sees both update live.
- [ ] Keep a backup: a screen recording of the full flow, in case the network fails.

## Run sheet

| # | Time | What to show | Account | Suggested presenter |
|---|---|---|---|---|
| 1 | 1 min | **Sign-in:** Get started → phone number → code. A wrong number shows its validation message. | 1 | Wajd (UI and UX) |
| 2 | 1 min | **Home:** search as you type, the filter button (category, city, tags), a listing's details and *See all* reviews. | 2 | Wajd |
| 3 | 1 min | **Post a skill:** Publish with nothing selected shows the errors; then pick a category and skill and publish. It appears in My listings. | 1 | Raghad (profile and quality) |
| 4 | 2 min | **Propose and negotiate:** from Account 1's listing, Account 2 sends a proposal in chat. Account 1 presses **Counter** on the card and offers credits instead of a skill. Account 2 accepts. Both windows update live. | 2 → 1 → 2 | Yasmeen (trade flow) |
| 5 | 2 min | **Complete the trade:** schedule a session, then each member presses **Mark as complete**. Only the second confirmation completes it, and both Wallets update (+10 each, and the offered credits move). | 1 and 2 | Yasmeen |
| 6 | 1 min | **Rate and level up:** rate the exchange with stars and tags. The Profile shows the rating, the new XP and level, and badge progress. Tap the level card to show *How XP works*. | 1 | Raghad |
| 7 | 1 min | **Group trade:** create a group trade from Post, then **Invite** Account 2 by username. Account 2 accepts the invitation. | 1 → 2 | Fatimah (backend and data) |
| 8 | 1 min | **Safety:** report the trade or the member, see the case in the Safety Centre, and send a complaint to get the confirmation message. | 2 | Fatimah |
| 9 | 1 min | **Loading and error states:** in Chrome DevTools → Network, choose *Slow 4G* and sign in again, so the spinners show on Wallet ("Loading balance…") and My Trades before the data arrives. **Rehearse this first:** Firestore may serve cached data when offline rather than show an error, so if no error appears live, show the loading states and point to the automated tests in `test/load_states_test.dart` for the error states. | 1 | Fatimah |
| 10 | 1 min | **Behind the scenes:** the Firestore data for the trade and wallets in the Firebase Console, the README's known issues, and the test run. | — | Whole team |

## If something goes wrong

- **No code arrives:** the test numbers above don't send SMS; check that they are listed in the Firebase Console.
- **A screen says it could not load:** check the connection, then press **Try again**.
- **Both windows show the same account:** use an Incognito window for Account 2; tabs in the same window share one sign-in.
- **Running out of time:** skip steps 7–9 and finish with step 10.
