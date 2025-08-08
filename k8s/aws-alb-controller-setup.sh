#!/bin/bash

echo "🚀 Setting up AWS ALB Ingress Controller for EKS"
echo "=================================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to Kubernetes cluster. Please connect to your EKS cluster first."
    exit 1
fi

echo "✅ Connected to Kubernetes cluster: $(kubectl config current-context)"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $AWS_ACCOUNT_ID"

# Get EKS Cluster Name
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
echo "🏗️  EKS Cluster Name: $CLUSTER_NAME"

# Get VPC ID
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.vpcId' --output text)
echo "🌐 VPC ID: $VPC_ID"

# Get Subnet IDs
SUBNET_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.subnetIds' --output text)
echo "🔗 Subnet IDs: $SUBNET_IDS"

echo ""
echo "📦 Installing AWS Load Balancer Controller..."

# Create IAM OIDC provider
echo "🔐 Creating IAM OIDC provider..."
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster $CLUSTER_NAME --approve

# Create IAM policy for ALB Controller
echo "📋 Creating IAM policy..."
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# Create IAM role and service account
echo "👤 Creating IAM role and service account..."
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install AWS Load Balancer Controller using Helm
echo "📦 Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Wait for controller to be ready
echo "⏳ Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

echo ""
echo "✅ AWS Load Balancer Controller setup completed!"
echo ""
echo "🔍 Check controller status:"
echo "   kubectl get pods -n kube-system | grep aws-load-balancer-controller"
echo ""
echo "📋 Next steps:"
echo "   1. Update alb-ingress.yaml with your specific values"
echo "   2. Deploy your application: ./k8s/deploy.sh"
echo "   3. Apply ALB Ingress: kubectl apply -f k8s/alb-ingress-simple.yaml"
