from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class ChatRequest(BaseModel):
    message: str = Field(..., description="The user's chat message.", example="My engine won't start and makes a clicking noise.")
    session_id: str = Field(..., description="The session ID to maintain conversation memory.", example="session_abc_123")

class DiagnosticSummary(BaseModel):
    predicted_fault: str = Field(..., description="The identified vehicle system fault.")
    estimated_cost: int = Field(..., description="Estimated repair cost in INR.")
    repair_time: str = Field(..., description="Estimated repair duration.")
    safety_advice: str = Field(..., description="Crucial safety guidelines.")

class ChatResponse(BaseModel):
    response: str = Field(..., description="The conversational response from the Senior Automotive Engineer.")
    intent: str = Field(..., description="The classified intent of the user message.")
    session_id: str = Field(..., description="Active session key associated with this conversation history.")
    diagnostic_details: Optional[DiagnosticSummary] = Field(None, description="Optional telemetry/symptom diagnostic summary if intent matches Vehicle Diagnosis.")
    latency_ms: float = Field(..., description="Total API processing time in milliseconds.")
    llm_latency_ms: Optional[float] = Field(None, description="LLM inference time in milliseconds.")

class SessionResponse(BaseModel):
    session_id: str = Field(..., description="Newly generated UUID session key.")

class MessageLog(BaseModel):
    role: str = Field(..., description="Message author (e.g. 'user', 'assistant').")
    content: str = Field(..., description="Message text payload.")

class HistoryResponse(BaseModel):
    session_id: str = Field(..., description="Active session key.")
    history: List[MessageLog] = Field(..., description="List of messages in the dialogue session.")
