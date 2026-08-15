"""Conversation Engine service (Sprint 2, Task 4 — Conversation Ownership).

Refactored from the Stage 2 in-memory singleton into a REQUEST-SCOPED service
(mirrors ``AuthService``): constructed per request with the ``AsyncSession``
from ``get_db``, owns the transaction boundary (single ``commit()`` per write
flow), and persists conversations + messages through owner-scoped
repositories instead of the process-local ``sessions`` dict.

Ownership rules implemented here (recon report §9, §12):
- Every read/write resolves ``get_owned(session_id, user_id)``; a miss maps to
  a GENERIC ``EntityNotFoundException("Conversation not found.")`` — identical
  for "does not exist" vs "belongs to someone else" (no existence leak).
- ``user_id`` ALWAYS comes from ``get_current_user().id`` (route handler),
  never from the request body or the session id.
- No auto-create on chat (removed chat_service.py:73–74): an unknown session
  is a 404, never a silently created cross-user session.
- The 12-turn prompt cap is enforced at the query level
  (``ChatMessageRepository.list_for_conversation(limit=12)``).
- The first user message derives the conversation title (authoritative schema
  requires ``title NOT NULL``).

Transaction boundaries (§12.9): ``handle_chat`` = one transaction (conversation
check + user append + assistant append + touch → single commit); ``create_session``
= one transaction; ``get_session_history`` = read-only, never commits.
"""

import time
import uuid
from typing import Any, Dict, List, Optional, Tuple

from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI

from app.core.config import settings
from app.core.exceptions import EntityNotFoundException, InferenceException
from app.core.logging import logger
from app.repositories.chat_messages import ChatMessageRepository
from app.repositories.conversations import ConversationRepository
from app.schemas.chat import ChatRequest, ChatResponse, DiagnosticSummary
from app.schemas.diagnosis import DiagnosisInput
from app.schemas.knowledge import KnowledgeQuery
from app.services.diagnosis_service import diagnosis_service
from app.services.rag_service import rag_service


class SessionMemory:
    """In-memory prompt window fed to the LLM.

    After Task 4 it is a PURE FORMATTER built from loaded persisted history —
    it no longer owns storage. ``add_message`` keeps the trim as a defensive
    cap (the authoritative 12-turn limit is the repository query limit).
    """

    def __init__(self) -> None:
        self.history: List[Dict[str, str]] = []  # List of {"role", "content"}

    def add_message(self, role: str, content: str) -> None:
        self.history.append({"role": role, "content": content})
        if len(self.history) > 12:
            self.history = self.history[-12:]

    def get_formatted_history(self) -> str:
        formatted = []
        for msg in self.history:
            role_label = "User" if msg["role"] == "user" else "Engineer"
            formatted.append(f"{role_label}: {msg['content']}")
        return "\n".join(formatted)


class ChatService:
    """Request-scoped conversation orchestration (persistence + ownership).

    Constructed per request with the request's ``AsyncSession``; the single
    ``commit()``/``rollback()`` boundary lives here, never in the routes or the
    repositories (Stage 4 flush-only convention).
    """

    # Shared Gemini client: initialized once per process, reused across the
    # per-request service instances (never re-initialized per request).
    _llm: Optional[ChatGoogleGenerativeAI] = None

    def __init__(
        self,
        session,
        conversation_repository: Optional[ConversationRepository] = None,
        chat_message_repository: Optional[ChatMessageRepository] = None,
    ) -> None:
        self.session = session
        self.conversations = conversation_repository or ConversationRepository(session)
        self.messages = chat_message_repository or ChatMessageRepository(session)
        if ChatService._llm is None:
            ChatService._llm = self._build_llm()
        self.llm = ChatService._llm

    @staticmethod
    def _build_llm() -> Optional[ChatGoogleGenerativeAI]:
        """Create the Gemini client once; ``None`` when the key is unset/dummy."""
        try:
            api_key = settings.GEMINI_API_KEY
            if not api_key or api_key == "AIzaSyDummyKeyForNow":
                return None
            llm = ChatGoogleGenerativeAI(
                model=settings.GEMINI_MODEL,
                google_api_key=api_key,
                temperature=0.3,
            )
            logger.info("Gemini Pro connector initialized for Conversation Engine.")
            return llm
        except Exception as e:
            logger.critical(f"Failed to initialize Gemini for ChatService: {str(e)}")
            return None

    async def create_session(self, user_id: str) -> str:
        """Create a new conversation owned by ``user_id``; return its id."""
        conversation = await self.conversations.create_owned(user_id=user_id)
        await self.session.commit()
        logger.info(f"Created new conversation session: {conversation.id}")
        return conversation.id

    async def get_session_history(
        self, session_id: str, user_id: str
    ) -> List[Dict[str, str]]:
        """Return the persisted dialogue turns (owner-guarded; read-only)."""
        conversation = await self.conversations.get_owned(session_id, user_id)
        if conversation is None:
            raise EntityNotFoundException("Conversation not found.")
        messages = await self.messages.list_for_conversation(
            conversation_id=session_id
        )
        return [{"role": m.role, "content": m.content or ""} for m in messages]

    async def handle_chat(self, payload: ChatRequest, user_id: str) -> ChatResponse:
        start_time = time.perf_counter()
        session_id = payload.session_id

        # Ownership guard: the ONLY conversation lookup for the whole flow.
        conversation = await self.conversations.get_owned(session_id, user_id)
        if conversation is None:
            raise EntityNotFoundException("Conversation not found.")

        user_message = payload.message.strip()

        # 1. Intent classification
        intent = self._classify_intent(user_message)

        # Load the persisted prompt window (12-turn cap at the query level).
        history = await self.messages.list_for_conversation(
            conversation_id=session_id, limit=12
        )
        memory = SessionMemory()
        for msg in history:
            memory.add_message(msg.role, msg.content or "")

        diagnostic_details = None
        response_text = ""
        modules_used = []
        llm_latency_ms = None
        error_msg = None

        # 2. Orchestrated dispatch routing
        try:
            if intent in ["Vehicle Diagnosis", "Repair Cost"]:
                modules_used.append("Diagnosis Engine")
                response_text, diagnostic_details = self._orchestrate_diagnosis(user_message)

            elif intent in [
                "Dashboard Warning",
                "OBD Error",
                "Vehicle Maintenance",
                "Spare Parts",
                "App Support",
            ]:
                modules_used.append("Knowledge Engine (RAG)")
                response_text = self._orchestrate_rag(user_message)

            else:
                modules_used.append("Conversational LLM")
                llm_start = time.perf_counter()
                response_text = self._orchestrate_conversation(user_message, memory)
                llm_latency_ms = (time.perf_counter() - llm_start) * 1000

        except Exception as err:
            error_msg = str(err)
            logger.error(f"Error handling orchestration inside ChatService: {error_msg}")
            response_text = "I'm sorry, my systems encountered a diagnostic loading failure. Let me connect you with a service provider."

        # 3. Persist both turns (user first, then assistant — §12.7); one
        #    transaction, committed at the end.
        await self.messages.append(
            conversation_id=session_id, role="user", content=user_message
        )
        await self.messages.append(
            conversation_id=session_id, role="assistant", content=response_text
        )

        # Derive the title from the first user message (schema: title NOT NULL).
        if not history:
            await self.conversations.update_title(
                conversation, self._derive_title(user_message)
            )

        await self.conversations.touch(conversation)
        await self.session.commit()

        total_latency_ms = (time.perf_counter() - start_time) * 1000

        # 4. Structured audit logging
        logger.info(
            f"Conversation Engine Log | "
            f"Detected Intent: {intent} | "
            f"Modules Used: {', '.join(modules_used)} | "
            f"Latency: {total_latency_ms:.2f}ms | "
            f"LLM Response Time: {f'{llm_latency_ms:.2f}ms' if llm_latency_ms else 'N/A'} | "
            f"Errors: {error_msg or 'None'}"
        )

        return ChatResponse(
            response=response_text,
            intent=intent,
            session_id=session_id,
            diagnostic_details=diagnostic_details,
            latency_ms=round(total_latency_ms, 2),
            llm_latency_ms=round(llm_latency_ms, 2) if llm_latency_ms else None,
        )

    @staticmethod
    def _derive_title(user_message: str) -> str:
        """Derive a conversation title from the first user message."""
        cleaned = " ".join(user_message.split())
        return cleaned[:60] if cleaned else "New conversation"

    def _classify_intent(self, message: str) -> str:
        msg_lower = message.lower()

        # Rule-based intent detection (Failsafe fallback)
        if any(code in msg_lower for code in ["p0300", "p0115", "p0562", "p0299"]):
            return "OBD Error"
        if any(keyword in msg_lower for keyword in ["light", "symbol", "icon", "dashboard warning"]):
            return "Dashboard Warning"
        if any(keyword in msg_lower for keyword in ["refuel", "petrol", "diesel", "fuel delivery"]):
            return "Fuel Delivery"
        if any(keyword in msg_lower for keyword in ["parts", "oil filter", "battery cost", "tire purchase"]):
            return "Spare Parts"
        if any(keyword in msg_lower for keyword in ["mechanic", "book", "call help", "dispatch"]):
            return "Mechanic Booking"
        if any(keyword in msg_lower for keyword in ["schedule", "maintenance", "coolant level", "oil change"]):
            return "Vehicle Maintenance"
        if any(keyword in msg_lower for keyword in ["cost to fix", "how much", "repair estimate"]):
            return "Repair Cost"
        if any(keyword in msg_lower for keyword in ["app support", "login issue", "cancel order"]):
            return "App Support"

        symptom_triggers = ["start", "click", "smoke", "noise", "vibration", "squeal", "pickup", "overheat", "flat"]
        if any(trigger in msg_lower for trigger in symptom_triggers):
            return "Vehicle Diagnosis"

        return "General Vehicle Question"

    def _orchestrate_diagnosis(self, message: str) -> Tuple[str, Optional[DiagnosticSummary]]:
        extracted_symptoms = []
        msg_lower = message.lower()

        symptoms_map = {
            "won't start": "Engine won't start",
            "clicking": "Clicking sound",
            "overheating": "Overheating",
            "vibration": "Engine vibration",
            "noise": "Brake noise",
            "squeal": "Brake noise",
            "flat": "Flat tyre",
            "puncture": "Flat tyre",
            "smoke": "Black smoke",
        }

        for kw, sym in symptoms_map.items():
            if kw in msg_lower:
                extracted_symptoms.append(sym)

        if not extracted_symptoms:
            extracted_symptoms.append("Engine vibration")

        diag_res = diagnosis_service.predict_fault(
            DiagnosisInput(
                mileage=settings.DEFAULT_VEHICLE_MILEAGE,
                symptoms=extracted_symptoms,
            )
        )

        diag_summary = DiagnosticSummary(
            predicted_fault=diag_res.predicted_fault,
            estimated_cost=diag_res.estimated_cost,
            repair_time=diag_res.repair_time,
            safety_advice=diag_res.safety_advice,
        )

        response = (
            f"As a Senior Automotive Engineer, I've evaluated the symptoms you described: "
            f"{', '.join(extracted_symptoms)}. Based on my diagnostics, the most likely issue is a **{diag_res.predicted_fault}**. "
            f"Typically, fixing this costs around INR {diag_res.estimated_cost} and takes about {diag_res.repair_time}.\n\n"
            f"**Safety Recommendation**: {diag_res.safety_advice}"
        )
        return response, diag_summary

    def _orchestrate_rag(self, message: str) -> str:
        rag_res = rag_service.query_rag(KnowledgeQuery(query=message, k=3))
        return rag_res.answer

    def _orchestrate_conversation(self, message: str, session: SessionMemory) -> str:
        chat_prompt = PromptTemplate(
            input_variables=["history", "query"],
            template=(
                "You are Mecha Connect's Senior Automotive Engineer. You have over 20 years of experience "
                "troubleshooting passenger cars, motorcycles, and commercial vehicle engines.\n"
                "- Do NOT introduce yourself or greet the user repeatedly.\n"
                "- Speak like an experienced shop foreman: professional, brief, direct, and authoritative.\n"
                "- If asked diagnostic, maintenance, emergency, or insurance questions, answer with clear, structured steps.\n"
                "- Explain complex systems (like transmissions or electrical loops) using simple mechanical terms.\n"
                "- Never guess or hallucinate parameters. If you lack context, tell the user to visit a workshop.\n\n"
                "Conversation History:\n{history}\n\n"
                "User: {query}\n\n"
                "Engineer Reply:"
            ),
        )

        history_str = session.get_formatted_history()
        prompt = chat_prompt.format(history=history_str, query=message)

        if self.llm is None:
            if not settings.ENABLE_FALLBACK:
                logger.error(f"Gemini Request Failed | Model: {settings.GEMINI_MODEL} | Error: GEMINI_API_KEY is unconfigured and fallback mode is disabled.")
                raise InferenceException("GEMINI_API_KEY is unconfigured and fallback mode is disabled.")
            return self._fallback_chat_reply(message)
        else:
            try:
                logger.info(f"Gemini Request | Model: {settings.GEMINI_MODEL} | Prompt Length: {len(prompt)} characters")
                res = self.llm.invoke(prompt)
                logger.info("Gemini Response | Status: 200 OK | Success")
                return res.content
            except Exception as e:
                logger.error(f"Gemini Request Failed | Complete Exception: {str(e)}", exc_info=True)
                if not settings.ENABLE_FALLBACK:
                    raise InferenceException(f"Gemini API failure: {str(e)}")
                return self._fallback_chat_reply(message)

    def _fallback_chat_reply(self, message: str) -> str:
        logger.info("Executing local conversational fallback response.")
        return (
            "[Senior Engineer Response (Local Fallback - Key Missing)]\n"
            f"Understood. Regarding your query about \"{message}\", without my full neural diagnostics active, "
            "I recommend checking standard service intervals. Please ensure to check fluid levels (oil, coolant), "
            "inspect battery voltage, and scan for active OBD fault codes using the diagnostics tool."
        )