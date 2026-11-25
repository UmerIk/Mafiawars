<!-- Created by Hamza Ali on 2026-11-25. -->

# Current project status

Assessment date: **2026-11-25**. Based on source inspection and local checks. Deployed services, real-device behavior, and Figma fidelity are unverified.

## Where we are

This is an implemented Flutter client with substantial gameplay code and unfinished product integrations. It is ready for a scoped UI migration after establishing a compiling baseline, but production multiplayer readiness has not been demonstrated. Backend deployment sources and security rules are absent from this repository; they may exist elsewhere.

## What we have

| Area | Present in code | Limitation |
| --- | --- | --- |
| App | Riverpod, GoRouter, portrait layout, Firebase startup | Initialization failures permit startup without usable services |
| Authentication | Anonymous sign-in, profiles, sign-out | “Google” button signs in anonymously as `Agent47`; Apple disabled |
| Rooms | Create/join, slots, readiness, host transfer, start/leave/rematch | Concurrency and authorization need hardening |
| Gameplay | Five roles, night actions, discussion, voting, victory/results | Host device advances phases; hidden-role trust needs validation |
| Voice | LiveKit connection, mute, active speakers, test screen | External token function required; speakerphone action is boolean only |
| Narration | Phase scripts, TTS, optional file/URL playback | No ElevenLabs API; no cache writer; local digital narration helper unused |
| Social | Friend requests, accept/remove, search, direct text chat, invites/presence writes | Search bound suspect; presence incomplete; messages unbounded |
| Incoming invites | Firestore records/listener | Sheet shows sample data; Join shows snackbar; Decline only closes it |
| Dashboard | Styled lobby, avatar list, stats display | Fixed/sample content and fallback stats; no result-based stats update found |
| In-person | Two modes, config, pass-reveal, local persistence | Configured roles ignored, night actions lost, duplicate names allowed |
| Design | Shared theme/widgets, images, `Mafia Wars.fig` | Frame/state inventory and visual comparison pending |
| Tests | 14 files for selected entities, controllers, rules, widgets, audio basics | No backend security/concurrency or full multiplayer end-to-end coverage |
| Platforms | Mobile, desktop, web scaffolds | Working builds/support not established |

## What we need

### First: establish the UI baseline

1. The `google_fonts` constant-map compilation failure was resolved by upgrading to 6.3.3. All 32 tests passed on Flutter 3.44.8 / Dart 3.12.2. The separate local `CardThemeData` edit remains preserved.
2. Select and record a supported Flutter version, then rerun analysis/tests. Dart `^3.5.4` does not pin Flutter.
3. Declare `path_provider` directly if the narrator retains its import.
4. Inventory Figma frames/states and map them to existing routes/components.
5. Identify which displayed metrics/actions will be real, deferred, or disabled. New layouts should not silently promise unfinished behavior.

### Next: correctness in affected flows

- Honor configured local roles; reject duplicate names or introduce stable player IDs.
- Preserve local night actions until resolution; test a full night through the notifier.
- Move assistant eliminate/revive operations into validated, persisted notifier methods.
- Connect invitations to real records and implement join/decline/consumption.
- Confirm special victory rules and Snitch abilities.
- Correct/test prefix search and implement reliable game-result statistics.

### Before online release

- Locate or implement the backend repository, token function, Firestore rules, and indexes. Missing source here does not establish missing deployment.
- Enforce membership, identity, role/phase eligibility, alive status, secret-role access, channel access, and host operations at a trusted boundary.
- Reconcile all-role client reads with secrecy; use trusted resolution where required.
- Make room capacity/slots and phase advancement atomic and retry-safe; enforce code uniqueness.
- Handle host loss/reconnect, device clocks, room cleanup, and stale rematch role/team data.
- Add integration/emulator tests for denied access, concurrent joins, duplicate advancement, private data, and rematches.

### Before platform release

- Verify Firebase per target; Apple plist and explicit web Firebase options are absent.
- Add appropriate Apple microphone setup; `ios/Runner/Info.plist` lacks a microphone purpose string.
- Replace debug App Check providers and verify backend enforcement.
- Replace Android debug release signing and template application names.
- Complete FCM setup, token refresh, delivery handlers, and invitation lifecycle. Obtaining a token does not establish working push delivery.
- Test device audio routing, disconnect/reconnect state, eliminated-player voice permissions, cleanup, and visible connection errors.
- Address swallowed errors, unbounded chats, friend-list per-user reads, and logging of role/action details.
- Add CI and platform build checks; none are present.

Release work need not all block visual implementation, but must remain explicit follow-up work.

## Verification baseline

Follow-up on 2026-11-25: `flutter test --no-pub --reporter expanded` passed all 32 tests after updating `google_fonts` to 6.3.3 on Flutter 3.44.8 / Dart 3.12.2. The table below records the earlier assessment, before this dependency fix.

`flutter build apk --debug --no-pub` also passed after aligning `flutter_webrtc` and its consumer `livekit_client` with the app's compile SDK 36 in `android/build.gradle`. The older plugins pin incompatible Android API levels. Kotlin Gradle Plugin migration warnings and Java deprecation warnings remain; built-in Kotlin migration requires coordinated plugin updates. The APK was built but not tested on a device.

Executed on 2026-11-25 with the installed toolchain (Dart 3.12.2). Checks were refreshed after a separate local theme edit appeared during review; this task made no implementation changes.

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Nonzero exit: 74 warning/info findings, no analysis errors after the separate theme edit; includes deprecations, unused code, undeclared direct import, search escape, and protected notifier-state access |
| `flutter test --no-pub --reporter expanded` | 31 tests passed; `test/widget_test.dart` failed to load because `google_fonts` 6.3.0 fails constant evaluation with the installed SDK's `FontWeight` type |
| `git diff --check` | Passed |
| Platform builds / real-device flows | Not run |
| Firebase rules / callable / LiveKit | Not verified; backend sources absent |
| Figma comparison | Not performed; archive/assets identified only |

Tests include controller fakes, serialization, role allocation, selected phase/victory cases, local config/state, unread badge animation, app/WebRTC smoke checks, audio initial/disconnect state, and narration script generation. `narrator_player_service_test.dart` tests script generation rather than playback. Local tests do not exercise a full notifier night-action lifecycle.

## Documentation change scope

Only the root README and `docs/` were authored for this task. Existing local changes in Apple Flutter configs, Podfiles, and `pubspec.lock` predate this work. A separate edit to `lib/core/theme/app_theme.dart` appeared during review and was left untouched. This documentation task did not change application code, dependencies, database state, or deployment configuration.
