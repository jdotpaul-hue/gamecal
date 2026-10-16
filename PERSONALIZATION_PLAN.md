# Personal Assistant Personalization and Teaching

**Updated:** 16 October 2026

**Status:** Planning proposal responding to the user's hybrid charter/settings/teaching/template idea. This extends [the personal AI direction](PERSONAL_AI_PLAN.md); it creates no UI, SQL, provider integration, autonomous job or public marketplace. Voice-led Calendar and People remain the confirmed product direction. Scope/defaults below are recommendations for review.

**Knowledge extension:** [SECOND_BRAIN_PLAN.md](SECOND_BRAIN_PLAN.md) develops explicit source notes, automatic Markdown organization/linking and cited retrieval. Routine generated summaries/topics/links need no per-item approval; preserve provenance and selective clarification. Note capture does not automatically promote content into an authoritative preference or executable rule. Derived chunks/vectors follow source revision, ownership and forgetting; a private notes export is distinct from a public persona template. The cute-monster presentation grants no extra tool authority.

**Memory engine option:** [Mem0 is an optional evaluation candidate](SECOND_BRAIN_PLAN.md#11-mem0-evaluation-optional-memory-engine), not an adopted dependency. Library/service extraction defaults do not override our capture scope, explicit-memory promotion or forget/correction contracts. Evaluate engine reuse before building generic infrastructure, while keeping authoritative rules/permissions and original notes under application ownership.

## 1. Product model

Let users describe the assistant they want, then make the resulting behavior understandable and editable. Use five distinct controls rather than one giant prompt or a universal autonomy slider.

| Control | Example | Meaning |
| --- | --- | --- |
| Personality | “Warm, witty and concise.” | Tone, vocabulary and presentation; cannot grant access or actions |
| Charter | “Help me protect rest and make time for close friends.” | A human-readable statement of purpose, priorities and working style |
| Planning rules | “No social plans starting before 10:00 in Asia/Singapore.” | Typed constraints enforced by application validation once confirmed |
| Action permissions | “Suggest calendar changes; ask me before saving.” | Capability-specific authority checked outside the model |
| Approved memory | “Alex prefers Friday afternoons.” | An attributed, editable user note; not proof of Alex's availability or permission |

Recommended positioning: **Teach your assistant how to help you, and see what it has learned.** Personalization helps useful planning; engagement with a persona is not itself a growth outcome.

The charter can show a readable summary of confirmed preferences/rules, but that summary is derived. Structured values remain authoritative. The assistant must not maintain a second conflicting set of rules in prose.

## 2. Charter and personality experience

Start with three built-in styles: Calm Planner, Gentle Coach and Direct Organizer. Each supplies a previewable tone and suggested charter wording. A user can customize by voice or text without knowing prompt syntax. Presets create configuration for the same assistant, not separate agents or accounts.

A useful charter editor covers: how to speak to me, what matters to me, how I prefer to plan, and what I want help remembering. Link “Planning rules” and “What you may do” as separate controls. Keep onboarding optional and short; let the first real request reveal useful preferences.

A proposed initial limit of 4,000 characters for free-text charter input is an app validation/budget choice, not a verified Grok requirement. Keep UI/server limits aligned and show remaining space. Context assembly still needs a token budget; characters are not tokens. Voice transcripts use the same limit and remain editable before acceptance when recognition is uncertain.

“Be a protective gatekeeper” can mean gently recommending rest or drafting a polite decline. It does not permit inventing an emergency, sending an excuse, cancelling an event or hiding relevant facts. Direct user-facing tone and outbound message tone are separate; a playful assistant need not produce a sarcastic message to a friend. Outbound drafts stay visible and editable.

Changing a personality preserves memories, planning rules and permissions. Offer a short simulated response before applying a preset and a reversible settings change afterward. Distinguish Reset personality from Forget memory and Delete account.

## 3. Translate natural language into explicit rules

Treat natural-language settings as proposed input to a small typed model. Begin with a few useful rule kinds: preferred hours, unavailable windows, planning buffers and scope such as personal/social versus work. Avoid a general executable rule language or arbitrary generated code.

Example: “Never book things before ten unless it's an emergency.”

1. Apply the requested correction to the current proposal without silently changing an existing saved event.
2. Offer “Use this once” and “Make this a planning rule.” No repeated nudge after dismissal.
3. For a standing rule, clarify the scope, 10:00 AM meaning, days and IANA timezone, plus whether it follows the planning zone when travelling. Do not invent an emergency detector or exception policy.
4. Preview the exact rule and its effect: “For new social suggestions, avoid starts before 10:00, Asia/Singapore, every day.” If an exception is wanted, use a deliberate per-proposal override when supported.
5. Save the confirmed rule through a validated settings operation, then label its actual local/accepted status. Explain any existing commitments that conflict; do not move them automatically.

An ordinary preference affects ranking. A confirmed block excludes proposals within its declared scope. Neither implies that the user's whole external schedule is known. Date/time rules follow the existing calendar's explicit timezone/DST model. A rule cannot be advertised as enforced for a schedule variant whose command support does not exist yet.

Use one constraint evaluator for candidate filtering and pre-save validation. Recheck relevant canonical rules, data revisions and permission revisions at execution. A stale proposal needs renewed review when its meaning changes. If rules conflict, show the conflict and offer an edit; never choose a hidden winner based on prompt order. A session-level request does not silently erase a durable block.

App/account authorization and domain invariants always constrain actions. Personality, templates, retrieved content and model output never override them. Users can explicitly edit their own rules or approve a supported one-time exception; this does not bypass server authorization or calendar validity.

## 4. Permissions by capability and effect

Use understandable actions rather than a single “full agent” setting. Separate permission to read, propose, persist and contact another person. Granting read access does not authorize writes; granting calendar writes does not authorize messages.

| Action | Proposed first-pilot behavior | Later expansion |
| --- | --- | --- |
| Read selected Calendar/People context | Authenticated, scope-limited reads for a user request; clear data controls | Explicit additional source integrations |
| Suggest plans and draft messages | Allowed within selected context; no saved event or sent message implied | More bounded tools when useful |
| Save/change calendar entries | Review a specific proposal/version, then use the normal durable operation | Narrow standing grants only after execution/recovery proof |
| Remember a preference/fact | Explicit, sufficiently clear “Remember…” intent or approval of a suggested memory | Opt-in behavior-derived suggestions |
| Change a planning block or permissions | Explicit settings review; never inferred from tone or feedback | Still a distinct settings operation |
| Send invitations/messages, book or pay | Unavailable in the initial pilot | Separate supported integration, targets, limits and authorization |
| Initiate work while the browser is closed | Unavailable in the initial pilot | Separately designed standing assignment and backend runner |

Show unavailable capabilities as unavailable. A toggle cannot imply a working integration or grant scope that the authenticated user does not own. Drafting an invitation and actually sending it are separate actions with separate feedback.

If standing action grants are introduced later, each must identify the tool/action, permitted targets, field/resource scope, maximum effect/rate, activation/expiry and revision. Default to no standing write/send grant. Require explicit review of each grant and make revocation visible. Never import grants from templates or infer them from “handle my social life.”

Authoritative permission checks belong in trusted application/server execution, not only a model prompt or model-based reviewer. Cross-account identity, current grant, proposal ownership and revisions are checked again when an approved operation executes. Ordinary RLS proves account isolation; it does not by itself enforce assistant-specific permission policy. Do not give the provider an unrestricted SQL client or broad account credential.

Authority expansion requires accepted online settings before use. Unsynced or stale settings cannot authorize a new autonomous action. A local restriction/pause should stop new work on that device immediately while its revocation syncs; the UI must not promise account-wide revocation until accepted. Later background/external execution needs a defined transaction/lease boundary for grant-check versus execution races. Revocation stops future work at that boundary; it cannot recall an already sent message or undo accepted work.

## 5. Teaching and memory lifecycle

Support explicit correction first. Show what changed in the current plan and, separately, a proposed reusable lesson. A change to one event is not consent to a permanent preference.

Suggested rule/memory states: proposed, accepted, superseded, rejected and forgotten. Keep a source reference where available, explicit/inferred origin, scope, revision and optional review/expiry. Confidence can help rank a suggestion; it never grants authority or makes a third-party fact verified.

The user can say “Only this time,” “Remember that,” “Show what you remember,” or “Forget this.” A card makes the precise operation visible. Voice approval binds to the current card/version; ambiguous acknowledgments do not approve a different memory, rule or calendar action. Saving a setting does not need a second confirmation when the user's explicit intent and scope are already clear.

Behavior observation is a later opt-in experiment, limited to disclosed in-app actions. Repeated declines may justify offering a preference review; they do not prove dislike of a person, a diagnosis or a sensitive identity. Do not monitor external activity, retain raw audio for learning, or silently turn interaction history into permanent memory. Let users disable observation independently of explicit memory.

The Memory and Rules view should show active values, why they are present, relevant scope and edit/forget controls. Corrections replace the current authoritative value; past prompt summaries, retrieved copies and vector entries must not keep reviving it. Forgetting removes usable content and invalidates dependent retrieval/context caches. In-flight proposals using it become stale; clear or restart affected live provider context before continuing, or disclose a provider limitation and end that session. Provider-side retention remains a separate verified policy.

Keep only the minimal content-free receipt/tombstone needed for retries after forgetting, with an explicit retention policy; do not preserve the forgotten text in an activity log. Cross-device propagation, export and account/source deletion require their own accepted lifecycle proof. Undoing a settings change creates a new validated revision; it does not rewind an audit stream or roll back calendar actions already executed.

## 6. Initiative and always-on work

Treat initiative and action authority as separate dimensions. A future daily briefing could run on a standing schedule with read-and-report permission while all calendar writes still need review. Natural personality does not require persistent microphone capture or a constantly running worker.

For the first pilot, respond to deliberate interaction and show suggestions while the app is active. Use a visible suggestions area with dismiss/snooze controls; do not claim browser-closed monitoring, push delivery or contact reminders. In-app People intentions remain distinct from delivered notifications.

Before standing assignments ship, specify: explicit goal and completion/expiry, timezone/schedule/trigger, required source coverage, allowed actions, quiet hours and interruption limits, budget/attempt limits, last successful check, next check, pause/revoke and failure states. Use a bounded backend job/queue with idempotent run IDs and operation receipts. Do not replay private prompts or external sends through the foreground calendar outbox. No job or automation is created by this planning document.

## 7. Templates and sharing

Start with curated built-in presets. Useful themes include Quiet Social Planner, Balanced Week and Direct Organizer. Preview tone and a sample plan; users select which suggested defaults to apply. A template proposes settings, never replaces existing values without a visible diff. Existing memories and account facts remain separate.

Private export/import can follow demonstrated demand. A public marketplace is a later product with public/private authorization, reporting/moderation, versioning, removal and abuse handling; it is not a prerequisite for personalization or validated growth.

A future portable template is an allowlisted, schema-versioned configuration: title/description, persona text, generic charter guidance, suggested rule parameters and placeholders. It contains no executable code, credentials, tool grants, enabled connections, background assignments, conversation history, learned memory, person/contact records or source attachments. Do not include private identifiers, internal URLs or active account record references.

Free-text instructions can contain personal data even when named memory fields are excluded. Build the export from selected reusable fields; require preview and author review of the actual content. Automated scanning or model redaction can assist but cannot guarantee anonymization. Publishing is deliberate and warns about publicly visible text; private export does not automatically publish.

Installation creates an independent private copy pinned to a template version. It displays changes, requires any supported source setup/permissions separately, and cannot silently accept later author updates. Treat template text as untrusted input under the same instruction/permission boundary as user material. Removing a public template stops new discovery/access as supported; do not promise recall of exported copies.

## 8. Data architecture and contracts to design

Reuse the modular monolith and typed application operations. The following are conceptual records, not a decision to add one SQL table for every row. [Database schema](DATABASE_SCHEMA_PLAN.md), [RLS](RLS_PLAN.md) and [API contracts](API_CONTRACTS.md) remain the owners of exact SQL/grants/wire contracts when the slice is specified.

| Concept | Authority and versioning | Access and lifecycle |
| --- | --- | --- |
| Assistant configuration | Accepted owner-scoped settings; persona/charter revision | Private; resettable without deleting unrelated data |
| Planning rule | Typed condition/scope/timezone and revision; derived prose summary | Owner-controlled; runtime validation; explicit exception/conflict behavior |
| Memory or teaching suggestion | Attributed owner record with origin/state/revision | Private; edit/forget/export, bounded retrieval and source dependency invalidation |
| Action grant, later | Trusted permission record; narrow scope, validity and revision | Explicit owner change; no template/model writes; execute-time validation |
| Proposal/action record | Frozen intention and relevant source/config revisions | Same-account review, expiry, durable operation identity and truthful outcome |
| Standing assignment, later | Explicit bounded job definition and run status | Trusted runner, revocation, budgets, scoped sources and retry receipts |
| Template, later | Versioned portable settings copy | Private by default; public projection explicitly allowlisted if publishing ships |

Reuse existing preference fields only where they already express the same fact. Do not place permissions in an unvalidated profile JSON blob, duplicate a calendar inside memory or expose private notes through a template join. References to people/sources require matching owner relationships. Private rows require RLS and least-privilege command grants; derived public template content needs a separate reviewed access model.

Supabase remains authoritative for accepted synced state. Dexie may retain supported local intentions and labeled confirmed snapshots using the established account partition, revision and recovery rules. This plan does not promise all future memory files or transcripts are stored locally. Decide per data class what is persisted, synced and sent to a provider; keep credentials outside ordinary account data.

Context construction should select bounded relevant configuration and memory with source IDs/revisions. Tool execution uses typed inputs and independent policy validation; prompt generation consumes a rendering of that policy but is not its enforcement. No extra backend, fine-tuning pipeline, vector database, general rule engine or agent framework is required for the first preference/correction slice.

## 9. Delivery and acceptance

| Stage | Scope | Evidence required |
| --- | --- | --- |
| First personalization slice | Three built-in styles, editable charter, explicit preference/memory, scoped planning rule and action review | One voice/text correction, visible current rule, edit/forget, account isolation and truthful save feedback |
| Later teaching experiment | Opt-in in-app behavior suggestions and a small activity view | Useful suggestions without unwanted inference; dismissal/forgetting works and no hidden standing rules |
| Later portability | Private template export/import, then curated sharing if useful | Actual-content preview, no private data/grant leakage, independent copy and deliberate updates |
| Separately gated automation | Standing assignments or narrow autonomous actions | Supported integrations, backend lifecycle, revocation/race/retry proof, cost limits and consequence-specific authorization |

The first slice follows the [existing correctness/Auth/calendar prerequisites](PERSONAL_AI_PLAN.md#8-recommended-first-pilot-and-build-sequence). Keep the initial rule set small. Full autonomy, passive learning and a marketplace are not first-pilot requirements.

Before implementation, finalize the first rule types, persona/charter limits, memory/source expiry, retention of content-free receipts, exact persistence/API/RLS mapping and supported voice browsers. Permissions, budget and tool schemas need concrete acceptance examples rather than generic “AI safety” prose.

Acceptance fixtures must cover: a one-time correction versus a durable lesson; a fully specified explicit Remember action; ambiguous “emergency” exception; travel/DST rule behavior; competing rules; persona/template permission escalation attempts; stale/revoked settings; cross-account access; memory forgetting during a live session; duplicate retries; reset versus forget; template preview/private data exclusion and imported-copy independence when portability ships. Add fixtures only as their corresponding behavior is implemented.

Measure intended task success, correction effort, useful remembered preferences, unwanted suggestions, permission comprehension and ability to inspect/forget. Persona popularity, chat length or a high number of reminders do not establish better planning or relationships.

## 10. Research interpretation

Official [xAI bot documentation](https://docs.x.ai/grok-bot/bots) describes editable profiles, persistent preferences and shared templates that create recipient copies. It also cautions that memory is not the authoritative source for changing facts. These are implementation examples, not proof of user benefit or a choice of provider for Gamecal.

Official [approval guidance](https://docs.x.ai/grok-bot/approvals-security-and-privacy) describes reviewing specific action inputs and narrow approval rules. Our proposed typed, application-enforced permissions are Gamecal architecture decisions, not a claim that copying a prompt reproduces another product's execution guarantees.

[Jakob Nielsen's interaction-styles article](https://jakobnielsenphd.substack.com/p/ai-interaction-styles) distinguishes requested tasks from standing responsibilities, separates authority from initiative, and argues for inspectable learned rules. It is UX commentary, not a controlled evaluation of this product. We adopt the questions as design prompts and validate the proposed experience with users.

The supplied third-party settings article does not establish an exact official charter limit or a universal autonomy scale. Community posts, videos and marketing descriptions are inspiration; no fine-tuning, always-on service, passive-learning benefit or marketplace growth claim is treated as established by them. See [the research review](RESEARCH_REVIEW.md#12-personal-assistant-personalization).
