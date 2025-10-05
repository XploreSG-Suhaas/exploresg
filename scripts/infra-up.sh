#!/bin/bash

set -e  # Exit on any error

echo "╔══════════════════════════════════════════╗"
echo "║   🚀 INFRASTRUCTURE UP                   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Configuration
TERRAFORM_DIR="infra/environments/prod"
AWS_REGION="ap-southeast-1"
CLUSTER_NAME="exploresg-prod-cluster"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Terraform Init
echo -e "${BLUE}🔄 Terraform Init${NC}"
cd $TERRAFORM_DIR
terraform init
echo ""

# Step 2: Terraform Plan
echo -e "${BLUE}📋 Terraform Plan - EKS & NAT${NC}"
terraform plan \
  -target=module.eks \
  -target=module.vpc.aws_nat_gateway.main \
  -out=tfplan
echo ""

# Step 3: Terraform Apply
echo -e "${BLUE}🏗️  Terraform Apply - Provisioning Infrastructure${NC}"
echo -e "${YELLOW}⏰ This will take ~15-20 minutes...${NC}"
terraform apply -auto-approve tfplan
echo ""

# Go back to root
cd ../../..

# Step 4: Configure kubectl
echo -e "${BLUE}🔗 Configuring kubectl${NC}"
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $AWS_REGION
echo ""

# Step 5: Verify EKS
echo -e "${BLUE}✅ Verifying EKS Cluster${NC}"
kubectl get nodes
echo ""

# Step 6: Install AWS Load Balancer Controller
echo -e "${BLUE}🎛️  Installing AWS Load Balancer Controller${NC}"

# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install controller
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller
echo ""

# Step 7: Wait for controller
echo -e "${BLUE}⏳ Waiting for Load Balancer Controller${NC}"
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=aws-load-balancer-controller \
  -n kube-system \
  --timeout=300s
echo ""

# Success!
echo "╔══════════════════════════════════════════╗"
echo "║   ✅ INFRASTRUCTURE READY!               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ EKS Cluster: $CLUSTER_NAME${NC}"
echo -e "${GREEN}✅ Worker Nodes: Running${NC}"
echo -e "${GREEN}✅ NAT Gateways: Configured${NC}"
echo -e "${GREEN}✅ Load Balancer Controller: Installed${NC}"
echo ""
echo -e "${BLUE}🚀 Ready to deploy applications!${NC}"
echo -e "${BLUE}💡 Next: Run './scripts/app-up.sh'${NC}"