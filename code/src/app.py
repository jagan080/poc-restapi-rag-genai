from flask import Flask, request, jsonify
from rag import retrieve_context, generate_response, load_initial_knowledge
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Global variable to track if knowledge base has been loaded
knowledge_base_loaded = False

@app.before_request
def load_knowledge_base_once():
    """Load the knowledge base only once when the app starts"""
    global knowledge_base_loaded
    if not knowledge_base_loaded:
        try:
            logger.info("Loading knowledge base at application startup...")
            load_initial_knowledge("data")
            knowledge_base_loaded = True
            logger.info("Knowledge base loaded successfully!")
        except Exception as e:
            logger.error(f"Error loading knowledge base: {str(e)}")
            knowledge_base_loaded = True  # Set to True to prevent repeated attempts

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "knowledge_base_loaded": knowledge_base_loaded
    }), 200

@app.route('/api/prompt', methods=['POST'])
def prompt_handler():
    """
    POST endpoint to send a prompt and get response from LLM or RAG
    
    Request JSON format:
    {
        "prompt": "Your question or prompt here"
    }
    
    Response JSON format:
    {
        "prompt": "Your original prompt",
        "response": "AI-generated response",
        "context_used": "Context retrieved from knowledge base",
        "success": true
    }
    """
    try:
        # Get JSON data from request
        data = request.get_json()
        
        if not data or "prompt" not in data:
            return jsonify({
                "error": "Missing 'prompt' field in request body",
                "success": False
            }), 400
        
        prompt = data.get("prompt")
        
        if not isinstance(prompt, str) or not prompt.strip():
            return jsonify({
                "error": "Prompt must be a non-empty string",
                "success": False
            }), 400
        
        logger.info(f"Processing prompt: {prompt[:100]}...")
        
        # Retrieve context from knowledge base
        context = retrieve_context(prompt)
        logger.info(f"Retrieved context length: {len(context)} characters")
        
        # Generate response using LLM with RAG context
        response = generate_response(prompt, context)
        logger.info(f"Generated response length: {len(response)} characters")
        
        return jsonify({
            "prompt": prompt,
            "response": response,
            "context_used": context if context.strip() else "No relevant context found",
            "success": True
        }), 200
        
    except Exception as e:
        logger.error(f"Error processing prompt: {str(e)}")
        return jsonify({
            "error": f"Internal server error: {str(e)}",
            "success": False
        }), 500

@app.route('/api/reload-knowledge-base', methods=['POST'])
def reload_knowledge_base():
    """Endpoint to manually reload the knowledge base"""
    try:
        logger.info("Manually reloading knowledge base...")
        load_initial_knowledge("data")
        logger.info("Knowledge base reloaded successfully!")
        return jsonify({
            "message": "Knowledge base reloaded successfully",
            "success": True
        }), 200
    except Exception as e:
        logger.error(f"Error reloading knowledge base: {str(e)}")
        return jsonify({
            "error": f"Failed to reload knowledge base: {str(e)}",
            "success": False
        }), 500

if __name__ == "__main__":
    # Load knowledge base on startup
    try:
        logger.info("Starting Flask application...")
        logger.info("Loading initial knowledge base...")
        load_initial_knowledge()
        knowledge_base_loaded = True
        logger.info("Knowledge base loaded successfully at startup!")
    except Exception as e:
        logger.error(f"Failed to load knowledge base at startup: {str(e)}")
    
    # Run Flask app
    app.run(host="0.0.0.0", port=5001, debug=False)