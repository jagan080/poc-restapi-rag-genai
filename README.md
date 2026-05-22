# 🚀 RAG GenAI API

## 📖 Table of Contents
- [Introduction](#introduction)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
  - [Local Development](#local-development)
  - [Docker Deployment](#docker-deployment)
  - [Google Cloud Run](#google-cloud-run)
  - [Google Kubernetes Engine (GKE)](#google-kubernetes-engine-gke)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Introduction

**RAG GenAI API** is an advanced Retrieval-Augmented Generation (RAG) powered API that combines:
- **Vector-based document retrieval** for context-aware responses
- **Multiple LLM provider support** (Ollama, Google Vertex AI)
- **Production-ready deployment** options (Cloud Run, GKE)
- **Interactive API documentation** with Swagger UI
- **Comprehensive logging and monitoring**

This API is designed for platform support teams to streamline knowledge management and automate context-aware responses.

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   FastAPI Web Server                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Endpoints:                                        │     │
│  │  • POST /api/prompt - Process queries              │     │
│  │  • GET  /health - Health check                     │     │
│  │  • POST /api/reload-knowledge-base - Reload KB     │     │
│  │  • GET  /api/docs - Swagger UI                     │     │
│  └────────────────────────────────────────────────────┘     │
└──────────┬──────────────────────────────────────────────────┘
           │
    ┌──────┴──────────────────────────┐
    │                                  │
    ▼                                  ▼
┌─────────────────────┐    ┌──────────────────────┐
│  ChromaDB           │    │  RAG Engine          │
│  (Vector Store)     │    │  ┌────────────────┐  │
│  - Documents        │    │  │ Text Splitting │  │
│  - Embeddings       │    │  ├────────────────┤  │
│  - Vector Search    │    │  │ Embeddings     │  │
│                     │    │  ├────────────────┤  │
│                     │    │  │ Context Ret.   │  │
│                     │    │  └────────────────┘  │
└─────────────────────┘    └──────────────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────┐
                        │  LLM Backends            │
                        │  • Ollama (Local)        │
                        │  • Vertex AI Gemini      │
                        └──────────────────────────┘
```

### Data Flow

1. **User Query** → FastAPI endpoint
2. **Query Embedding** → SentenceTransformer
3. **Vector Search** → ChromaDB retrieves relevant documents
4. **Context Augmentation** → Combine query with retrieved context
5. **LLM Processing** → Generate response using selected backend
6. **Response** → Return to client with context and answer

---

## ✨ Features

- ✅ **Multi-LLM Support**: Ollama, Google Vertex AI
- ✅ **Vector-based RAG**: Semantic search with ChromaDB
- ✅ **Swagger/OpenAPI Documentation**: Interactive API explorer at `/api/docs`
- ✅ **Multiple File Format Support**: PDF, JSON, DOCX, TXT, Excel
- ✅ **Production-ready**: Health checks, logging, error handling
- ✅ **Scalable Deployment**: Cloud Run, GKE, Docker
- ✅ **Environment Configuration**: .env-based configuration
- ✅ **Auto-scaling**: HPA support for Kubernetes
- ✅ **Security**: Non-root user, RBAC, secret management

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | FastAPI 0.104.1 |
| **Server** | Uvicorn 0.24.0 |
| **Vector Database** | ChromaDB 1.5.9 |
| **Embeddings** | SentenceTransformers (all-MiniLM-L6-v2) |
| **LLMs** | Ollama, Vertex AI |
| **Document Processing** | PyMuPDF, python-docx, pandas |
| **Container** | Docker |
| **Orchestration** | Kubernetes (GKE) |
| **Cloud** | Google Cloud Platform |
| **Config** | python-dotenv, pydantic |

---

## 🚀 Quick Start

### Prerequisites

- Python 3.13+
- Docker (for containerized deployment)
- Google Cloud Project (for cloud deployment)
- Virtual environment (venv or conda)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd poc-restapi-rag-genai
   ```

2. **Create virtual environment**
   ```bash
   python -m venv myvenv
   source myvenv/bin/activate  # On Windows: myvenv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r code/src/requirements.txt
   ```

4. **Configure environment**
   ```bash
   cp .env.example code/src/.env
   # Edit .env with your configuration
   vim code/src/.env
   ```

5. **Prepare knowledge base**
   ```bash
   # Place your documents in code/src/data/
   # Supported formats: PDF, JSON, DOCX, TXT, Excel
   ```

6. **Run the application**
   ```bash
   cd code/src
   python app.py
   # or
   uvicorn app:app --host 0.0.0.0 --port 5000
   ```

7. **Access the API**
   - Swagger UI: http://localhost:5000/api/docs
   - Health Check: http://localhost:5000/health
   - API: http://localhost:5000/api/prompt

---

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in `code/src/` directory:

```env
# LLM Provider (2=Ollama, 3=Vertex AI)
LLM_PROVIDER=3

# API Configuration
APP_ENV=production
APP_HOST=0.0.0.0
APP_PORT=5000
LOG_LEVEL=INFO

# Google Cloud
GOOGLE_CLOUD_PROJECT=your-project-id
VERTEX_AI_LOCATION=us-central1

# RAG Configuration
RAG_TOP_K=3
RAG_SIMILARITY_THRESHOLD=0.5
TEXT_CHUNK_SIZE=500
TEXT_CHUNK_OVERLAP=50

# ChromaDB
CHROMA_DB_PATH=./chroma_db
CHROMA_COLLECTION_NAME=rag_docs

# Knowledge Base
KB_DATA_FOLDER=./data
KB_AUTO_RELOAD=True
```

See `.env.example` for all available options.

---

## 📚 API Documentation

### Swagger UI

Access interactive documentation at:
```
http://<host>:<port>/api/docs
```

Features:
- Try out endpoints directly
- View request/response schemas
- Test with real parameters
- See error responses

### ReDoc

Alternative documentation at:
```
http://<host>:<port>/api/redoc
```

---

## 🌐 Deployment

### Docker Deployment

1. **Build Docker image**
   ```bash
   docker build -t rag-genai-api:latest code/src/
   ```

2. **Run container**
   ```bash
   docker run \
     -p 5000:5000 \
     -e LLM_PROVIDER=3 \
     -e GOOGLE_CLOUD_PROJECT=your-project \
     -v /path/to/data:/app/data \
     -v /path/to/service-account-key.json:/app/key.json \
     rag-genai-api:latest
   ```

### Google Cloud Run

#### Prerequisites
- Google Cloud Project
- gcloud CLI configured
- Docker installed

#### Deployment Steps

1. **Configure your settings**
   ```bash
   cd deploy/cloud-run
   export PROJECT_ID="your-gcp-project-id"
   export REGION="us-central1"
   ```

2. **Deploy using script**
   ```bash
   bash deploy-cloud-run.sh $PROJECT_ID $REGION
   ```

3. **Or deploy manually**
   ```bash
   gcloud run deploy rag-genai-api \
     --source . \
     --region $REGION \
     --platform managed \
     --memory 2Gi \
     --cpu 1 \
     --set-env-vars "LLM_PROVIDER=3"
   ```

#### Verify Deployment
```bash
gcloud run services describe rag-genai-api --region $REGION
gcloud run logs read rag-genai-api --limit 50
```

### Google Kubernetes Engine (GKE)

#### Prerequisites
- GKE cluster created
- kubectl configured
- Docker image in Google Container Registry

#### Deployment Steps

1. **Create cluster (if not exists)**
   ```bash
   gcloud container clusters create rag-genai-cluster \
     --zone us-central1-a \
     --num-nodes 2 \
     --machine-type n1-standard-2 \
     --enable-autoscaling \
     --min-nodes 2 \
     --max-nodes 10
   ```

2. **Create secrets**
   ```bash
   # Create namespace
   kubectl create namespace rag-genai

   # Create service account key secret
   kubectl create secret generic google-cloud-key \
     -n rag-genai \
     --from-file=key.json=/path/to/service-account-key.json

   # Create configuration data
   kubectl create configmap rag-data-config \
     -n rag-genai \
     --from-file=data/
   ```

3. **Deploy using script**
   ```bash
   cd deploy/gke
   bash deploy-gke.sh $PROJECT_ID $CLUSTER_NAME $CLUSTER_ZONE
   ```

4. **Or deploy manually**
   ```bash
   # Update image reference
   sed -i "s|PROJECT_ID|your-gcp-project-id|g" deployment.yaml
   
   # Apply manifests
   kubectl apply -f deployment.yaml
   kubectl apply -f ingress.yaml

   # Verify deployment
   kubectl get pods -n rag-genai
   kubectl get services -n rag-genai
   ```

#### Monitor Deployment
```bash
# Check pod status
kubectl get pods -n rag-genai -w

# View logs
kubectl logs -f deployment/rag-genai-api -n rag-genai

# Check autoscaling
kubectl get hpa -n rag-genai

# Describe deployment
kubectl describe deployment rag-genai-api -n rag-genai
```

---

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Response:
```json
{
  "status": "healthy",
  "knowledge_base_loaded": true,
  "version": "1.0.0"
}
```

### Process Prompt
```http
POST /api/prompt
Content-Type: application/json

{
  "prompt": "Your question here",
  "top_k": 3,
  "include_context": true
}
```

Response:
```json
{
  "prompt": "Your question here",
  "response": "AI-generated response",
  "context_used": "Retrieved context from knowledge base",
  "success": true
}
```

### Reload Knowledge Base
```http
POST /api/reload-knowledge-base
```

### Get Status
```http
GET /api/status
```

---

## 📊 Monitoring and Logging

### View Logs

**Local:**
```bash
tail -f logs/app.log
```

**Docker:**
```bash
docker logs -f <container-id>
```

**Cloud Run:**
```bash
gcloud run logs read rag-genai-api
```

**Kubernetes:**
```bash
kubectl logs -f deployment/rag-genai-api -n rag-genai
```

### Metrics

Monitor resource usage:
```bash
# GKE
kubectl top pods -n rag-genai
kubectl top nodes
```

---

## 🐛 Troubleshooting

### Common Issues

**1. PDF Extraction Error: "bad stream: type(stream)=<class 'str'>'"**
- ✅ Fixed in the code
- Ensure `fitz.open()` receives file path (string) or bytes, not both

**2. Knowledge Base Not Loading**
- Check data folder path in `.env`
- Verify file permissions
- Check log output for specific errors

**3. LLM Connection Issues**
- Verify API keys in `.env`
- Check internet connection
- Test provider connectivity separately

**4. Out of Memory**
- Reduce `TEXT_CHUNK_SIZE` in `.env`
- Increase container memory limits
- Use smaller embedding model

### Debug Mode

Enable debug logging:
```bash
export LOG_LEVEL=DEBUG
python app.py
```

---

## 📝 File Structure

```
poc-restapi-rag-genai/
├── code/src/
│   ├── app.py                    # FastAPI application
│   ├── rag.py                    # RAG engine logic
│   ├── agent_setup.py            # Agent configuration
│   ├── mock_actions.py           # Mock actions for testing
│   ├── requirements.txt          # Python dependencies
│   ├── Dockerfile               # Container definition
│   └── data/                    # Knowledge base documents
│       ├── banking_payment_guide.txt
│       ├── banking_payment_processes.json
│       └── telemertry.json
├── deploy/
│   ├── cloud-run/
│   │   ├── deploy-cloud-run.sh  # Cloud Run deployment script
│   │   └── service.yaml         # Cloud Run service config
│   └── gke/
│       ├── deploy-gke.sh        # GKE deployment script
│       ├── deployment.yaml      # K8s deployment manifest
│       └── ingress.yaml         # K8s ingress config
├── .env.example                 # Example environment variables
├── README.md                    # This file
└── LICENSE
```

---

## 🔐 Security Best Practices

- ✅ Use non-root user in containers
- ✅ Manage secrets via Google Secret Manager
- ✅ Enable RBAC in Kubernetes
- ✅ Use service accounts
- ✅ Enable network policies
- ✅ Regular dependency updates
- ✅ Input validation on all endpoints
- ✅ CORS configuration for API access

---

## 📦 Scaling Considerations

### Horizontal Scaling
- GKE: HPA automatically scales to 10 replicas based on CPU/memory
- Cloud Run: Auto-scales to 100 instances
- Database: ChromaDB is replicated across pods using PVC

### Performance Optimization
- Response caching enabled in GKE Ingress
- Connection pooling for database access
- Batch processing for large queries

### Resource Requirements

| Environment | CPU | Memory |
|------------|-----|--------|
| Development | 500m | 1Gi |
| Staging | 1000m | 2Gi |
| Production | 2000m | 4Gi |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 👥 Team

The AI Vengers - Platform Support Intelligence Platform

---

## 📞 Support

For issues, questions, or suggestions:
- Create a GitHub Issue
- Check existing documentation
- Review API logs and debug output

---

**Last Updated**: May 2026  
**API Version**: 1.0.0  
**Status**: Production Ready ✅
