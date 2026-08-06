import uuid
import time
from typing import List, Dict, Tuple, Optional
from fastapi import HTTPException, status
from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from app.core.config import settings
from app.core.exceptions import InferenceException
from app.core.logging import logger
from app.schemas.chat import ChatRequest, ChatResponse, DiagnosticSummary
from app.schemas.diagnosis import DiagnosisInput
from app.schemas.knowledge import KnowledgeQuery
from app.services.diagnosis_service import diagnosis_service
from app.services.rag_service import rag_service

class SessionMemory:
    def __init__(self) -> None:
        self.history: List[Dict[str, str]] = [] # List of {"role": "user"/"assistant", "content": "..."}
        
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
    def __init__(self) -> None:
        self.sessions: Dict[str, SessionMemory] = {}
        self.llm = None
        self._initialize_llm()
        
    def _initialize_llm(self) -> None:
        try:
            api_key = settings.GEMINI_API_KEY
            if not api_key or api_key == "AIzaSyDummyKeyForNow":
                self.llm = None
            else:
                self.llm = ChatGoogleGenerativeAI(
                    model=settings.GEMINI_MODEL,
                    google_api_key=api_key,
                    temperature=0.3
                )
                logger.info("Gemini Pro connector initialized for Conversation Engine.")
        except Exception as e:
            logger.critical(f"Failed to initialize Gemini for ChatService: {str(e)}")
            self.llm = None

    def create_session(self) -> str:
        session_id = f"session_{uuid.uuid4().hex[:12]}"
        self.sessions[session_id] = SessionMemory()
        logger.info(f"Created new conversation session: {session_id}")
        return session_id

    def get_session_history(self, session_id: str) -> List[Dict[str, str]]:
        if session_id not in self.sessions:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Conversation session '{session_id}' not found."
            )
        return self.sessions[session_id].history

    def handle_chat(self, payload: ChatRequest) -> ChatResponse:
        start_time = time.perf_counter()
        session_id = payload.session_id
        
        # Auto-create session if missing in database map
        if session_id not in self.sessions:
            self.sessions[session_id] = SessionMemory()
            
        session = self.sessions[session_id]
        user_message = payload.message.strip()
        
        # 1. Intent Classification
        intent = self._classify_intent(user_message)
        
        diagnostic_details = None
        response_text = ""
        modules_used = []
        llm_latency_ms = None
        error_msg = None
        
        # 2. Orchestrated Dispatch Routing
        try:
            if intent in ["Vehicle Diagnosis", "Repair Cost"]:
                modules_used.append("Diagnosis Engine")
                response_text, diagnostic_details = self._orchestrate_diagnosis(user_message)
                
            elif intent in ["Dashboard Warning", "OBD Error", "Vehicle Maintenance", "Spare Parts", "App Support"]:
                modules_used.append("Knowledge Engine (RAG)")
                response_text = self._orchestrate_rag(user_message)
                
            else:
                modules_used.append("Conversational LLM")
                llm_start = time.perf_counter()
                response_text = self._orchestrate_conversation(user_message, session)
                llm_latency_ms = (time.perf_counter() - llm_start) * 1000
                
        except Exception as err:
            error_msg = str(err)
            logger.error(f"Error handling orchestration inside ChatService: {error_msg}")
            response_text = "I'm sorry, my systems encountered a diagnostic loading failure. Let me connect you with a service provider."
            
        # Update session memory
        session.add_message("user", user_message)
        session.add_message("assistant", response_text)
        
        total_latency_ms = (time.perf_counter() - start_time) * 1000
        
        # Structured Audit Logging
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
            llm_latency_ms=round(llm_latency_ms, 2) if llm_latency_ms else None
        )

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
            "smoke": "Black smoke"
        }
        
        for kw, sym in symptoms_map.items():
            if kw in msg_lower:
                extracted_symptoms.append(sym)
                
        if not extracted_symptoms:
            extracted_symptoms.append("Engine vibration")
            
        diag_res = diagnosis_service.predict_fault(DiagnosisInput(
            mileage=settings.DEFAULT_VEHICLE_MILEAGE,
            symptoms=extracted_symptoms
        ))
        
        diag_summary = DiagnosticSummary(
            predicted_fault=diag_res.predicted_fault,
            estimated_cost=diag_res.estimated_cost,
            repair_time=diag_res.repair_time,
            safety_advice=diag_res.safety_advice
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
            )
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

# Singleton Service Instance
chat_service = ChatService()
