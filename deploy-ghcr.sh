#!/bin/bash

# Deploy FriendBet to Kubernetes using GHCR (GitHub Container Registry)

set -e

echo "🚀 Deploying FriendBet to Kubernetes (using GHCR)..."

# Check if namespace exists
if ! kubectl get namespace friendbet &> /dev/null; then
    echo "📦 Creating namespace friendbet..."
    kubectl apply -f k8s/namespace.yaml
fi

# Apply secrets and config
echo "🔐 Applying secrets and config..."
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/django-config.yaml

# Apply GHCR secret (you need to update this file with your credentials first)
echo "🔑 Applying GHCR authentication..."
if [ -f "k8s/ghcr-secret.yaml" ]; then
    echo "⚠️  Make sure you've updated k8s/ghcr-secret.yaml with your GitHub credentials!"
    kubectl apply -f k8s/ghcr-secret.yaml
else
    echo "❌ k8s/ghcr-secret.yaml not found. Please create it with your GHCR credentials."
    exit 1
fi

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n friendbet --timeout=120s
echo "✅ PostgreSQL is ready"

# Update Django deployment
echo "🎸 Deploying Django (from GHCR)..."
kubectl apply -f k8s/django.yaml

# Wait for Django
echo "⏳ Waiting for Django to be ready..."
kubectl wait --for=condition=ready pod -l app=django -n friendbet --timeout=300s || echo "⚠️ Django pods may still be starting"

# Deploy ingress
echo "🌐 Deploying Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment complete!"
echo "📱 FriendBet should be available at: https://friendbet.526462738.xyz"
echo ""
echo "To check status:"
echo "  kubectl get pods -n friendbet"
echo "  kubectl logs -f deployment/django -n friendbet"
echo ""
echo "To access the admin interface locally:"
echo "  kubectl port-forward -n friendbet deployment/django 8000:8000"
echo "  Then visit: http://localhost:8000/admin"
echo ""
echo "Current pod status:"
kubectl get pods -n friendbet