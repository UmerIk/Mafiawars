<!-- Created by Hamza Ali on 2026-11-25. -->

# Architecture and data

Reviewed against the current client on 2026-11-25. Source code is authoritative if this document becomes stale.

## Startup and data flow

`lib/main.dart` initializes Flutter, locks portrait orientation, attempts Firebase initialization, activates debug App Check providers, and creates a Riverpod `ProviderScope` around `MafiaApp`. Initialization failures are logged and the app still starts; online services may remain unavailable.

```text
Screen → Riverpod controller/provider → repository interface
       → Firebase implementation → Auth/Firestore
Firestore snapshots → stream provider → screen

Game repository → RoleAllocator / GameStateMachine → Firestore batch
InPersonGameNotifier → shared rules → local state → SharedPreferences
Game screen → audio providers → callable function → LiveKit
Phase change → narration script → cached file / URL / device TTS
```

Auth, game, and social generally separate `domain`, `data`, and `presentation`. Audio uses services directly; lobby is presentation only. Riverpod supplies repositories, `StateNotifier` controllers using `AsyncValue`, and stream providers. Several screens also use `setState()`, and the lobby writes Firestore directly. These are current deviations from the engineering standard, not recommended patterns for new work.

| Area | Responsibilities and entry points |
| --- | --- |
| Core | `core/router/app_router.dart`, `core/theme/`, `core/widgets/` |
| Auth | `AuthRepositoryImpl`, `AuthController`, user entity/model, splash/sign-in/profile UI |
| Lobby | Dashboard, room entry, FCM token registration, incoming-invite listener |
| Game | `GameRepositoryImpl`, `GameController`, room/player/role/chat models, `RoleAllocator`, `GameStateMachine`, gameplay widgets |
| Audio | `LiveKitAudioService`, `ElevenLabsModeratorService`, `NarratorPlayerService`, diagnostic screen |
| Social | `SocialRepositoryImpl`, friend/request streams, search, direct messages, invites, presence |
| In person | `InPersonGameNotifier`, configuration/state entities, persistence service, setup/reveal/game screens |

At review time, the gameplay screen is about 1,444 lines and the lobby 981 lines. Both mix layout and orchestration; extract focused widgets/controllers as those screens are migrated.

## Navigation

`GoRouter` starts at `/splash`. Redirects use Firebase authentication; `/splash` and `/in_person...` bypass the guard. If Firebase is unavailable, the redirect returns without enforcement. Route guards do not replace backend authorization.

| Route | Purpose |
| --- | --- |
| `/splash` | Startup animation and next-screen selection |
| `/` | Sign-in UI; enabled action currently signs in anonymously |
| `/profile_setup` | Name and avatar selection |
| `/lobby` | Dashboard and room entry |
| `/social` | Friends, requests, search |
| `/new_chat` | Direct-chat entry |
| `/social/chat/:friendUid` | Friend chat; optional `name` query parameter |
| `/game/:gameId` | Online room lobby, gameplay, results/rematch |
| `/webrtc_test` | Manual voice connection diagnostic |
| `/in_person` | Local mode selection |
| `/in_person/config` | Configuration; mode in `state.extra`, default full digital |
| `/in_person/pass_reveal` | Pass-the-phone role reveal |
| `/in_person/digital_game` | Local digital game |
| `/in_person/assistant_game` | Human moderator assistant |

## Online lifecycle and rules

Room creation writes the room and host player in a batch. Codes contain six uppercase letters/digits from an alphabet excluding ambiguous characters; uniqueness is not checked. Joining queries a lobby by code, reads players, finds a free slot, then writes membership and increments the count. Capacity/slot checks are not transactional.

Default capacity is 12; start requires at least five players and checks host identity. Repository start logic does not enforce that every player is ready. Roles are assigned on the client and written to private-role documents.

| Players | Automatic allocation |
| --- | --- |
| 5 | 1 Mafia, 1 Doctor, 1 Detective, 2 Civilians |
| 6–8 | 2 Mafia, 1 Doctor, 1 Detective, remaining Civilians |
| 9+ | 3 Mafia, 1 Snitch, 1 Doctor, 1 Detective, remaining Civilians |

The allocator accepts smaller nonempty lists, although normal start requires five. Snitch counts as Mafia for victory but investigates as a civilian. The game UI checks the Mafia role specifically for Mafia night actions/chat.

Phases cycle through `nightMafia → nightDoctor → nightDetective → dayDiscussion → dayVoting → nightMafia`, ending at `gameOver`. Night phases each last 20 seconds, discussion four minutes, and voting 45 seconds. The host's game-screen timer advances expired phases; no server scheduler is included. Unanimous ready-to-vote state can move discussion to voting early.

Night resolution accepts one distinct Mafia target among submitted choices; disagreement yields no kill unless the legacy `nightMafia` action is present. This does not prove every living Mafia submitted. A matching Doctor target prevents the kill. Detective success means Mafia, excluding Snitch. A summary is published in `nightFacts`. Day voting eliminates the unique highest-voted living target; ties eliminate nobody.

`GameStateMachine.checkVictory` contains project-specific rules:

- No surviving Mafia/Snitch means Town wins.
- Mafia/Snitch at parity or majority means Mafia wins.
- One Mafia/Snitch and two Town wins for Mafia when Doctor is absent; play continues when Doctor is present.
- One Doctor and one Mafia/Snitch means Mafia wins.

Confirm these before changing gameplay. Rematch clears actions/votes and resets room/player state, but does not clear all role/team/chat documents. Room deletion does not recursively remove subcollections.

## Firestore contract inferred from code

This describes client reads/writes, not an approved security schema. Rules and index deployment files are absent.

| Path | Data / behavior |
| --- | --- |
| `users/{uid}` | Name, avatar URL, creation time, `gamesPlayed`, `wins`, presence `status`; lobby merges `fcmToken`; presence updates merge `lastActive` |
| `users/{uid}/friends/{friendUid}` | Denormalized friend profile and `addedAt`; accept/remove writes both users in a batch |
| `users/{uid}/friend_requests/{senderUid}` | Sender profile, receiver, pending status, creation time; accept/reject deletes request |
| `users/{uid}/game_invites/{id}` | Sender, room ID/code, server timestamp, pending status |
| `rooms/{roomId}` | Code, host, status/phase/deadline, capacity/count, alive/eliminated IDs, ready-to-vote IDs, winner, night facts, creation time |
| `rooms/{roomId}/public_players/{uid}` | Profile, slot, host/ready/alive flags, elimination type, joined time |
| `rooms/{roomId}/private_roles/{uid}` | User ID, secret role, faction |
| `rooms/{roomId}/mafia_team/{uid}` | Mafia user ID/name/avatar |
| `rooms/{roomId}/actions/{actionKey}` | Actor, target, server timestamp; Mafia key `nightMafia_{uid}`, other keys use phase name |
| `rooms/{roomId}/votes/{uid}` | Voter, target, server timestamp |
| `rooms/{roomId}/{public_chat,mafia_chat,ghost_chat}/{messageId}` | Channel messages |
| `direct_chats/{chatId}/messages/{messageId}` | Direct messages; chat ID joins lexically sorted user IDs with `_` |

Chat payloads contain `id`, sender ID/name/avatar, message, channel type, and ISO-8601 string `timestamp`. Streams order timestamp ascending. Room/profile models use Firestore `Timestamp` values. Preserve these format differences until a deliberate migration. Message streams have no pagination/limit. `sendDirectMessage` accepts `audioUrl` but does not persist it.

Queries include room code plus lobby status, pending requests/invites, display-name prefix search limited to ten results, and ordered messages. Verify indexes in the intended Firebase environment. Search currently uses a suspicious upper-bound literal `'$trimmed\zf8ff'`; test and correct its behavior.

Phase resolution reads every private role on the client. A production trust model must resolve how authorized resolution accesses secrets without exposing other players' roles. UI-only role/phase/channel checks cannot prevent forged writes or secret reads.

## Audio and narration

`LiveKitAudioService.joinRoomAudio(roomId)` uses the default Firebase Functions instance:

```text
Callable: generateLiveKitToken
Request:  { roomId: string }
Response: { token: string, url: string }
```

The backend must authenticate users, verify membership, assign appropriate LiveKit identities/grants, and retain signing secrets. Source, deployment configuration, and an explicit Functions region are absent; deployed behavior is unverified.

The client requests microphone permission, connects/publishes audio, and exposes mute/connection/active-speaker streams. Speakerphone controls only change a boolean. Room listeners update active speakers but do not explicitly synchronize unexpected disconnections into connection state. Reconnect, routing, and cleanup need device testing.

Despite its name, `ElevenLabsModeratorService` returns local narration text and makes no ElevenLabs request. Playback tries an existing cached MP3, then a supplied URL, then device TTS. Generated scripts have no audio URL; no cache download/write is implemented. The narrator imports `path_provider` without declaring it directly in `pubspec.yaml`.

## In-person persistence and limitations

Configuration contains names, role counts/toggles, discussion/voting timing, and reveal preference. `InPersonGameNotifier` owns state and uses the shared allocator/state machine. Full JSON state, including secret roles, is stored unencrypted in SharedPreferences under `active_in_person_game`; it is convenience storage, not secure storage.

- New-game validation checks custom configuration, but allocation uses only player names and ignores the chosen role mix.
- Names are map keys; duplicate names are allowed and can overwrite roles.
- Every phase advance clears night actions, losing earlier actions before night resolution.
- Assistant eliminate/revive operations write notifier `.state` directly, bypassing persistence methods.
- Saves are asynchronous and not awaited by notifier calls; failures are logged without user feedback.
- The digital screen's narration helper is unused.

## UI foundations and testing seams

`core/theme/` centralizes colors, Cinzel/Inter typography through Google Fonts, spacing, radii, shadows, and the Material theme. Shared widgets include buttons, cards, badges, text fields, and `mafia_ui.dart` decoration. Hardcoded screen styles coexist with these tokens.

Repository interfaces and Riverpod overrides provide test seams. Controller tests use fakes; entity/rule tests cover selected behavior, with injectable randomness in allocation. They do not verify backend authorization, concurrent room behavior, local notifier lifecycle, or real voice connectivity. See [Project status](PROJECT_STATUS.md) and [UI plan](UI_IMPLEMENTATION_PLAN.md).
