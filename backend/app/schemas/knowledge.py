from typing import List, Optional
from pydantic import BaseModel, Field

class KnowledgeQuery(BaseModel):
    query: str = Field(..., description="The diagnostic or support question to search the knowledge base for.", example="What does P0300 code mean?")
    k: Optional[int] = Field(3, description="Number of document chunks to retrieve.", ge=1, le=10, example=3)

class SourceDoc(BaseModel):
    source: str = Field(..., description="Name of the source document.")
    category: str = Field(..., description="Knowledge base folder category.")
    score: float = Field(..., description="Vector similarity distance score.")

class KnowledgeResponse(BaseModel):
    answer: str = Field(..., description="The AI assistant's grounded answer.")
    sources: List[SourceDoc] = Field(..., description="Document source chunks used to formulate the answer.")
