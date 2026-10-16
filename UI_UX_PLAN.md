# Main Screen, Twin Mascots, and Planning Assistant

**Updated:** 14 October 2026

**Status:** UX proposal; the webapp has infrastructure and an unstyled framework placeholder only. Product UI/UX has not started. The user requested a 50/50 Calendar/AI screen, outward panel exits, twin mascots for hidden panels, and mascot-triggered conversation or reopening. The user confirmed that AI should first suggest quests, time blocks, and itinerary changes for review.

**Related contracts:** [Product plan](PRODUCT_PLAN.md), [technical design](TECHNICAL_DESIGN.md), [local sync](LOCAL_SYNC_DESIGN.md), and [agent guide](AGENTS.md).

**First-session detail:** [FIRST_SESSION_PLAN.md](FIRST_SESSION_PLAN.md) defines account/setup, editor, pending/synced completion, Undo, conflict/recovery copy and the acceptance journeys around this workspace. It preserves the existing email/password proposal and separates the first 20 XP from the later 100 XP room milestone.

## 1. Concrete experience

Open the main planning workspace and see **Calendar on the left, AI Planner on the right, at 50/50**. Choose Calendar: the planner slides out through the right edge, Calendar expands, and the planner's mascot appears at that right edge. Choose AI: Calendar slides out through the left edge, the planner expands, and Calendar's mascot appears at the left edge.

Tap the hidden panel's mascot for a small conversation-style popover: “Your calendar is tucked away. Open it?” Its primary Open Calendar/Open AI action restores the split view. A persistent Calendar / Both / AI control also provides direct navigation; mascots are a friendly shortcut, not the only way back.

This main workspace replaces the previous desktop calendar-plus-room composition. The evolving fantasy room remains a separate destination or compact progression detail; the AI panel is not a replacement room. Public manga reading keeps its own quiet layout.

## 2. Three layout states

| State | Calendar | AI Planner | Visible mascot |
| --- | --- | --- | --- |
| `split` — initial | Left 50% | Right 50% | Neither |
| `calendar_focus` | Full available workspace | Hidden beyond the right edge | Planner twin at the right edge |
| `assistant_focus` | Hidden beyond the left edge | Full available workspace | Calendar twin at the left edge |

| User action | Result |
| --- | --- |
| Focus Calendar from split | `calendar_focus`; planner exits right |
| Focus AI from split | `assistant_focus`; Calendar exits left |
| Both from either focus state | `split`; hidden panel returns from its own edge |
| Tap visible mascot | Open its conversation popover; no panel change yet |
| Open hidden panel from popover | `split`; both mascots disappear |
| Ask planner from its mascot | `assistant_focus`, with the existing composer focused |
| Dismiss mascot popover | Keep the current panel state |

Only one layout state is authoritative. Derive panel visibility and mascot visibility from it; do not maintain independent flags that can display the wrong twin. Initial workspace entry uses split; preserve the current state during same-workspace interactions. No cross-device layout preference or auto-focus based on AI messages is needed initially.

## 3. Touch, keyboard, and responsive behavior

The user's touch-to-focus intent needs an unambiguous activation area. Recommended refinement: a clearly labeled Focus Calendar/Focus AI header area, plus noninteractive panel background where practical. Taps on dates, quest controls, links, text fields, and buttons perform their normal actions; scrolling, text selection, dragging, and long presses never collapse a panel. Do not wrap an entire interactive panel inside a button or place a capturing overlay over it.

On wider screens, both halves can show useful content: the familiar calendar/date navigation and agenda on the left, a planning conversation/proposals on the right. The full calendar/editor is available in Calendar focus. Start with a proposed 768 px content breakpoint and test it, rather than equating screen labels with usability.

On a narrow phone, retain the requested left/right 50/50 **overview** at first, with low-density previews and large focus controls. Do not squeeze a functional month grid, editor, or chat form into half a phone. Focusing either half opens its usable full-width interface. When the software keyboard appears, keep the composer/editor full width and visible; preserve its draft if the user switches views. Zoom/large text may further simplify the overview without changing left/right ownership.

Use roughly 44 px effective mascot/focus targets as a design target, visible text labels, keyboard operation, and focus rings. Do not park mascots over bottom navigation, save buttons, editors, or the reader; reserve safe space near the relevant edge. Width/height changes and orientation changes must not trigger a new layout state.

Before hiding a focused panel, move focus to an appropriate persistent control or heading in the retained panel. Hidden panels and their children must leave keyboard/accessibility navigation; a translated offscreen panel is not sufficient. Restore to a logical visible control, never to a hidden or destroyed input. See [MDN inert](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert) and [W3C target sizing](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).

## 4. Twin mascots and conversation

Use a matching pair with distinct accessories and text labels: a calendar twin and a planner twin. Names, species, and final art remain open; prototypes can use simple static illustrations. Start with 2D artwork and shared Motion transitions. Two 3D mascots and always-running character renderers are not requirements.

A mascot exists as a control only while its assigned panel is hidden. A small greeting/open menu can be deterministic and clearly presented as a navigation helper; it must not call a language model on every tap or pretend to generate personalized advice. No automatic speech, looping demands for attention, or guilt-based prompts.

The planner twin may offer Ask planner, which opens the right panel's normal composer. The calendar twin primarily offers Open Calendar; a future contextual question can route through the same planning assistant after explicit user action. The twins are two entry points, not two independent AI agents, memory stores, or conflicting conversations.

Popover behavior: visible close action, Escape/outside dismissal, accessible labeling and focus return. Opening the hidden view closes the popover and removes that mascot. Rapid mode changes cannot leave an orphan popover or duplicate mascot. If a mascot asset fails, its labeled HTML control still works.

## 5. Planning assistant scope and review

The right panel first helps with three jobs: suggest a manageable quest, propose a time block, and propose a change to an itinerary's shared calendar entries. Suggested prompt chips might be Plan today, Find a time block, and Review this itinerary. Casual companion conversation, voice, autonomous scheduling, and general internet research are not part of this first assistant slice.

AI returns **proposals**, not executed mutations. Each proposal shows the title, target date/local time/IANA zone, duration where known, relevant existing entry, and before/after changes. Users can edit, accept, or dismiss it. Batch acceptance, deletion, completion, XP assignment, creator publication, and bookings remain outside initial AI actions.

An accepted proposal opens the existing editor prefilled; the user reviews and saves through the ordinary validated application operation and Dexie/outbox path. It is not saved merely because the model suggested it. For an existing entry, preserve the revision/context used to build the proposal and surface changes/conflicts before applying; never silently apply a stale plan to newer canonical data. Itinerary changes reference the same occurrence, not a second schedule.

The assistant receives only the context necessary for an explicit request: selected date window or selected itinerary with the user's awareness. Minimize private notes/booking references and exclude unrelated accounts, publication drafts, and reading history. Do not automatically transmit the full account, run a model when a panel opens, or log raw prompts/calendar contents. Treat model output as untrusted input and validate structured proposals; text alone cannot authorize execution.

State calendar context coverage, timezone, and pending-sync limitations. Missing external calendar data does not mean a proposed slot is free; uncached ranges do not mean an empty schedule. For the first AI integration, use acknowledged canonical context; if relevant local edits are pending, ask the user to sync or proceed without schedule-specific suggestions. Keep manual calendar editing available while AI is unavailable.

AI generation is an online server capability with verified account identity, server-only credentials, request limits, cancellation, and bounded context. No model/provider is selected in this UX plan. Before enabling it, define actual provider/data-handling terms, cost budget, structured response contract, and error handling. Do not add an AI subscription or credential merely to build the shell.

Initial conversation is session-scoped and account-isolated, preserved across panel switches but cleared on sign-out/account change; persistent chat history is a separate choice. Do not enqueue an offline model request that might run later unexpectedly. Display unavailable/needs-sign-in states honestly; deterministic open/help prompts remain usable without model access.

## 6. Motion and state ownership

Reuse Motion for React for coordinated panel exits/returns and expansion, with CSS for simple control feedback. Proposed transition duration: 220–300 ms, tuned on devices. Hide the inactive panel from interaction as the state changes; render the appropriate mascot after its exit settles. An interrupted transition resolves to the latest selected state, with no duplicate nodes or delayed reset.

Prefer transform/opacity for large moving surfaces and avoid animating a full calendar grid's individual cells. Do not mix CSS and Motion ownership of the same transform. Respect reduced motion with an immediate layout switch or short fade, retaining the same state/focus outcomes. See [Motion accessibility guidance](https://motion.dev/docs/react-accessibility).

Keep editor text, selected date, scroll anchor, assistant draft, conversation, and reviewed proposals above panel visibility boundaries. Hiding does not delete data or cancel an accepted calendar command. Pause hidden optional 3D/idle animations. Pending assistant responses may finish in the current session, but cannot reopen panels or apply changes; abort on session/account changes and ignore stale request results.

Proposed components when implemented: `PlanningWorkspace`, `CalendarPanel`, `PlanningAssistantPanel`, `HiddenPanelMascot`, and `MascotPopover`. These are names for future components, not existing source. A small reducer or local state is sufficient; no global UI framework, separate agent infrastructure, or alternative animation engine is needed.

## 7. Delivery and verification

1. Prototype the three layout states, direction of motion, mascot ownership, and popover reopening with sample content. No AI calls or database changes.
2. Implement the workspace shell around the existing calendar slice and a deterministic planner placeholder. Validate phone overview, focus modes, drafts, and accessibility before adding AI dependencies.
3. Add one planning request-to-proposal-to-editor journey after the actual provider/context/cost contract is established. A disabled or failed AI service cannot block the calendar.

Recommended scope: the split shell and deterministic mascots belong to the core UX direction; working AI planning has its own integration gate before being advertised. Existing calendar pilot gates remain in force. If AI has not shipped, label the panel's planning guidance/availability accurately rather than showing a fake live AI response.

Live AI is optional for the calendar pilot: a disabled integration does not fail Phase 1A. Enable it only after the provider/model, data-handling, token/cost reservations and proposal checks pass. Initial shared budgets are in [OPERATIONS_PLAN.md](OPERATIONS_PLAN.md#4-request-limits-and-provider-budgets); no model is selected or subscription purchased by this decision.

Use the first-session plan's Add Quest, editor dismissal, loading/coverage, and recovery states when implementing the shell. Unsaved form drafts survive in-session panel switches, not guaranteed reload/closure; durable save claims begin at the local transaction. Real AI and optional assets never block this foundational journey.

Acceptance: split starts at 50/50; each hidden panel exits through its own edge; only its own mascot appears; Open restores split; Ask planner opens the composer; every normal calendar/control/scroll action still works; keyboard and reduced-motion behavior preserve usability; hidden content cannot receive focus; drafts and pending saves survive switches; rapid taps/resize/session changes resolve safely; AI suggestions require review and the existing save path; no unsolicited network requests, XP, or data mutations occur from navigation.

**Remaining visual choices:** mascot identity/art and final motion tuning. These do not block the state/interaction contract above.
