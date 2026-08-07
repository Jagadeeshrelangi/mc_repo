# Module Knowledge: AI Assistant (`frontend/lib/features/ai/`)

> Phase 5 · Tab 3. Source: Architecture §5.1, API §4, SPRINT_1_9.

## Purpose
AI chat + guided diagnosis + conversation history; cross-module action routing
(book mechanic, search parts, fuel recommendation). Mock keyword engine at RC1.

## Inventory
| Layer | Items |
|---|---|
| Models (7) | `AiBlock`, `AiActionButton`, `AiResponse`, `ChatMessage`, `Conversation`, `Diagnosis`, `QuickAction`, `SuggestedQuestion` |
| Provider | `AiProvider` — owns ONE `AiRepository` shared with `AiService` + `DiagnosisService` |
| Repositories | `AiRepository` (900ms latency, `failForFirstCalls`) |
| Services | `AiService`, `DiagnosisService` |
| Screens (5) | `AiHomeScreen`, `ChatScreen`, `DiagnosisScreen`, `ConversationHistoryScreen`, `ConversationDetailScreen` |
| Widgets (10) | chat bubbles, quick action cards, diagnosis cards, severity badges, etc. |
| Navigation | `navigation.dart`: `/ai`, `/ai/chat`, `/ai/diagnosis`, `/ai/history`, `/ai/conversation`, `aiFadeRoute` |

## Key Behavior
- Seed: 5 conversations (`ai-0001` Engine overheating … `ai-0005` Oil change), 2 pinned.
- `sendMessage` returns keyword knowledge-base replies; `diagnoseVehicle` returns typed payload.
- `AiBlock.type`: text | warning | recommendation | bulletList | checklist | costEstimate.
- `AiAction`: openDiagnosis | bookMechanic | searchParts | fuelRecommendation.
- Pull-to-refresh uses `_mergeReloaded()` — preserves user conversations + pin overrides.
- Conversation rename/delete via bottom sheet; returns results via `Navigator.pop(value)`.

## Failure Paths
`AiNetworkException` (retry UI); confidence < 60% → misdiagnosis disclaimer (product-level, R4).

## Tests
`test/ai_module_test.dart` — 25 tests.

## Backend Relation (Sprint 2)
Scaffold: `api/v1/conversation.py` · `diagnosis.py` · `knowledge.py`;
`chat_service` (Gemini/langchain) · `diagnosis_service` (XGBoost joblib) · `rag_service` (FAISS KB).
Tables: `conversations`, `chat_messages` (response JSONB), `diagnoses`.
