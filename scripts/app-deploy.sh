#!/bin/bash

set -e

echo "╔══════════════════════════════════════════╗"
echo "║   🚀 DEPLOY FRONTEND                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
K8S_DIR="k8s/frontend"
NAMESPACE="exploresg-prod"

# Step 1: Create namespace
echo -e "${BLUE}📦 Creating namespace${NC}"
kubectl apply -f k8s/namespace.yaml
echo ""

# Step 2: Deploy frontend
echo -e "${BLUE}🚀 Deploying frontend${NC}"
kubectl apply -f $K8S_DIR/deployment.yaml
echo ""

# Step 3: Wait for deployment
echo -e "${BLUE}⏳ Waiting for deployment to be ready${NC}"
kubectl rollout status deployment/exploresg-frontend -n $NAMESPACE --timeout=5m
echo ""

# Step 4: Get Load Balancer URL
echo -e "${BLUE}🔗 Getting Load Balancer URL${NC}"
echo -e "${YELLOW}⏳ Waiting for Load Balancer to provision (this takes ~2 minutes)...${NC}"
sleep 30

LB_URL=$(kubectl get svc exploresg-frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_URL" ]; then
    echo -e "${YELLOW}⚠️  Load Balancer still provisioning. Run this to get URL:${NC}"
    echo "kubectl get svc exploresg-frontend -n $NAMESPACE"
else
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║   ✅ FRONTEND DEPLOYED!                  ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}📍 Frontend URL: http://$LB_URL${NC}"
    echo ""
fi

# Show status
echo -e "${BLUE}📊 Current Status:${NC}"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get svc -n $NAMESPACE