# API Reference - RAG GenAI API

## Overview

The RAG GenAI API is a FastAPI-based REST API that provides retrieval-augmented generation capabilities for intelligent query processing.

**Base URL**: `http://<host>:<port>` (default: `http://localhost:5000`)

**API Documentation**: `/api/docs` (Swagger UI)

**Alternative Documentation**: `/api/redoc` (ReDoc)

---

## Endpoints

### 1. Health Check

Check if the API is running and knowledge base is loaded.

**Endpoint:**
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "knowledge_base_loaded": true,
  "version": "1.0.0"
}
```

**Status Codes:**
- `200 OK` - Service is healthy

---

### 2. Process Prompt (Main Endpoint)

Process a user prompt and get AI-generated response with retrieved context.

**Endpoint:**
```http
POST /api/prompt
```

**Content-Type:**
```
application/json
```

**Request Body:**
```json
{
  "prompt": "What is the process for payment settlement?",
  "top_k": 3,
  "include_context": true
}
```

**Parameters:**
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `prompt` | string | Yes | - | User question or prompt (1-5000 characters) |
| `top_k` | integer | No | 3 | Number of relevant documents to retrieve |
| `include_context` | boolean | No | true | Include retrieved context in response |

**Response (Success):**
```json
{
  "prompt": "What is the process for payment settlement?",
  "response": "Based on our payment processes, settlement occurs within 24-48 hours...",
  "context_used": "Payment settlement is processed daily at 2 PM UTC...",
  "success": true
}
```

**Status Codes:**
- `200 OK` - Request processed successfully
- `400 Bad Request` - Invalid prompt (empty or too long)
- `500 Internal Server Error` - Processing error

**Example cURL:**
```bash
curl -X POST http://localhost:5000/api/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "How do I process a refund?",
    "top_k": 5
  }'
```

**Example Python:**
```python
import requests

url = "http://localhost:5000/api/prompt"
payload = {
    "prompt": "How do I process a refund?",
    "top_k": 3
}

response = requests.post(url, json=payload)
print(response.json())
```

---

### 3. Reload Knowledge Base

Manually reload the knowledge base from the configured data folder.

**Endpoint:**
```http
POST /api/reload-knowledge-base
```

**Response (Success):**
```json
{
  "message": "Knowledge base reloaded successfully",
  "success": true
}
```

**Status Codes:**
- `200 OK` - Knowledge base reloaded
- `500 Internal Server Error` - Reload failed

**Example cURL:**
```bash
curl -X POST http://localhost:5000/api/reload-knowledge-base
```

---

### 4. Get Status

Get detailed API status and configuration information.

**Endpoint:**
```http
GET /api/status
```

**Response:**
```json
{
  "service": "RAG GenAI API",
  "version": "1.0.0",
  "environment": "production",
  "llm_provider": "3",
  "knowledge_base_loaded": true,
  "docs_url": "/api/docs"
}
```

**Example cURL:**
```bash
curl http://localhost:5000/api/status
```

---

### 5. Root Endpoint

Get API information and links.

**Endpoint:**
```http
GET /
```

**Response:**
```json
{
  "message": "RAG GenAI API",
  "version": "1.0.0",
  "documentation": "/api/docs",
  "health": "/health"
}
```

---

## Response Models

### PromptResponse

Standard response for prompt processing.

```json
{
  "prompt": "string (user input)",
  "response": "string (AI-generated response)",
  "context_used": "string (retrieved context)",
  "success": "boolean"
}
```

### HealthResponse

Health check response.

```json
{
  "status": "string (e.g., 'healthy')",
  "knowledge_base_loaded": "boolean",
  "version": "string (e.g., '1.0.0')"
}
```

### ErrorResponse

Error response.

```json
{
  "error": "string (error message)",
  "success": false
}
```

---

## Error Handling

### Common Error Responses

**400 Bad Request**
```json
{
  "detail": "Prompt must be a non-empty string"
}
```

**500 Internal Server Error**
```json
{
  "detail": "Internal server error: [error message]"
}
```

---

## Authentication

Currently, the API is open without authentication. For production deployments, consider:

- API Key authentication
- OAuth 2.0
- JWT tokens
- Google Cloud IAM (for GCP deployments)

---

## Rate Limiting

No built-in rate limiting is currently configured. For production, consider:

- API Gateway rate limiting
- Cloud Run quotas
- Kubernetes NetworkPolicy

---

## CORS Configuration

Cross-Origin Resource Sharing (CORS) is configured for the following origins (configurable via `.env`):
- `http://localhost:3000`
- `http://localhost:5000`

---

## Example Workflows

### Workflow 1: Simple Query

```bash
# 1. Check health
curl http://localhost:5000/health

# 2. Process a prompt
curl -X POST http://localhost:5000/api/prompt \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What are the payment methods?"}'

# 3. Check status
curl http://localhost:5000/api/status
```

### Workflow 2: Python Application

```python
import requests

class RAGClient:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
    
    def is_healthy(self):
        resp = requests.get(f"{self.base_url}/health")
        return resp.json()["status"] == "healthy"
    
    def ask(self, prompt, top_k=3):
        payload = {
            "prompt": prompt,
            "top_k": top_k
        }
        resp = requests.post(
            f"{self.base_url}/api/prompt",
            json=payload
        )
        return resp.json()
    
    def reload_kb(self):
        resp = requests.post(f"{self.base_url}/api/reload-knowledge-base")
        return resp.json()

# Usage
client = RAGClient()

if client.is_healthy():
    response = client.ask("How do I make a payment?")
    print(response["response"])
```

---

## Performance Tips

1. **Batch Requests**: Use reasonable `top_k` values (3-5)
2. **Chunk Size**: Larger chunks reduce latency but may reduce precision
3. **Caching**: Implement client-side caching for repeated queries
4. **Async Processing**: Use async operations for high-throughput scenarios

---

## Monitoring

### Key Metrics to Monitor

- **Response Time**: Latency of `/api/prompt` endpoint
- **Error Rate**: Percentage of failed requests
- **Knowledge Base Load Time**: Time to load KB on startup
- **CPU/Memory Usage**: Container resource utilization
- **Request Volume**: Requests per second

### Logging

All requests and errors are logged with:
- Timestamp
- Request ID (if available)
- Endpoint
- Status code
- Error message (if applicable)

---

## Testing the API

### Using Swagger UI

1. Navigate to `http://localhost:5000/api/docs`
2. Click on endpoint
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"

### Using cURL

See examples in each endpoint section.

### Using Postman

1. Create new POST request
2. URL: `http://localhost:5000/api/prompt`
3. Body (JSON):
   ```json
   {
     "prompt": "Your question here"
   }
   ```
4. Send request

---

## Versioning

Current API Version: **1.0.0**

Future versions will be available at:
- `/v1/` for v1.x.x
- `/v2/` for v2.x.x (when released)

---

## Support

For API issues:
1. Check health endpoint: `/health`
2. Review logs: `docker logs` or `kubectl logs`
3. Enable debug mode: `LOG_LEVEL=DEBUG`
4. Create GitHub issue with details

---

**Last Updated**: May 2026  
**API Version**: 1.0.0
