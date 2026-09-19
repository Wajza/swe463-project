# Souq Skills

A Flutter mobile app for a skill barter marketplace in Saudi Arabia. Users trade skills directly with one another. No money changes hands.

## Team

Course: SWE 463, Group 1

| Name | Student ID | Initial role |
|---|---|---|
| Wajd Alghamdi | 202262140 | UI and UX lead |
| Yasmeen Alshehri | 202271660 | Trade flow developer |
| Fatimah Alshehab | 202278660 | Backend and data lead |
| Raghad Almaghrabi | 202156390 | Profile and quality lead |

Every member contributes to both code and documentation. Roles may shift as the project progresses.

## Problem

Many people in Saudi Arabia have valuable skills, such as tutoring, design, cooking, or basic repair work, but limited disposable income to pay for services they need in return. Existing gig and freelance platforms are built entirely around cash payment, which excludes people who have time and skill to offer but cannot or do not want to pay. Souq Skills lets people trade skills directly, with a credits system to balance trades that are not an even swap.

## Target users

Young adults and university students in major Saudi cities such as Riyadh, Jeddah, and Dammam who have a marketable skill and want something specific in return without spending money, plus small local service providers looking to reach new customers through non cash exchanges.

## Features

### Essential
- Skill listing creation
- Browse and search by category, distance, and keyword
- In app trade chat with counter offers
- Trade confirmation and ratings
- Identity verification badge
- Skill credits wallet
- Saved searches and alerts
- Group trades

### Optional
- Gamification: levels and badges
- Dispute reporting

## Screens

| Screen | Purpose |
|---|---|
| Home and Discover | Nearby skill listings with search and category filters |
| Listing detail | One member's offer, what they want in return, their rating, and a propose a trade action |
| Post a skill | Form to create a new listing: offer, want, category, location |
| Chat and negotiate | In app messaging for a trade, including counter offers |
| Profile | Trade history, rating, verification badge, gamification progress |
| Skill wallet | Skill credit balance and recent transactions |

## Tech stack and planned packages

- Flutter and Dart
- [go_router](https://pub.dev/packages/go_router) (BSD 3 Clause) for navigation
- [provider](https://pub.dev/packages/provider) (MIT) for state management
- [firebase_core](https://pub.dev/packages/firebase_core), [firebase_auth](https://pub.dev/packages/firebase_auth), [cloud_firestore](https://pub.dev/packages/cloud_firestore) (BSD 3 Clause) for authentication and the database
- [geolocator](https://pub.dev/packages/geolocator) (MIT) and [geocoding](https://pub.dev/packages/geocoding) (BSD 3 Clause) for distance based listing sorting

Every third party package used in this project is listed above with its source and license. This list will be kept up to date as the project grows.

## Originality and AI use disclosure

Souq Skills is an original idea developed by this team. It is not a copy of an existing application, tutorial project, or another team's work, and no ready made project has been used or submitted as our own.

No application code has been written yet at this phase. This README and the Phase 1 proposal document were written with the assistance of AI, based on ideas and decisions made by the team. Any future use of AI during development, such as for learning, debugging, or small suggestions, will be disclosed here as it happens.

## Project status

Phase 1: Proposal and team plan. No code yet.
