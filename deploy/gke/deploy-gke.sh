#!/bin/bash
# GKE Deployment Script
# Usage: bash deploy-gke.sh <PROJECT_ID> <CLUSTER_NAME> <CLUSTER_ZONE>

set -e

PROJECT_ID=${1:-}
CLUSTER_NAME=${2:-}
CLUSTER_ZONE=${3:-us-central1-a}
IMAGE_NAME="rag-genai-api"
NAMESPACE="rag-genai"

if [ -z "$PROJECT_ID" ] || [ -z "$CLUSTER_NAME" ]; then
    echo "Usage: bash deploy-gke.sh <PROJECT_ID> <CLUSTER_NAME> <CLUSTER_ZONE>"
    echo "Example: bash deploy-gke.sh my-project my-cluster us-central1-a"
    exit 1
fi

echo "================================================"
echo "Deploying RAG GenAI API to Google Kubernetes Engine"
echo "================================================"
echo "Project ID: $PROJECT_ID"
echo "Cluster Name: $CLUSTER_NAME"
echo "Zone: $CLUSTER_ZONE"

# Set the project
echo "Step 1: Setting GCP project..."
gcloud config set project $PROJECT_ID

# Get cluster credentials
echo "Step 2: Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID

# Build the Docker image
echo "Step 3: Building Docker image..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$(date +%Y%m%d-%H%M%S) code/src/

# Push to Google Container Registry
echo "Step 4: Pushing image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest

# Update image reference in deployment.yaml
echo "Step 5: Updating image reference in Kubernetes manifests..."
sed -i.bak "s|gcr.io/PROJECT_ID/rag-genai-api|gcr.io/$PROJECT_ID/rag-genai-api|g" deploy/gke/deployment.yaml

# Create namespace
echo "Step 6: Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply Kubernetes manifests
echo "Step 7: Applying Kubernetes manifests..."
kubectl apply -f deploy/gke/deployment.yaml

# Wait for deployment to be ready
echo "Step 8: Waiting for deployment to be ready (this may take a few minutes)..."
kubectl rollout status deployment/rag-genai-api -n $NAMESPACE --timeout=5m

# Get service information
echo ""
echo "================================================"
echo "Deployment completed successfully!"
echo "================================================"
echo ""
echo "Service Information:"
kubectl get service -n $NAMESPACE -o wide

echo ""
echo "Pod Information:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "Deployment Status:"
kubectl describe deployment rag-genai-api -n $NAMESPACE

echo ""
echo "View logs:"
echo "kubectl logs -f deployment/rag-genai-api -n $NAMESPACE"

echo ""
echo "Access the API:"
EXTERNAL_IP=$(kubectl get svc rag-genai-api-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")
if [ "$EXTERNAL_IP" != "PENDING" ]; then
    echo "API URL: http://$EXTERNAL_IP:5000"
    echo "API Docs: http://$EXTERNAL_IP:5000/api/docs"
else
    echo "External IP is pending. Check status with: kubectl get svc -n $NAMESPACE"
fi
