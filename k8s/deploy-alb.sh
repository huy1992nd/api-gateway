#!/bin/bash

echo "🚀 Deploying API Gateway with ALB Ingress Controller"
echo "====================================================="

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

# Create namespace if it doesn't exist
NAMESPACE="api-gateway"
echo "📦 Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply all manifests
echo ""
echo "🔧 Applying Kubernetes manifests..."

echo "📊 Deploying PostgreSQL..."
kubectl apply -f postgres-deployment.yaml -n $NAMESPACE

echo "👤 Deploying User Service..."
kubectl apply -f user-service-deployment.yaml -n $NAMESPACE

echo "📦 Deploying Product Service..."
kubectl apply -f product-service-deployment.yaml -n $NAMESPACE

echo "🌐 Deploying API Gateway..."
kubectl apply -f api-service-deployment.yaml -n $NAMESPACE

# Wait for deployments to be ready
echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/user-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/product-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n $NAMESPACE

# Apply ALB Ingress
echo ""
echo "🔗 Applying ALB Ingress..."
kubectl apply -f alb-ingress-simple.yaml -n $NAMESPACE

# Wait for ALB to be provisioned
echo ""
echo "⏳ Waiting for ALB to be provisioned..."
kubectl wait --for=condition=available --timeout=300s ingress/api-gateway-ingress-simple -n $NAMESPACE

# Show deployment status
echo ""
echo "📋 Deployment Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🔍 Services:"
kubectl get services -n $NAMESPACE

echo ""
echo "🌐 Ingress:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "🔗 ALB Load Balancer:"
kubectl describe ingress api-gateway-ingress-simple -n $NAMESPACE | grep -A 5 "Address:"

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🔗 Access your API Gateway:"
echo "   - ALB URL will be shown above"
echo "   - Or check: kubectl get ingress -n $NAMESPACE -o wide"
echo ""
echo "🧪 Test endpoints:"
echo "   curl http://<ALB-URL>/health"
echo "   curl http://<ALB-URL>/users"
echo "   curl http://<ALB-URL>/products"
echo ""
echo "📊 Monitor ALB:"
echo "   kubectl logs -n kube-system deployment/aws-load-balancer-controller"
