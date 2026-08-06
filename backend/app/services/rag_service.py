import os
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from app.core.config import settings
from app.core.exceptions import InferenceException
from app.core.logging import logger
from app.schemas.knowledge import KnowledgeQuery, KnowledgeResponse, SourceDoc

class RAGService:
    def __init__(self) -> None:
        self.index_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "ai", "knowledge_base", "faiss_index"
        )
        self.db = None
        self.embeddings = None
        self.llm = None
        self._initialize_pipeline()
        
    def _initialize_pipeline(self) -> None:
        try:
            # 1. Load the CPU embedding model
            logger.info("Initializing HuggingFace embeddings inside RAG service...")
            self.embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
            
            # 2. Load FAISS index database
            if not os.path.exists(self.index_dir):
                logger.error(f"FAISS index directory not found at {self.index_dir}. Vector DB must be built first.")
                self.db = None
                return
                
            self.db = FAISS.load_local(self.index_dir, self.embeddings, allow_dangerous_deserialization=True)
            logger.info("FAISS vector store successfully loaded into RAG service.")
            
            # 3. Load Gemini LLM
            api_key = settings.GEMINI_API_KEY
            if not api_key or api_key == "AIzaSyDummyKeyForNow":
                logger.warning("GEMINI_API_KEY is not configured or using placeholder. Gemini API calls will run in local mock fallback mode.")
                self.llm = None
            else:
                self.llm = ChatGoogleGenerativeAI(
                    model=settings.GEMINI_MODEL,
                    google_api_key=api_key,
                    temperature=0.2
                )
                logger.info("Gemini Pro RAG connector successfully initialized.")
        except Exception as e:
            logger.error(f"Failed to initialize RAG pipeline: {str(e)}")
            self.db = None
            self.llm = None

    def query_rag(self, payload: KnowledgeQuery) -> KnowledgeResponse:
        if self.db is None:
            raise InferenceException("RAG Knowledge base FAISS database is currently offline.")
            
        try:
            # Query similarity search
            k_val = payload.k or 3
            results = self.db.similarity_search_with_score(payload.query, k=k_val)
            
            if not results:
                return KnowledgeResponse(
                    answer="I'm sorry, I could not find any matching topics in our knowledge database manuals.",
                    sources=[]
                )
                
            # Compile context text and source documents list
            context_blocks = []
            sources = []
            
            for doc, score in results:
                src_meta = SourceDoc(
                    source=doc.metadata.get("source", "unknown"),
                    category=doc.metadata.get("category", "general"),
                    score=float(score)
                )
                sources.append(src_meta)
                context_blocks.append(f"Source: {src_meta.source} ({src_meta.category})\n{doc.page_content}")
                
            context_str = "\n\n---\n\n".join(context_blocks)
            
            # Formulate RAG Prompt
            prompt_template = PromptTemplate(
                input_variables=["context", "query"],
                template=(
                    "You are Mecha Connect's Senior Automotive Engineer. Answer the user's automotive "
                    "diagnostic, maintenance, or app-support questions accurately, using only the provided context below. "
                    "Be direct and practical. Do not begin with pleasantries or ChatGPT-like sentences.\n\n"
                    "If the context does not contain relevant information, say: \"I'm sorry, I cannot find sufficient "
                    "information in the vehicle manuals to diagnose this accurately.\"\n\n"
                    "Context:\n{context}\n\n"
                    "User Question:\n{query}\n\n"
                    "Engineers Grounded Answer:"
                )
            )
            
            prompt = prompt_template.format(context=context_str, query=payload.query)
            
            # Execute inference
            if self.llm is None:
                if not settings.ENABLE_FALLBACK:
                    logger.error(f"Gemini Request Failed | Model: {settings.GEMINI_MODEL} | Error: GEMINI_API_KEY is unconfigured and fallback mode is disabled.")
                    raise InferenceException("GEMINI_API_KEY is unconfigured and fallback mode is disabled.")
                answer = self._generate_local_fallback(payload.query, results)
            else:
                try:
                    logger.info(f"Gemini Request | Model: {settings.GEMINI_MODEL} | Prompt Length: {len(prompt)} characters")
                    response = self.llm.invoke(prompt)
                    logger.info("Gemini Response | Status: 200 OK | Success")
                    answer = response.content
                except Exception as api_err:
                    logger.error(f"Gemini Request Failed | Complete Exception: {str(api_err)}", exc_info=True)
                    if not settings.ENABLE_FALLBACK:
                        raise InferenceException(f"Gemini API failure: {str(api_err)}")
                    answer = self._generate_local_fallback(payload.query, results)
                    
            return KnowledgeResponse(answer=answer, sources=sources)
            
        except Exception as e:
            logger.error(f"RAG query execution failed: {str(e)}")
            raise InferenceException(f"Failed to process knowledge query: {str(e)}")

    def _generate_local_fallback(self, query: str, results) -> str:
        # Fallback summarizes retrieved context when API key is missing
        logger.info("Executing local fallback rule summarizing top retrieved context document chunks.")
        
        # Compile relevant sentences from retrieved chunks
        best_doc, score = results[0]
        source_name = best_doc.metadata.get("source", "manuals")
        
        summary = (
            f"[Grounded Service Advisor Response (Local Fallback - Key Missing)]\n\n"
            f"Based on the closest reference manual ({source_name}), here is the indexed procedure:\n"
            f"{best_doc.page_content}\n\n"
            f"Ensure to check these guidelines. Let me know if you want to book a mechanic for further repairs."
        )
        return summary

# Singleton Service Instance
rag_service = RAGService()
