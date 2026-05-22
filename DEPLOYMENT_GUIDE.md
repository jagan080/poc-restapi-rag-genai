# RAG GenAI API - Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the RAG GenAI API to:
1. **Google Cloud Run** (Serverless)
2. **Google Kubernetes Engine (GKE)** (Kubernetes)

---

## Prerequisites

### Common Requirements
- Google Cloud Project with billing enabled
- `gcloud` CLI installed and authenticated
- `kubectl` configured (for GKE)
- Docker installed locally
- Python 3.13+
- Service account with appropriate permissions

### GCP Permissions Required
```
- roles/run.admin (Cloud Run)
- roles/container.admin (GKE)
- roles/artifactregistry.admin (Container Registry)
- roles/secretmanager.secretAccessor (Secret Manager)
```

### Install gcloud CLI
```bash
# macOS
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash

# Initialize
gcloud init
gcloud auth login
```

---

## Part 1: Google Cloud Run Deployment (Serverless)

### What is Cloud Run?

Cloud Run is a managed compute platform that lets you run containers that are invoked via HTTP requests. It's fully serverless and auto-scales.

**Advantages:**
- ✅ No infrastructure management
- ✅ Pay only for execution time
- ✅ Auto-scales from 0 to 100+ instances
- ✅ Built-in monitoring and logging
- ✅ Easy SSL/TLS

**Disadvantages:**
- ❌ Request timeout: 60 minutes max
- ❌ Memory: 8GB max
- ❌ Startup time matters (cold starts)

### Step 1: Setup Google Cloud Project

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  container.googleapis.com
```

### Step 2: Create Secrets in Secret Manager

```bash
# Create secrets for sensitive data
gcloud secrets create huggingface-api-key \
  --replication-policy="automatic"

# Add the secret value (interactive)
echo -n "your-actual-api-key" | \
  gcloud secrets versions add huggingface-api-key --data-file=-

# Create GCP project secret
gcloud secrets create gcp-project-id \
  --replication-policy="automatic"

echo -n "$PROJECT_ID" | \
  gcloud secrets versions add gcp-project-id --data-file=-
```

### Step 3: Setup Container Registry

```bash
# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker gcr.io

# Create repository
gcloud artifacts repositories create rag-genai \
  --repository-format=docker \
  --location=$REGION
```

### Step 4: Build and Push Docker Image

```bash
# Navigate to source directory
cd code/src

# Build Docker image
docker build -t gcr.io/$PROJECT_ID/rag-genai-api:latest .

# Tag with timestamp
docker tag gcr.io/$PROJECT_ID/rag-genai-api:latest \
  gcr.io/$PROJECT_ID/rag-genai-api:$(date +%Y%m%d-%H%M%S)

# Push to Container Registry
docker push gcr.io/$PROJECT_ID/rag-genai-api:latest
```

### Step 5: Deploy to Cloud Run

**Option A: Using Deployment Script**

```bash
cd deploy/cloud-run
bash deploy-cloud-run.sh $PROJECT_ID $REGION
```

**Option B: Manual Deployment**

```bash
gcloud run deploy rag-genai-api \
  --image gcr.io/$PROJECT_ID/rag-genai-api:latest \
  --platform managed \
  --region $REGION \
  --memory 2Gi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 100 \
  --set-env-vars "APP_ENV=production,LLM_PROVIDER=3,LOG_LEVEL=INFO" \
  --set-secrets "HUGGINGFACE_API_KEY=huggingface-api-key:latest,GCP_PROJECT_ID=gcp-project-id:latest" \
  --allow-unauthenticated
```

### Step 6: Verify Deployment

```bash
# Get service URL
gcloud run services describe rag-genai-api \
  --region $REGION \
  --format 'value(status.url)'

# Test the API
SERVICE_URL=$(gcloud run services describe rag-genai-api \
  --region $REGION \
  --format 'value(status.url)')

curl $SERVICE_URL/health
curl $SERVICE_URL/api/docs
```

### Step 7: Monitor Deployment

```bash
# View recent logs
gcloud run logs read rag-genai-api --limit 50

# Stream logs in real-time
gcloud run logs read rag-genai-api --follow

# View deployment details
gcloud run services describe rag-genai-api --region $REGION
```

---

## Part 2: Google Kubernetes Engine (GKE) Deployment

### What is GKE?

Google Kubernetes Engine (GKE) is a managed Kubernetes service. It's ideal for complex applications needing fine-grained control and advanced orchestration.

**Advantages:**
- ✅ Full Kubernetes features
- ✅ Multi-container pods
- ✅ Persistent storage
- ✅ Advanced networking
- ✅ RBAC and service accounts
- ✅ Auto-scaling and load balancing

**Disadvantages:**
- ❌ More complex to manage
- ❌ Requires Kubernetes knowledge
- ❌ Minimum cost even when idle

### Step 1: Create GKE Cluster

```bash
export CLUSTER_NAME="rag-genai-cluster"
export ZONE="us-central1-a"

# Create cluster
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --num-nodes 2 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing \
  --workload-pool=$PROJECT_ID.svc.id.goog

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
```

### Step 2: Create Service Account and RBAC

```bash
# Create namespace
kubectl create namespace rag-genai

# Create service account
kubectl create serviceaccount rag-genai-sa -n rag-genai

# Create cluster role binding
kubectl create clusterrolebinding rag-genai-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=rag-genai:rag-genai-sa
```

### Step 3: Create Secrets

```bash
# Create secrets from Google Cloud Secret Manager
kubectl create secret generic google-cloud-key \
  -n rag-genai \
  --from-file=key.json=/path/to/service-account-key.json

# Create ConfigMap for application data
kubectl create configmap rag-data-config \
  -n rag-genai \
  --from-file=code/src/data/
```

### Step 4: Build and Push Docker Image

```bash
# Build image
docker build -t gcr.io/$PROJECT_ID/rag-genai-api:latest code/src/

# Push to registry
docker push gcr.io/$PROJECT_ID/rag-genai-api:latest
```

### Step 5: Update and Apply Kubernetes Manifests

```bash
cd deploy/gke

# Update image reference in manifests
sed -i "s|PROJECT_ID|$PROJECT_ID|g" deployment.yaml
sed -i "s|PROJECT_ID|$PROJECT_ID|g" ingress.yaml

# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml

# Verify deployment
kubectl get pods -n rag-genai
kubectl get svc -n rag-genai
kubectl get hpa -n rag-genai
```

### Step 6: Wait for Deployment

```bash
# Wait for all pods to be ready
kubectl rollout status deployment/rag-genai-api -n rag-genai

# Watch pod creation
kubectl get pods -n rag-genai -w

# Get service info
kubectl get svc rag-genai-api-service -n rag-genai
```

### Step 7: Configure Ingress (Optional)

```bash
# Get external IP
kubectl get ingress -n rag-genai

# Update your DNS records to point to the external IP
# Or use the provided IP directly
```

### Step 8: Monitor Deployment

```bash
# View logs
kubectl logs -f deployment/rag-genai-api -n rag-genai

# Check pod details
kubectl describe pod <pod-name> -n rag-genai

# View events
kubectl get events -n rag-genai

# Monitor resource usage
kubectl top pods -n rag-genai
kubectl top nodes
```

---

## Comparison: Cloud Run vs GKE

| Feature | Cloud Run | GKE |
|---------|-----------|-----|
| **Startup** | Quick | Slow |
| **Cost** | Pay per request | Always running |
| **Complexity** | Simple | Complex |
| **Scaling** | 0-100 | Custom (0-N) |
| **Storage** | Ephemeral | Persistent |
| **Networking** | Basic | Advanced |
| **Best For** | APIs, webhooks | Complex apps |

---

## Maintenance and Updates

### Update Application

**Cloud Run:**
```bash
# Rebuild and push new image
docker build -t gcr.io/$PROJECT_ID/rag-genai-api:v2 code/src/
docker push gcr.io/$PROJECT_ID/rag-genai-api:v2

# Deploy new version
gcloud run deploy rag-genai-api \
  --image gcr.io/$PROJECT_ID/rag-genai-api:v2 \
  --region $REGION
```

**GKE:**
```bash
# Update deployment image
kubectl set image deployment/rag-genai-api \
  rag-genai-api=gcr.io/$PROJECT_ID/rag-genai-api:v2 \
  -n rag-genai

# Monitor rollout
kubectl rollout status deployment/rag-genai-api -n rag-genai
```

### Scale Application

**Cloud Run:**
```bash
# Update max instances
gcloud run services update rag-genai-api \
  --max-instances 50 \
  --region $REGION
```

**GKE:**
```bash
# Update HPA
kubectl patch hpa rag-genai-api-hpa \
  -n rag-genai \
  -p '{"spec":{"maxReplicas":15}}'
```

### View Logs and Metrics

**Cloud Run:**
```bash
# Logs
gcloud run logs read rag-genai-api

# Metrics via Cloud Console
# https://console.cloud.google.com/run
```

**GKE:**
```bash
# Logs
kubectl logs -f deployment/rag-genai-api -n rag-genai

# Metrics
kubectl top pods -n rag-genai
```

---

## Cost Optimization

### Cloud Run
- Start with minimum settings, increase as needed
- Use 0.5 CPU for lower traffic
- Set `max-instances` appropriately

### GKE
- Use Preemptible VMs for dev/staging
- Enable cluster autoscaling
- Use pod resource requests/limits

---

## Security Checklist

- [ ] Enable RBAC on GKE
- [ ] Use service accounts with minimal permissions
- [ ] Store secrets in Secret Manager
- [ ] Enable VPC Service Controls
- [ ] Use private GKE clusters
- [ ] Enable Binary Authorization
- [ ] Enable Cloud Audit Logging
- [ ] Regularly update container images
- [ ] Use non-root users in containers

---

## Troubleshooting

### Cloud Run Issues

**Container not starting:**
```bash
gcloud run logs read rag-genai-api --limit 50
```

**Timeout errors:**
```bash
# Increase timeout
gcloud run services update rag-genai-api \
  --timeout 600 --region $REGION
```

### GKE Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n rag-genai
kubectl logs <pod-name> -n rag-genai
```

**Node issues:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

---

## Cleanup

### Remove Cloud Run Deployment

```bash
gcloud run services delete rag-genai-api --region $REGION
```

### Remove GKE Cluster

```bash
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE
```

### Clean up images

```bash
# List images
gcloud container images list --repository=gcr.io/$PROJECT_ID

# Delete image
gcloud container images delete gcr.io/$PROJECT_ID/rag-genai-api
```

---

## Next Steps

1. **Setup monitoring**: Configure Cloud Monitoring and alerting
2. **Setup logging**: Use Cloud Logging for centralized logs
3. **Setup CI/CD**: Use Cloud Build for automated deployments
4. **Setup DNS**: Configure custom domain names
5. **Setup SSL**: Enable SSL/TLS certificates
6. **Backup strategy**: Plan data backup and recovery

---

## Support and Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Google Cloud Support](https://cloud.google.com/support)

---

**Last Updated**: May 2026
