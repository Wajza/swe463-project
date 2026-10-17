# Souq Skills

Souq Skills is a Flutter starter application for a skill-exchange marketplace in Saudi Arabia. Members can offer what they know and discover useful skills from their community without cash payments.

## Team

| Name | Student ID | Initial responsibility |
|---|---:|---|
| Wajd Alghamdi | 202262140 | UI and UX |
| Yasmeen Alshehri | 202271660 | Trade flow |
| Fatimah Alshehab | 202278660 | Backend and data |
| Raghad Almaghrabi | 202156390 | Profile and quality |

All team members contribute to the implementation and documentation. Responsibilities may change as the project progresses.

## Project purpose and Phase 2 scope

This repository contains the SWE436 Phase 2 prototype. It demonstrates the proposed project structure, Figma-informed visual direction, screen organization, and basic built-in Flutter navigation.

Implemented in this phase:

- Figma-informed welcome, phone number, verification, and verification success screens
- Home and Discover screen with search, categories, alerts, saved searches, filters, and listing cards
- Listing detail and propose-a-trade navigation
- Post a Skill: Skills, Details, Listing Preview, and Published screens
- Chat and Negotiate, Counteroffer Dialog, and Complete Trade and Review placeholders
- Skill Wallet, Profile, Safety Centre, and Report Received screens
- Five-item bottom navigation for Home, Chats, Post, Wallet, and Profile
- Reusable widgets, planned domain models, and planned service interfaces

This remains a simple starter app. It has no backend, database, real authentication, messaging, publishing, payments, notifications, or complete trade logic. Those features belong to Phase 3.

## Prerequisites

- Flutter SDK with Dart 3.13 or newer
- Android Studio and an Android emulator, or Xcode and an iOS simulator on macOS
- Chrome for the web version

Check the local setup with:

```bash
flutter doctor
```

## Run the application

From the repository root:

```bash
cd souq_skills
flutter pub get
flutter run
```

Choose a target explicitly:

```bash
flutter devices
flutter run -d chrome
flutter run -d <android-device-id>
```

The **Get started** button demonstrates the phone verification flow. The fields and code are placeholders; any entered values can continue through the demo. The **Start exploring** button opens the main application shell.

## Folder structure

```text
souq_skills/
├── android/                         # Android platform runner
├── ios/                             # iOS platform runner
├── web/                             # Web platform runner
├── assets/                          # Reserved for supplied images and icons
├── lib/
│   ├── main.dart                    # App theme, app entry point, main shell
│   ├── screens/
│   │   ├── auth/                    # Welcome and verification screens
│   │   ├── home/                    # Discover, saved searches, and alerts
│   │   ├── listings/
│   │   │   └── post_skill/          # Post-a-skill flow
│   │   ├── trades/                  # Chat, counteroffer, and review screens
│   │   ├── wallet/                  # Skill wallet
│   │   ├── profile/                 # Profile
│   │   └── safety/                  # Safety and report screens
│   ├── models/                      # Planned User, SkillListing, Trade, Message models
│   ├── services/                    # Planned auth, listing, trade, and notification services
│   └── widgets/                     # Reusable buttons, cards, logo, and navigation
├── test/                            # Widget smoke tests
├── pubspec.yaml                     # Flutter project configuration
└── README.md
```

## Dependencies and package purposes

The project currently uses the following packages:

| Package | Type | Purpose |
|---|---|---|
| `flutter` | SDK dependency | Provides Flutter's Material Design widgets, application framework, and built-in `Navigator` used by the starter app. |
| `flutter_test` | Development dependency | Provides widget testing APIs used by the smoke tests in `test/`. |
| `flutter_lints` | Development dependency | Provides the recommended Dart and Flutter static-analysis rules used by `analysis_options.yaml`. |

No third-party runtime package has been added for Phase 2. The original project proposal lists `go_router`, `provider`, Firebase packages, geolocation packages, and Firebase Messaging as possible future packages; they are intentionally not installed because this starter uses Flutter's built-in navigation and does not implement backend functionality.

## Verification checklist

- [ ] Run `flutter doctor`.
- [ ] Run `flutter pub get`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter run -d chrome` or launch on an emulator.
- [ ] Check the welcome, phone, verification, success, discover, listing, post, wallet, profile, safety, and trade flows.
- [ ] Confirm that secondary screens support back navigation.


## GitHub submission

After reviewing the changes, the group can commit and push them using its normal workflow:

```bash
git status
git add souq_skills README.md
git commit -m "Refine Souq Skills Phase 2 starter app"
git push origin <your-branch-name>
```

No commit or GitHub link is claimed by this README.

## AI assistance disclosure

AI assistance was used to help scaffold the Flutter screens, reusable Material widgets, navigation wiring, README wording, and widget smoke tests, and to translate the supplied visual references into code. The team remains responsible for reviewing, testing, adapting, and submitting the code, design, and documentation. No Phase 3 backend or production functionality is represented as complete.
