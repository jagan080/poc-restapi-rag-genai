#!/usr/bin/env bash
# Quick Reference - Deployment Commands
# This file contains quick copy-paste commands for deployment

# ============================================
# SETUP - Run Once
# ============================================

# Set your variables
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export CLUSTER_NAME="rag-genai-cluster"
export ZONE="us-central1-a"

# Enable Google Cloud APIs
gcloud services enable run.googleapis.com container.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com

# Create secrets
gcloud secrets create huggingface-api-key --replication-policy="automatic"
echo -n "your-api-key" | gcloud secrets versions add huggingface-api-key --data-file=-

# ============================================
# LOCAL DEVELOPMENT
# ============================================

# Create virtual environment
python -m venv myvenv
source myvenv/bin/activate

# Install dependencies
pip install -r code/src/requirements.txt

# Configure environment
cp .env.example code/src/.env
# Edit .env with your values
vim code/src/.env

# Run application
cd code/src
python app.py

# Access API
# Browser: http://localhost:5000/api/docs
# Health: curl http://localhost:5000/health
# Test: curl -X POST http://localhost:5000/api/prompt -H "Content-Type: application/json" -d '{"prompt":"hello"}'

# ============================================
# DOCKER - Local Testing
# ============================================

# Build image
docker build -t rag-genai-api:latest code/src/

# Run container with .env file (Recommended)
docker run -p 5001:5000 \
  --env-file code/src/.env \
  rag-genai-api:latest

# Run container with volume mount for .env
docker run -p 5001:5000 \
  -v $(pwd)/code/src/.env:/app/.env \
  rag-genai-api:latest

# Run container with Ollama (using .env file)
# Make sure Ollama is running: ollama serve
docker run -p 5001:5000 \
  --env-file code/src/.env \
  rag-genai-api:latest

# View logs
docker logs -f <container-id>

# Push to Google Container Registry
docker tag rag-genai-api:latest gcr.io/$PROJECT_ID/rag-genai-api:latest
docker push gcr.io/$PROJECT_ID/rag-genai-api:latest

# ============================================
# CLOUD RUN - QUICK DEPLOY
# ============================================

# Deploy using script (recommended)
cd deploy/cloud-run
bash deploy-cloud-run.sh $PROJECT_ID $REGION

# Or manual deploy with environment variables from .env file
# Load env variables into shell
export $(cat code/src/.env | grep -v '^#' | xargs)

# Deploy to Cloud Run
gcloud run deploy rag-genai-api \
  --image gcr.io/$PROJECT_ID/rag-genai-api:latest \
  --region $REGION \
  --platform managed \
  --memory 2Gi \
  --cpu 1 \
  --allow-unauthenticated \
  --set-env-vars "LLM_PROVIDER=2,APP_HOST=0.0.0.0,APP_PORT=5000,LOG_LEVEL=INFO,RAG_TOP_K=3"

# Or use environment file with Cloud Run (store variables in Secret Manager first)
# 1. Create secrets for sensitive vars
gcloud secrets create llm-provider --data-file=- <<< "2"
gcloud secrets create app-port --data-file=- <<< "5000"

# 2. Deploy referencing secrets
gcloud run deploy rag-genai-api \
  --image gcr.io/$PROJECT_ID/rag-genai-api:latest \
  --region $REGION \
  --platform managed \
  --memory 2Gi \
  --set-secrets "LLM_PROVIDER=llm-provider:latest,APP_PORT=app-port:latest" \
  --set-env-vars "APP_HOST=0.0.0.0,LOG_LEVEL=INFO"

# ============================================
# GKE - QUICK DEPLOY
# ============================================

# Create cluster (one-time)
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --num-nodes 2 \
  --machine-type n1-standard-2 \
  --enable-autoscaling --min-nodes 2 --max-nodes 10

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Deploy using script
cd deploy/gke
bash deploy-gke.sh $PROJECT_ID $CLUSTER_NAME $ZONE

# Or manual deploy
sed -i "s|PROJECT_ID|$PROJECT_ID|g" deploy/gke/deployment.yaml
kubectl apply -f deploy/gke/deployment.yaml
kubectl apply -f deploy/gke/ingress.yaml

# Check deployment
kubectl get pods -n rag-genai
kubectl get svc -n rag-genai
kubectl rollout status deployment/rag-genai-api -n rag-genai

# View logs
kubectl logs -f deployment/rag-genai-api -n rag-genai

# Get external IP
kubectl get service rag-genai-api-service -n rag-genai -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Port-forward for local testing
kubectl port-forward -n rag-genai svc/rag-genai-api-service 5000:80

# Scale deployment
kubectl scale deployment rag-genai-api --replicas=5 -n rag-genai

# Delete deployment
kubectl delete namespace rag-genai

# Delete cluster
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE

# ============================================
# MONITORING & DEBUGGING
# ============================================

# Cloud Run logs
gcloud run logs read rag-genai-api --follow

# GKE pod logs
kubectl logs -f deployment/rag-genai-api -n rag-genai

# GKE describe pod
kubectl describe pod <pod-name> -n rag-genai

# GKE events
kubectl get events -n rag-genai

# Check resource usage
kubectl top pods -n rag-genai
kubectl top nodes

# GKE shell access to container
kubectl exec -it <pod-name> -n rag-genai -- /bin/bash

# ============================================
# UPDATES & MAINTENANCE
# ============================================

# Update knowledge base
kubectl port-forward -n rag-genai svc/rag-genai-api-service 5000:80
curl -X POST http://localhost:5000/api/reload-knowledge-base

# Update deployment image
kubectl set image deployment/rag-genai-api \
  rag-genai-api=gcr.io/$PROJECT_ID/rag-genai-api:v2 \
  -n rag-genai

# Rollback deployment
kubectl rollout undo deployment/rag-genai-api -n rag-genai

# ============================================
# TESTING THE API
# ============================================

# Get base URL
SERVICE_URL="http://localhost:5000"

# Health check
curl $SERVICE_URL/health

# Test prompt
curl -X POST $SERVICE_URL/api/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is the payment process?",
    "top_k": 3
  }'

# Reload knowledge base
curl -X POST $SERVICE_URL/api/reload-knowledge-base

# Get status
curl $SERVICE_URL/api/status

# ============================================
# CLEANUP
# ============================================

# Delete all GCP resources
gcloud run services delete rag-genai-api --region $REGION --quiet
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE --quiet

# Delete Cloud Run
gcloud run services delete rag-genai-api --region $REGION

# Delete GKE cluster
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE

# Delete container images
gcloud container images delete gcr.io/$PROJECT_ID/rag-genai-api:latest

# ============================================
# TIPS
# ============================================

# Save output to variable
SERVICE_URL=$(gcloud run services describe rag-genai-api --region $REGION --format 'value(status.url)')
echo $SERVICE_URL

# Use environment file for commands
source deploy/cloud-run/deploy-cloud-run.sh

# Watch deployment progress
kubectl get pods -n rag-genai -w

# Check pod IP addresses
kubectl get pods -n rag-genai -o wide

# Get pod details
kubectl get pod <pod-name> -n rag-genai -o yaml

# Check HPA status
kubectl get hpa -n rag-genai

# Check storage
kubectl get pvc -n rag-genai
kubectl get pv

# View resource requests/limits
kubectl describe node <node-name>
