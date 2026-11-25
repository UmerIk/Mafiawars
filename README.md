# Mafia Wars

A Flutter social deduction game with online rooms, LiveKit voice, text chat, friends, and local pass-the-phone play. This repository contains the client application; Firebase backend deployment sources are not included.

The current priority is implementing the new Figma UI. First, use this documentation to distinguish existing behavior, unfinished integrations, and release requirements.

## Documentation

- [Current project status](docs/PROJECT_STATUS.md): what exists, what is incomplete, priorities, and verification results.
- [Architecture and data](docs/ARCHITECTURE.md): modules, routes, rules, persistence, and service contracts.
- [Figma UI implementation plan](docs/UI_IMPLEMENTATION_PLAN.md): preparation, screen mapping, sequence, and acceptance checks.

Assessment date: **2026-11-25**. These documents describe inspected client code and local checks, not deployed Firebase/LiveKit health. Figma fidelity has not been assessed.

## Local development

1. Install Flutter with Dart compatible with `pubspec.yaml` and its dependencies. Flutter 3.44.8 / Dart 3.12.2 passed all 32 tests with `google_fonts` 6.3.3. This font dependency requires at least Flutter 3.35 / Dart 3.9; an exact Flutter version is not pinned.
2. Run `flutter pub get`.
3. Configure Firebase for the intended environment. Android configuration exists at `android/app/google-services.json` (another copy exists at the root); verify the intended project. No Apple `GoogleService-Info.plist` or generated `firebase_options.dart` is present. Startup calls `Firebase.initializeApp()` without explicit options.
4. For online features, enable anonymous Firebase Authentication, provide Firestore rules/indexes, and deploy or locate the `generateLiveKitToken` callable function. Its contract is documented in [Architecture](docs/ARCHITECTURE.md). Keep LiveKit signing credentials on the backend.
5. Android specifies compile SDK 36 and minimum SDK 24. Install the corresponding Android toolchain. Apple targets require Xcode/CocoaPods, Firebase configuration, and microphone permissions. Existing local Podfiles/config changes require their own review.
6. Run `flutter devices`, then `flutter run -d <device-id>`.

There is no environment/flavor switch or Firebase emulator bootstrap in the app. Online calls use the configured Firebase project. Local in-person routes bypass the sign-in redirect, but startup still attempts Firebase initialization.

## Verification

```sh
flutter analyze --no-pub
flutter test --no-pub
```

Run `flutter pub get` first on a fresh checkout. Device builds and real multiplayer/voice testing are separate checks. Current results and limitations are recorded in [Project status](docs/PROJECT_STATUS.md).

## Repository layout

```text
lib/main.dart           Startup and provider scope
lib/core/               Theme tokens, shared widgets, router
lib/features/auth/      Anonymous authentication and profiles
lib/features/lobby/     Dashboard, room entry, invite sheet
lib/features/game/      Online room data, rules, controllers, gameplay UI
lib/features/audio/     LiveKit, narration scripts, audio/TTS playback
lib/features/social/    Friends, requests, direct messages, invites, presence
lib/features/in_person/ Local setup, role reveal, game and moderator modes
assets/images/          Logo, backgrounds, characters, avatars, unnamed assets
test/                   Unit and widget tests
Mafia Wars.fig          Local design archive; frame inventory still needed
```

Android, iOS, macOS, Windows, Linux, and web scaffolds exist. This does not establish that every platform builds or supports every integration. Release branding, signing, App Check, platform setup, and backend authorization still need verification.
