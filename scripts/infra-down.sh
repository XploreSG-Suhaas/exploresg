#!/bin/bash

set -e  # Exit on any error

echo "╔══════════════════════════════════════════╗"
echo "║   🧹 INFRASTRUCTURE DOWN                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Configuration
TERRAFORM_DIR="infra/environments/prod"
AWS_REGION="ap-southeast-1"
CLUSTER_NAME="exploresg-prod-cluster"

# Colors for output
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Confirmation prompt
echo -e "${YELLOW}⚠️  WARNING: This will destroy EKS cluster and NAT gateways${NC}"
echo -e "${YELLOW}⚠️  VPC and subnets will remain (base infrastructure)${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ Aborted${NC}"
    exit 0
fi

echo ""

# Step 1: Remove Helm releases
echo -e "${BLUE}🗑️  Removing Helm releases${NC}"
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $AWS_REGION || true

helm uninstall aws-load-balancer-controller -n kube-system || true
echo ""

# Step 2: Terraform Destroy
echo -e "${BLUE}💥 Terraform Destroy - EKS & NAT${NC}"
echo -e "${YELLOW}⏰ This will take ~5-10 minutes...${NC}"
cd $TERRAFORM_DIR

terraform destroy -auto-approve \
  -target=module.eks \
  -target=module.vpc.aws_nat_gateway.main

cd ../../..
echo ""

# Success!
echo "╔══════════════════════════════════════════╗"
echo "║   ✅ INFRASTRUCTURE DESTROYED!           ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ EKS Cluster: Destroyed${NC}"
echo -e "${GREEN}✅ NAT Gateways: Removed${NC}"
echo -e "${GREEN}💰 Hourly costs stopped${NC}"
echo ""
echo -e "${BLUE}📝 VPC remains for next deployment (~$5/month)${NC}"
echo -e "${BLUE}🔄 To start again: Run './scripts/infra-up.sh'${NC}"