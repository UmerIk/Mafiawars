<!-- Created by Hamza Ali on 2026-11-25. -->

# Shared UI and first-row implementation

The first-row implementation covers splash, Login A, profile creation/editing, dashboard, Agent Network, relationship dialogs, and the incoming-invitation sheet. Other rows retain their existing presentation; the existing game-room invite action opens the shared first-row Invite Friends dialog. Components were inspected through Chrome because the connected Figma API account could not read the file. This is not a completed automated pixel-diff certification.

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

Role cards, briefing cards and selection chips are presentation primitives for later rows; they do not change online game behavior. Backend eligibility, timers and role data remain owned by the existing features.

## Profile flow

Sign-in continues using the existing anonymous-authentication method. The Google label is retained from the design; this change does not implement Google OAuth or Apple sign-in. Apple remains disabled.

After sign-in, `/profile_setup` asks for a name and avatar, then calls the existing `AuthController.updateProfile`. Empty names and names longer than 30 characters are rejected. A failed save keeps the draft and permits retry. The dashboard edit action opens `/profile_setup?edit=true` with the current user and returns after saving. No new Firestore field or repository method was introduced.

`profileSetupPendingProvider` prevents authentication redirects from skipping setup during sign-in. On restart, existing `avatar_N` values and custom names identify completed profiles; generated `Agent_...`, `Agent47`, and `Agent` defaults without a saved avatar are sent to setup. This is a compatibility heuristic using existing fields, not a backend completion flag.

## Data boundaries and known limitations

- Friend/request/profile UI uses existing repository streams/actions. Search has a cancellable debounce and ignores stale results; the repository's existing prefix-query behavior is unchanged.
- Dashboard friend previews use live friends. There are no invented streaks or per-role win totals; unknown dialog metrics use an em dash.
- Invitations display actual records and join using the existing room-code method. Decline is a local dismissal only: there is no backend decline/consume endpoint. Reopening can show the invitation again.
- The message shortcut retains access to the existing new-chat flow; the dedicated conversation inbox belongs to a later row.
- Backend repositories, game rules, database models and security configuration were not changed.
- Exact numeric verification of every Figma effect and icon export remains outstanding: further Chrome inspection was blocked when automatic approval review reached its usage limit. Shared styling centralizes any subsequent corrections.

## Verification

`test/features/ui/first_row_ui_test.dart` covers 320-, 440- and 800-pixel layouts, larger text/keyboard insets, profile validation, save failure/retry, editing, pending setup routing and repeat-save prevention. It uses repository fakes and does not contact Firebase. Run:

```sh
flutter test --no-pub
flutter test --no-pub --dart-define=UI_PREVIEWS=true test/features/ui/first_row_ui_test.dart
```

The second command writes local review screenshots to `/tmp/mafia-first-row-previews`. Android debug APK compilation has been verified. Real-device behavior and deployed Firebase/voice integrations require separate verification. The full suite passes 57 tests; analysis reports 60 existing legacy findings and no errors.
