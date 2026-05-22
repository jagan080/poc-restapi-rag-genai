#!/bin/bash
# Cloud Run Deployment Script
# Usage: bash deploy-cloud-run.sh <PROJECT_ID> <REGION>

set -e

PROJECT_ID=${1:-}
REGION=${2:-us-central1}
SERVICE_NAME="rag-genai-api"
IMAGE_NAME="rag-genai-api"

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: bash deploy-cloud-run.sh <PROJECT_ID> <REGION>"
    echo "Example: bash deploy-cloud-run.sh my-gcp-project us-central1"
    exit 1
fi

echo "================================================"
echo "Deploying RAG GenAI API to Google Cloud Run"
echo "================================================"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"

# Build the Docker image
echo "Step 1: Building Docker image..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$(date +%Y%m%d-%H%M%S) code/src/

# Push to Google Container Registry
echo "Step 2: Pushing image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest

# Deploy to Cloud Run
echo "Step 3: Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
    --platform managed \
    --region $REGION \
    --project $PROJECT_ID \
    --memory 2Gi \
    --cpu 1 \
    --timeout 300 \
    --set-env-vars "APP_ENV=production,LLM_PROVIDER=3,LOG_LEVEL=INFO" \
    --allow-unauthenticated \
    --max-instances 100

echo "================================================"
echo "Deployment completed successfully!"
echo "================================================"
echo ""
echo "Service URL:"
gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT_ID \
    --format 'value(status.url)'

echo ""
echo "View logs:"
echo "gcloud run logs read $SERVICE_NAME --limit 50 --region $REGION --project $PROJECT_ID"
