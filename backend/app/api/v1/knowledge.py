from fastapi import APIRouter, status
from app.schemas.knowledge import KnowledgeQuery, KnowledgeResponse
from app.services.rag_service import rag_service

router = APIRouter()

@router.post(
    "/query",
    response_model=KnowledgeResponse,
    status_code=status.HTTP_200_OK,
    summary="Query Automotive Knowledge Base (RAG)",
    description="Searches indexed manuals, warning symbols, and OBD indices to generate grounded answers using Google Gemini."
)
def query_knowledge_base(payload: KnowledgeQuery):
    """
    Query the knowledge base using natural language:
    
    - **query**: Your diagnostic or assistance search (e.g., 'chain slack standard').
    - **k**: Optional number of document chunks to match.
    """
    return rag_service.query_rag(payload)
