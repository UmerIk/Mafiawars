<!-- Created by Hamza Ali on 2026-11-25. -->

# Shared UI implementation

The first-row implementation covers splash, Login A, profile creation/editing, dashboard, Agent Network, relationship dialogs, and the incoming-invitation sheet. The second row now covers Messages, New Chat, direct chat, host/player lobbies, and Agent Briefing. The third row adds the shared night-action/sunrise screen. The fourth row covers discussion, voting, final decision and eliminated-player states; the separate match-completion screen retains its existing presentation; game-room invites use the shared Invite Friends dialog. Components were inspected through Chrome because the connected Figma API account could not read the file. This is not a completed automated pixel-diff certification.

## Foundations

Use `lib/core/widgets/design/design_components.dart` as the shared component import. Existing legacy theme tokens remain available to screens outside this migration.

| Source | Responsibility |
| --- | --- |
| `core/design/app_assets.dart` | Canonical artwork paths, avatar IDs, atlas labels and display order |
| `core/theme/app_colors.dart` | Existing palette plus named Figma swatches |
| `core/theme/app_gradients.dart` | Button, translucent burgundy, neon stroke, profile, rim-light and splash fills |
| `core/theme/app_effects.dart` | Button elevation, glow and field inset shading |
| `core/theme/app_typography.dart` | Bundled Inter styles for migrated UI; legacy Google Fonts styles remain |

`assets/fonts/Inter.ttf` is the official Inter variable font, bundled with its OFL license. The login character composition and dashboard join/create/in-person images were exported from Figma. Existing image filenames are unreliable: for example, `avatars_grid.png` contains room artwork. Always use `AppAssets` rather than inferring contents from filenames.

## Components

| Component | Configuration / behavior |
| --- | --- |
| `AppButton` | Primary, secondary, outlined, danger, success, disabled/loading, compact, leading/trailing content |
| `AppTextField` | Label, error, prefix/suffix, keyboard action, formatters, autofill |
| `AppSurface` | Independent gradient stroke, translucent fill, radius, shadow and optional tap |
| `AppIconButton` | Shared floating button appearance and accessible tooltip |
| `AgentAvatar` | Original 5×5 avatar atlas, existing asset paths, HTTPS image values, online/selected state and fallback |
| `ProfileHeader` | Avatar, name, optional subtitle, edit action |
| `AgentNetworkRow` | Profile action, optional subtitle/presence, configurable action button |
| `AppSegmentedControl` | Selection controlled by the caller; optional icons |
| `InviteFriendsDialog` | Searchable friend list, per-friend busy/sent states, retry; uses the existing invitation method |
| `AppSheet` | Safe-area-aware, height-constrained bottom-sheet shell |
| `AgentChip` | Target/vote selection, enabled state, voter avatars |
| `AgentRoleCard` | Artwork, title, role color, mission/victory text, supplied teammate widgets |
| `AgentBriefingCard` | Caller-controlled secret-role reveal and role counts |
| `AppFloatingControls` | Wrapping floating-action tray |
| `MafiaPage` | Artwork background, system/keyboard insets, scrollable content, phone-width limit on tablets |

Role cards, briefing cards and selection chips are shared presentation primitives; they do not change online game behavior. Backend eligibility, timers and role data remain owned by the existing features.

## Profile flow

Sign-in continues using the existing anonymous-authentication method. The Google label is retained from the design; this change does not implement Google OAuth or Apple sign-in. Apple remains disabled.

After sign-in, `/profile_setup` asks for a name and avatar, then calls the existing `AuthController.updateProfile`. Empty names and names longer than 30 characters are rejected. A failed save keeps the draft and permits retry. The dashboard edit action opens `/profile_setup?edit=true` with the current user and returns after saving. No new Firestore field or repository method was introduced.

`profileSetupPendingProvider` prevents authentication redirects from skipping setup during sign-in. On restart, existing `avatar_N` values and custom names identify completed profiles; generated `Agent_...`, `Agent47`, and `Agent` defaults without a saved avatar are sent to setup. This is a compatibility heuristic using existing fields, not a backend completion flag.

## Data boundaries and known limitations

- Friend/request/profile UI uses existing repository streams/actions. Search has a cancellable debounce and ignores stale results; the repository's existing prefix-query behavior is unchanged.
- Dashboard friend previews use live friends. There are no invented streaks or per-role win totals; unknown dialog metrics use an em dash.
- Invitations display actual records and join using the existing room-code method. Decline is a local dismissal only: there is no backend decline/consume endpoint. Reopening can show the invitation again.
- The dashboard message shortcut opens `/chats`; the compose action opens `/new_chat`.
- Backend repositories, game rules, database models and security configuration were not changed.
- The live Figma UI/UX and Components pages were rechecked in Chrome for row two. Exact numeric verification of every effect and custom icon remains outstanding; shared styling centralizes subsequent corrections.

## Verification

`test/features/ui/first_row_ui_test.dart` covers 320-, 440- and 800-pixel layouts, larger text/keyboard insets, profile validation, save failure/retry, editing, pending setup routing and repeat-save prevention. It uses repository fakes and does not contact Firebase. Run:

```sh
flutter test --no-pub
flutter test --no-pub --dart-define=UI_PREVIEWS=true test/features/ui/first_row_ui_test.dart
```

The second command writes local review screenshots to `/tmp/mafia-first-row-previews`. Android debug APK compilation has been verified. Real-device behavior and deployed Firebase/voice integrations require separate verification. The first-row checkpoint passed 57 tests. After row two, the full suite passes 69 tests; analysis reports 52 existing legacy findings and no errors.


## Second row

Fresh Chrome references on 2026-11-25: file `T9Dqxoc5WduuS1vXwiZ87A`, UI/UX page, Chats List `48:959`, Chat screen `51:1995`, Admin Lobby `51:2154`, Agent Briefing game `133:1126`, and briefing card `197:764`. The frames use 440×956 layouts, 30-pixel margins, three-column room grids, and shared translucent surfaces.

- `PageHeader` and `AsyncFeedback` provide shared navigation and loading/error recovery layouts.
- `ChatContactRow`, `DirectMessageBubble`, and `ChatDateDivider` share friend identity, message colors, real timestamps and date grouping. No read receipts are invented because the message model has no receipt data.
- `RoomPlayerTile`/`RoomPlayersGrid` share avatar, host, own-player highlight, readiness, speaking and empty-slot presentation. Empty slots follow `slotIndex`; names truncate within accessible text scaling. Grids scroll on shorter phones; primary actions remain visible.
- `RoomCodePanel`, `RoomLobbyView`, and `RoomBriefingView` compose these widgets without altering game repositories. Host start retains the existing five-agent minimum; readiness, invites, copy, leave and chat call existing actions. Loading/error/busy states prevent accidental duplicate UI requests.
- `AppGradients.agentHighlight` and `briefing` centralize new fills. Avatars are clipped to circles; a zero-width `AppSurface` stroke now draws no border.

### Chat data and lifecycle

`chat_providers.dart` wraps the existing per-friend message/user streams in auto-disposed providers. The inbox derives its rows from current friends and their most recent stored message, orders by timestamp and stable ID, supports search, and offers retry for partially failed streams. Riverpod releases message subscriptions when dependencies or screens disappear.

There is no backend conversation-index endpoint. This compatibility implementation subscribes to existing histories for current friends while the inbox is visible; removed-friend conversations are not discoverable here and histories remain unbounded under the existing API. A scalable conversation index/pagination is future backend work.

New Chat searches actual friend records, replacing hardcoded sample IDs. The direct-chat composer rejects blank/repeat submissions, retains failed drafts, preserves edits made while a send is pending, and clears only a successfully sent draft. The list opens at recent messages while short conversations align with the top of the design. Errors leave retry available; Firestore may serve cached data using its existing behavior, but the UI does not claim a verified online/offline status.

### Briefing without changing game rules

The backend starts directly in `nightMafia`; it has no briefing phase. The new briefing is a local, dismissible view during that phase. It shows the actual server phase deadline, provides **Continue to game**, and automatically yields to the next existing phase. It never adds ten seconds, delays actions on the backend, or changes phase advancement. Dismissal lasts for this screen visit and resets when the room returns to its lobby.

The secret-role action opens the shared flip card. It listens only to the existing own-role stream. Aggregate counts reuse the existing role allocator with synthetic IDs, so no other player's role is fetched or inferred. The card hides immediately on flip/close. No teammate identities are displayed because the current presentation API does not supply an authorized team stream. Role allocation, victory conditions, private chat eligibility, narration and phase actions remain unchanged.

Microphone, speaker and leave controls delegate to the current audio service; disconnected/dead-player microphone controls are disabled. The existing service's hardware audio-routing limitations remain. In-game channel chat retains its current drawer; its independent visual migration remains a follow-up.

### Second-row verification

`test/features/ui/second_row_ui_test.dart` exercises responsive layouts at 320×640, 440×956 and 800×1024, larger text/keyboard insets, search with real IDs, draft recovery, duplicate sends, host minimum/start/readiness, role privacy, actual countdown display, live inbox ordering, partial errors and subscription cleanup.

```sh
flutter test --no-pub --dart-define=UI_PREVIEWS=true test/features/ui/second_row_ui_test.dart
```

This writes local review images to `/tmp/mafia-second-row-previews`. Screenshots were visually compared against the current Chrome frames. Exact custom-icon matching and automated pixel-diff certification remain unverified. Real multiplayer/Firebase and hardware audio checks require devices and the deployed services.


## Third row: one gameplay screen with multiple states

Chrome UI/UX references rechecked on 2026-11-25: Secret Attack `155:2399`, Agent Protection `164:2731`, and Sunrise Briefing `167:3741`, with adjacent attack/disagreement, investigation and sunrise variants. These are states of the same screen rather than independent routes.

`NightGameView` composes `GamePhaseHeader`, `PhaseActionPanel`, configurable `AgentChip` targets, `SunriseOutcomeCard`, and the existing player grid. `GameFloatingControls` is shared with the initial Agent Briefing. `RoomRoleSheet` now lives in a separate file to keep shared controls independent of the briefing screen. Original avatar assets remain in use. Phase gradients live in `AppGradients`; selected markers and result symbols follow the design's knife/medical/search notation. These four missing symbols are bundled as PNGs from the official [Twemoji repository](https://github.com/twitter/twemoji) so they work without an emoji font or network request. Graphics are by Twitter, Inc. and other contributors under CC BY 4.0; attribution and the full license are bundled in `assets/licenses/`.

Night actions use a Riverpod controller scoped by room, phase and deadline. The UI preserves the existing eligibility: Mafia acts during `nightMafia`, Doctor during `nightDoctor`, Detective during `nightDetective`; eliminated agents cannot act, dead targets are excluded, and only Doctor can select themselves. Failed writes expose retry and preserve the previous selection; pending writes cannot be duplicated. Targets disable at timer expiry. Actions go through the unchanged `GameRepository.submitPhaseAction` contract. Existing all-role reads are not used by the new UI; an investigation acknowledges submission without inventing a private investigation result.

Mafia selections from the existing actions stream are displayed only to a Mafia player during that phase. Divergent submitted targets show a coordination message. The UI does not claim that every living Mafia player has submitted: the current resolver counts submitted distinct targets, and backend enforcement remains unchanged.

The backend has no sunrise phase. On entry to `dayDiscussion`, a local sunrise panel displays the existing published results and actual discussion deadline. **Continue to discussion** returns to the existing discussion/voting presentation; no countdown is added or paused. The backend supplies only `nightFacts.summary`, so known legacy templates are mapped to the saved-agent/killed-agent cards. Missing or unrecognized summaries stay as plain text instead of showing invented successes, victims, or privileged identities. A separate structured result payload would require future backend work.

Narration still runs through the existing phase listener; available script text is shown inside the action panel. Host manual advance remains in the phase header's **Host controls** menu. Shared microphone/speaker/leave/role/chat controls retain their service contracts, and elimination mutes the existing audio session. Hardware routing limitations remain in the audio service.

`test/features/ui/third_row_ui_test.dart` covers all six design variants at 320, 440 and 800 pixels, larger text and panel scrolling, action failure/retry/busy states, role/alive/self eligibility, timer expiry, host advance, missing/loading/error data, sunrise parsing, dismissal callbacks and phase-scoped state cleanup. Preview command:

```sh
flutter test --no-pub --dart-define=UI_PREVIEWS=true test/features/ui/third_row_ui_test.dart
```

Review images are written to `/tmp/mafia-third-row-previews`. The third-row checkpoint passed 81 tests. Static analysis has no errors and retains 52 legacy findings. Android debug APK compilation passes, with existing Kotlin migration warnings. Automated pixel-diff certification, real multiplayer and device audio remain unverified.


## Fourth row: discussion, final vote, decision and eliminated agents

The current Chrome references were rechecked on 2026-11-25: the final-vote selection frame `167:3180`, adjacent discussion/decision variants, and the eliminated-player frame `133:1036`. `DayGameView` handles all five variants with the same phase header, action panel, agent chips, private-role sheet and audio/chat controls as earlier rows.

`DayPlayersBoard` separates living agents from the eliminated roster, keeps slot order stable, shows current speakers, and scrolls on short screens or larger text. `PlayerStateAvatar` preserves the player's dynamic identity in grayscale and applies the original Figma blood or jail overlay according to `eliminationType`. Those two transparent PNGs were exported from their individual layers in Chrome at 4× and are catalogued as `AppAssets.eliminationBlood`/`eliminationJail`. The killed-player layer was `Crimson Blood Splatter Overlay 1`; the jailed layer was `image 5`. No composite screen screenshot is used as UI.

`AppGradients.discussion`, `finalVote` and `eliminatedVignette` centralize phase fills and the full-screen eliminated-player effect. `MafiaPage.backgroundOverlay` allows that effect without intercepting input. The shared player tile shows distinct `KILLED`/`ELIMINATED` labels and highlights only living local players. The eliminated player's microphone is disabled, readiness is unavailable, and the existing chat eligibility remains owned by the current drawer/repository.

### Actions and decision data

Readiness calls `toggleReadyToVote`; votes call `submitDayVote`. Both use phase/deadline-scoped Riverpod state, retain prior successful selections on a failed replacement, offer retry, and prevent duplicate pending submissions. Vote targets exclude self and eliminated agents, voting disables at deadline, and eliminated agents see read-only vote states. Voter avatars use actual existing vote records. Host manual advance remains available in the header menu.

The backend has no `finalDecision` phase or persisted vote-result payload and deletes votes when resolving the voting phase. The UI therefore caches the last observed nonempty vote snapshot while voting and displays a dismissible decision only after observing a transition out of `dayVoting`. The eliminated identity comes from the newly published `eliminatedPlayerIds` delta, not a client tally prediction. If nobody was newly eliminated, the panel says so without assuming why. Missing totals/profiles receive explicit fallback text. The snapshot can be incomplete after reconnect or before all records arrive; a durable server result record would be needed for guaranteed historical totals and replay. A client joining after resolution cannot reconstruct deleted votes and does not invent a decision history.

**Continue to game** stays visible outside the scrollable decision panel. The actual next-phase countdown continues throughout; no backend phase or timer is delayed. A return to the lobby or a new voting phase clears the local decision state. Match completion/rematch retains its existing result screen after decision dismissal.

### Verification

`test/features/ui/fourth_row_ui_test.dart` adds 13 checks covering the five variants at 320×640, 440×956 and 800×1024, larger text/scrolling, readiness retry, vote failure/retry/busy state, expired/self/dead restrictions, eliminated audio controls, observed transition decisions, absent totals, stream errors, and disposal during a pending write.

```sh
flutter test --no-pub --dart-define=UI_PREVIEWS=true test/features/ui/fourth_row_ui_test.dart
```

Review screenshots are written to `/tmp/mafia-fourth-row-previews`. The complete suite passes 94 tests. Analysis reports no errors and 52 existing legacy findings. Android debug APK compilation is verified; existing Kotlin migration warnings remain. Exact pixel-diff certification, deployed multiplayer/security and device audio routing remain unverified.
