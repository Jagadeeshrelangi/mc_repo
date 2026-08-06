# Sprint 1.9 — AI Assistant Module (Mock Backend)

**Date:** 2026-08-01
**Version:** 1.0
**Status:** ✅ Complete — analyze clean, all tests green

---

## Executive Summary

Sprint 1.9 delivered the complete production AI Assistant frontend under
`lib/features/ai/`, built exclusively on a mock backend that simulates real
network latency, timeouts and failures. The module matches the
Fuel/Mechanic/Marketplace feature-first architecture, ships a single-source
conversation store, and is fully wired into the app (root provider + bottom-nav
tab 3). Legacy `ChatBot` entry points were redirected to the new chat.

Verification:
- `flutter analyze` — **0 errors, 0 warnings** (only pre-existing `avoid_print`
  infos in `test/integration/verify_chatbot_widget.dart` and
  `verify_e2e_network.dart`).
- `flutter test test/ai_module_test.dart` — **25/25 pass**.
- `flutter test` (full suite) — **129/129 pass**.

## Deliverables

```
lib/features/ai/
├── ai.dart                       # module barrel
├── navigation.dart               # route constants, aiFadeRoute, open* helpers, AiAction routing
├── models/
│   ├── chat_message.dart         # role, content, timestamp, optional typed AiResponse
│   ├── conversation.dart         # pinned flag, rename/delete lifecycle
│   ├── quick_action.dart         # home quick-action + destination enum
│   ├── diagnosis.dart            # severity, cost, drive-flag, service, confidence
│   ├── ai_response.dart          # block types (warning/bullets/recommendation) + action buttons
│   ├── suggested_question.dart
│   └── models.dart
├── repositories/
│   └── ai_repository.dart        # mock backend: latency + failForFirstCalls injection,
│                                 # 5 seeded conversations, keyword knowledge base,
│                                 # diagnosis templates with generic fallback
├── services/
│   ├── ai_service.dart           # intent → AssistantReply (text + typed AiResponse)
│   └── diagnosis_service.dart    # parseDiagnosis: raw map → typed Diagnosis, FormatException guard
├── providers/
│   └── ai_provider.dart          # single conversation store + diagnosis lifecycle
├── screens/
│   ├── ai_home_screen.dart       # greeting, search entry, quick actions, health card,
│   │                             # recent diagnoses/conversations, tips, emergency modal
│   ├── chat_screen.dart          # thread, typing indicator, retry banner, regenerate,
│   │                             # composer, welcome chips, auto-send initialPrompt
│   ├── diagnosis_screen.dart     # 3-step guided flow → DiagnosisCard + CTAs
│   ├── conversation_history_screen.dart  # search, pinned/others, clear-all
│   ├── conversation_detail_screen.dart   # transcript, pin/rename/delete, continue chat
│   └── screens.dart
├── widgets/
│   ├── empty_state.dart, error_state.dart, loading_state.dart
│   ├── quick_action_card.dart, suggestion_chip.dart, conversation_tile.dart
│   ├── typing_indicator.dart, message_bubble.dart (incl. AiMarkdownText), diagnosis_card.dart
│   └── widgets.dart
```

## Architecture Decisions

- **Single source of truth.** `AiProvider` owns exactly one `_conversations`
  list; `currentConversation` and `messages` are derived views. The home list,
  history, detail and chat screens can never disagree.
- **Root provider.** `AiProvider` is created once in `buildRootProviders()`
  (`lib/app_wiring.dart`), mirroring the Marketplace wiring. No per-tab
  `ChangeNotifierProvider`, so the badge, list and thread always share one
  instance across navigation.
- **Navigation.** `aiFadeRoute` (220 ms fade) matches the Marketplace pattern;
  `openAiAction` maps every `AiAction` to a real destination
  (Mechanic/Marketplace/Fuel/Chat/Diagnosis) so no button is dead.
- **Mock-only backend.** The repository simulates 900 ms latency, timeout-free
  failure injection and a deterministic keyword knowledge base; the provider,
  services and screens only depend on its interface, so Sprint 2 swaps in the
  real Gemini/OpenAI client without touching the UI.
- **State handling.** Every screen renders Loading / Ready / Empty / Error /
  Retry explicitly via shared `AiLoadingState` / `AiEmptyState` / `AiErrorState`
  widgets.

## Wiring

- `lib/app_wiring.dart` — root `ChangeNotifierProvider(create: (_) => AiProvider())`.
- `lib/bottom_bar/bottom_navigation.dart` — index 3 → `const AiHomeScreen()`;
  removed the legacy `ChatBot` / `chatboard` import.
- `lib/features/home/screens/home_screen.dart` and
  `lib/starting_screen/home.dart` — legacy `ChatBot` push replaced with
  `openAiChat(context)`.
- `lib/debug/runtime_trace.dart` — `traceAi(...)` added (provider hashCode,
  conversation count, currentId, message count, isSending, state, navigator
  identity) and used by all AI screens. `kRuntimeTrace` remains `true` from the
  prior marketplace audit; it is expected to be flipped off in a later sprint.

## Bugs Found and Fixed During QA

| # | Bug | Root cause | Fix |
|---|-----|-----------|-----|
| 1 | `RangeError (length)` building the home quick-actions grid | 9 actions rendered in 2-column rows → index 9 out of range | `_buildSlot` bounds-checks the index and emits a placeholder cell (`ai_home_screen.dart`) |
| 2 | `RenderFlex` unbounded-height crash on quick-action cards | `Spacer` inside a column with no bounded height | Fixed card `height: 124` in `quick_action_card.dart` |
| 3 | `recentDiagnoses` shorter than expected (2–3 instead of 4) | Diagnosis ids used ms-timestamp → sequential diagnoses in the same millisecond collided and were deduped | Monotonic `_diagnosisCounter` id in `ai_repository.dart` |
| 4 | Chat/history tests could not find rendered message text | `AiMarkdownText` emits `RichText` (plus a trailing `\n`), which exact `find.text` misses by default | Tests use `find.textContaining(..., findRichText: true)` |

## Test Evidence

`test/ai_module_test.dart` — 25 tests across:
- `AiRepository` — seeded pinned-first ordering, failure injection + recovery,
  keyword raw replies, diagnosis templates, search.
- `AiService` / `DiagnosisService` — intent mapping, severity mapping,
  `FormatException` on missing causes.
- `AiProvider` — send/retry, regenerate, rename/delete/clear, togglePin
  floats-to-top, search filter, last-four diagnoses, empty-symptom rejection.
- Widgets — home sections + quick-action navigation to guided diagnosis,
  chat auto-send + send button, history search filter.

Full-suite result: `00:26 +129: All tests passed!`

## Next Steps (Sprint 2)

- Swap the mock `AiRepository` internals for the real Gemini/OpenAI client
  (provider, services and screens unchanged).
- Add a runtime integration test (real `main()` wiring) like the Marketplace
  P0 audit, driving Home → AI tab → Diagnosis → Chat.
- Flip `kRuntimeTrace` back to `false` once the runtime audit is closed.
