from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional
import logging
import os
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from rag import retrieve_context, generate_response, load_initial_knowledge

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global variable to track if knowledge base has been loaded
knowledge_base_loaded = False

# Request/Response Models
class PromptRequest(BaseModel):
    """Request model for prompt endpoint"""
    prompt: str = Field(..., min_length=1, max_length=5000, description="The user's prompt or question")
    top_k: Optional[int] = Field(default=3, description="Number of top results to retrieve")
    include_context: Optional[bool] = Field(default=True, description="Include retrieved context in response")

class PromptResponse(BaseModel):
    """Response model for prompt endpoint"""
    prompt: str
    response: str
    context_used: str
    success: bool

class HealthResponse(BaseModel):
    """Response model for health check endpoint"""
    status: str
    knowledge_base_loaded: bool
    version: str

class ErrorResponse(BaseModel):
    """Error response model"""
    error: str
    success: bool

# Initialize FastAPI app with lifespan
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown"""
    # Startup
    global knowledge_base_loaded
    try:
        logger.info("Loading knowledge base at application startup...")
        load_initial_knowledge(os.getenv("KB_DATA_FOLDER", "data"))
        knowledge_base_loaded = True
        logger.info("Knowledge base loaded successfully!")
    except Exception as e:
        logger.error(f"Error loading knowledge base at startup: {str(e)}")
        knowledge_base_loaded = True  # Set to True to prevent repeated attempts
    
    yield
    
    # Shutdown
    logger.info("Application shutting down...")

# Create FastAPI app
app = FastAPI(
    title=os.getenv("API_TITLE", "RAG GenAI API"),
    description=os.getenv("API_DESCRIPTION", "Retrieval-Augmented Generation API powered by GenAI"),
    version=os.getenv("API_VERSION", "1.0.0"),
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Add CORS middleware
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Health check endpoint for monitoring and load balancers"""
    return HealthResponse(
        status="healthy",
        knowledge_base_loaded=knowledge_base_loaded,
        version=os.getenv("API_VERSION", "1.0.0")
    )

@app.post("/api/prompt", response_model=PromptResponse, tags=["RAG"])
async def prompt_handler(request: PromptRequest) -> PromptResponse:
    """
    Process a prompt and return AI-generated response with RAG context
    
    This endpoint:
    1. Takes a user prompt
    2. Retrieves relevant context from the knowledge base
    3. Generates a response using the LLM with RAG context
    4. Returns the response with context information
    """
    try:
        if not request.prompt or not request.prompt.strip():
            raise HTTPException(
                status_code=400,
                detail="Prompt must be a non-empty string"
            )
        
        logger.info(f"Processing prompt: {request.prompt[:100]}...")
        
        # Retrieve context from knowledge base
        context = retrieve_context(request.prompt, top_k=request.top_k)
        logger.info(f"Retrieved context length: {len(context)} characters")
        
        # Generate response using LLM with RAG context
        response = generate_response(request.prompt, context)
        logger.info(f"Generated response length: {len(response)} characters")
        
        return PromptResponse(
            prompt=request.prompt,
            response=response,
            context_used=context if context.strip() else "No relevant context found",
            success=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing prompt: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@app.post("/api/reload-knowledge-base", tags=["Knowledge Base"])
async def reload_knowledge_base():
    """Endpoint to manually reload the knowledge base"""
    global knowledge_base_loaded
    try:
        logger.info("Manually reloading knowledge base...")
        load_initial_knowledge(os.getenv("KB_DATA_FOLDER", "data"))
        knowledge_base_loaded = True
        logger.info("Knowledge base reloaded successfully!")
        return {
            "message": "Knowledge base reloaded successfully",
            "success": True
        }
    except Exception as e:
        logger.error(f"Error reloading knowledge base: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to reload knowledge base: {str(e)}"
        )

@app.get("/api/status", tags=["Status"])
async def get_status():
    """Get API status and configuration"""
    return {
        "service": os.getenv("API_TITLE", "RAG GenAI API"),
        "version": os.getenv("API_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development"),
        "llm_provider": os.getenv("LLM_PROVIDER", "3"),
        "knowledge_base_loaded": knowledge_base_loaded,
        "docs_url": "/api/docs"
    }

# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint - API information"""
    return {
        "message": "RAG GenAI API",
        "version": os.getenv("API_VERSION", "1.0.0"),
        "documentation": "/api/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    import uvicorn
    
    app_host = os.getenv("APP_HOST", "0.0.0.0")
    app_port = int(os.getenv("APP_PORT", "5000"))
    debug_mode = os.getenv("APP_ENV", "development") == "development"
    
    logger.info(f"Starting RAG GenAI API on {app_host}:{app_port}")
    
    uvicorn.run(
        "app:app",
        host=app_host,
        port=app_port,
        reload=debug_mode,
        log_level=os.getenv("LOG_LEVEL", "info").lower()
    )