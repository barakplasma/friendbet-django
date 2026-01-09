#!/bin/bash

# Deploy FriendBet to Kubernetes using k3s embedded registry

set -e

echo "🚀 Deploying FriendBet to Kubernetes (k3s with embedded registry)..."

# Check if namespace exists, if not create it
if ! kubectl get namespace friendbet &> /dev/null; then
    echo "📦 Creating namespace friendbet..."
    kubectl apply -f k8s/namespace.yaml
fi

# Apply secrets and config
echo "🔐 Applying secrets and config..."
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres-config.yaml
kubectl apply -f k8s/django-config.yaml

# Deploy PostgreSQL first
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n friendbet --timeout=120s

echo "✅ PostgreSQL is ready"

# Build Docker image and import into k3s
echo "🏗️ Building Docker image..."
cat > Dockerfile.build << 'EOF'
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies
RUN pip install --no-cache-dir django==4.2.17 psycopg2-binary==2.9.9 social-auth-app-django==5.4.3 gunicorn==21.2.0 pillow==10.4.0

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Create media directory
RUN mkdir -p /app/media

EXPOSE 8000

# Run the application
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2"]
EOF

# Check if docker/podman is available
if command -v docker &> /dev/null; then
    echo "Building with Docker..."
    docker build -f Dockerfile.build -t friendbet:latest .
    echo "Importing into k3s..."
    docker save friendbet:latest | ctr -n k8s.io image import -
elif command -v podman &> /dev/null; then
    echo "Building with Podman..."
    podman build -f Dockerfile.build -t friendbet:latest .
    echo "Importing into k3s..."
    podman save friendbet:latest | ctr -n k8s.io image import -
else
    echo "❌ No container runtime found. Please install docker or podman."
    exit 1
fi

echo "✅ Image imported into k3s registry"

# Update deployment to use the local image
echo "🎸 Deploying Django..."
kubectl apply -f k8s/django.yaml

# Wait for Django to be ready (with extended timeout)
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

# Show pod status
echo ""
echo "📊 Current pod status:"
kubectl get pods -n friendbet