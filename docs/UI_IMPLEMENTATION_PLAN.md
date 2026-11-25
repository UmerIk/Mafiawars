<!-- Created by Hamza Ali on 2026-11-25. -->

# Figma UI implementation plan

Prepared on 2026-11-25 from current code. This is a proposed migration sequence, not a completed design audit. `Mafia Wars.fig` is present; frame inventory and visual comparison remain pending.

## Approach

Keep feature boundaries, repositories, models, routes, and rules while migrating presentation incrementally. Update shared tokens/components first. A full rewrite increases risk because streams, timers, narration, and chat subscriptions already interact across screens.

The visual migration should not require a database migration unless an approved design feature needs new data. Record missing behavior explicitly, particularly provider sign-in, invitations, dashboard metrics, and voice state.

## Preparation

1. Use the verified test baseline: Flutter 3.44.8 / Dart 3.12.2 with `google_fonts` 6.3.3 passed all 32 tests. The separate local `CardThemeData` edit removes the earlier theme API error. Rerun analysis and platform builds as changes proceed.
2. Open/import the local archive in Figma or use the relevant Figma file/frames. Inventory frame names, sizes, variants, transitions, and overlays. Do not infer specifications solely from existing images.
3. Map fonts, colors, spacing, radii, shadows, icons, and imagery to `core/theme/` and `core/widgets/`. Bundle fonts if dependable offline rendering is required.
4. Create an asset manifest with meaningful names. Review extensionless files before using/renaming them; preserve references.
5. Record each screen's data source/actions and loading, empty, error, disabled, offline, and partial-data states.

## Screen mapping and implementation order

| Order | Area | Existing implementation | Behavior to preserve or clarify |
| --- | --- | --- | --- |
| 1 | Foundations | `core/theme/`, `core/widgets/` | Tokens, button/input states, contrast, semantics, text scaling |
| 2 | Splash/sign-in/profile | `features/auth/presentation/` | Routing, loading/errors, name/avatar edits; clarify real provider sign-in |
| 3 | Home/room entry/invites | `features/lobby/presentation/` | Create/join errors, disabled actions, sample-data replacement scope |
| 4 | Friends/search/direct chat | `features/social/presentation/` | Streams, requests, search feedback, empty chats, send failures |
| 5 | Room lobby/gameplay | `features/game/presentation/` | Readiness/start, role privacy, phases/timers, targeting/votes, chat eligibility |
| 6 | Overlays/results | Game widgets, dialogs, drawer | Narration, unread count, audio states, profiles, leave/rematch |
| 7 | In-person | `features/in_person/presentation/` | Setup, reveal privacy, phase controls, resume, assistant actions |
| 8 | Diagnostics/platform polish | WebRTC screen/platform runners | Diagnostic visibility, keyboard/safe areas, permissions, branding |

For existing routes absent from Figma, explicitly decide whether to retain the current UI, add a design, or retire them in a separately approved scope.

## Implementation boundaries

- Use Riverpod for new state; move touched `setState()` behavior into focused providers/controllers where appropriate.
- Extract repeated dashboard sections, player tiles, message rows, and dialogs. Use stable model IDs for dynamic-list keys.
- Keep Firebase calls in repositories/services; move touched lobby networking out of widgets where practical.
- Keep secret-role and chat eligibility rules independent of styling. Visual hiding is not backend authorization.
- Give timers, subscriptions, controllers, narration, and voice sessions explicit lifecycle ownership; prevent duplicate subscriptions on rebuild.
- Preserve persistence formats/interfaces unless a separate change is needed; test the affected full flow after each screen group.

## Acceptance checks

Compare rendered device screenshots with selected Figma frames at matching dimensions. Check small/larger phones, safe areas, keyboard overlap, long names/messages, text scaling, contrast, accessibility labels, touch targets, and focus.

Use repository/provider fakes for deterministic widget tests of meaningful behavior. Add targeted golden tests after fonts/assets are deterministic. Run analysis/relevant tests, then mobile builds when platform setup is available.

Exercise sign-in/profile; create/join/leave; ready/start; a full night/day vote; elimination/chat eligibility; results/rematch; friends/direct chat; actual invite handling; microphone permission/connect/mute/reconnect; and local setup/reveal/resume. Online flows require multiple devices or suitable integration tooling and a verified backend environment.

Track functional completion separately from visual fidelity: matching screenshots do not demonstrate working authentication, invitations, voice, or secure multiplayer.
