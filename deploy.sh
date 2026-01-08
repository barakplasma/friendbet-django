#!/bin/bash

# Deploy FriendBet to Kubernetes

set -e

echo "🚀 Deploying FriendBet to Kubernetes..."

# Check if namespace exists, if not create it
if ! kubectl get namespace friendbet &> /dev/null; then
    echo "📦 Creating namespace friendbet..."
    kubectl apply -f k8s/namespace.yaml
fi

# Apply secrets
echo "🔐 Applying secrets..."
kubectl apply -f k8s/secrets.yaml

# Apply config maps
echo "⚙️ Applying config maps..."
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/django-config.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n friendbet --timeout=120s

# Deploy Django
echo "🎸 Deploying Django..."
kubectl apply -f k8s/django.yaml

# Wait for Django to be ready
echo "⏳ Waiting for Django to be ready..."
kubectl wait --for=condition=ready pod -l app=django -n friendbet --timeout=120s

# Deploy Ingress
echo "🌐 Deploying Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment complete!"
echo "📱 FriendBet should be available at: https://friendbet.526462738.xyz"
echo ""
echo "To check status:"
echo "  kubectl get pods -n friendbet"
echo "  kubectl logs -f deployment/django -n friendbet"