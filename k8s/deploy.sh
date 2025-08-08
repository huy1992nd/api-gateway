#!/bin/bash

echo "🚀 Deploying API Gateway with Microservices to Kubernetes"
echo "=========================================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to Kubernetes cluster. Please connect to your cluster first."
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

echo "🔗 Applying Istio Gateway and VirtualService..."
kubectl apply -f api-gateway-istio.yaml -n $NAMESPACE

# Wait for deployments to be ready
echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/user-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/product-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n $NAMESPACE

# Show deployment status
echo ""
echo "📋 Deployment Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🔍 Services:"
kubectl get services -n $NAMESPACE

echo ""
echo "🌐 Istio Resources:"
kubectl get gateway,virtualservice -n $NAMESPACE

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🔗 Access your API Gateway:"
echo "   - If using minikube: kubectl port-forward svc/api-gateway 3000:3000 -n $NAMESPACE"
echo "   - If using Istio Ingress: kubectl get ingress -n $NAMESPACE"
echo ""
echo "🧪 Test endpoints:"
echo "   curl http://localhost:3000/health"
echo "   curl http://localhost:3000/users"
echo "   curl http://localhost:3000/products"
