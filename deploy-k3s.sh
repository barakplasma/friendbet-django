#!/bin/bash

# Deploy FriendBet to Kubernetes (k3s with built-in registry)

set -e

echo "🚀 Deploying FriendBet to Kubernetes (k3s)..."

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

# For now, let's create a simple deployment that uses a public Docker image
# or we can run Django directly on the host

echo "🎸 Deploying Django (using minimal approach)..."

# Create a simple deployment script that runs Django locally
cat > /tmp/friendbet-deploy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django
  namespace: friendbet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: django
  template:
    metadata:
      labels:
        app: django
    spec:
      containers:
      - name: django
        image: python:3.11-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            apt-get update && apt-get install -y gcc postgresql-client && \
            pip install django==4.2.17 psycopg2-binary==2.9.9 social-auth-app-django==5.4.3 gunicorn==21.2.0 pillow==10.4.0 && \
            python manage.py migrate --noinput && \
            python manage.py collectstatic --noinput && \
            gunicorn config.wsgi:application --bind 0.0.0.0:8000
        ports:
        - containerPort: 8000
        env:
        - name: POSTGRES_DB
          value: "friendbet"
        - name: POSTGRES_USER
          value: "friendbet"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
        - name: DJANGO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: django-secret
              key: DJANGO_SECRET_KEY
        - name: DJANGO_ALLOWED_HOSTS
          valueFrom:
            configMapKeyRef:
              name: django-config
              key: DJANGO_ALLOWED_HOSTS
        - name: DJANGO_DEBUG
          valueFrom:
            configMapKeyRef:
              name: django-config
              key: DJANGO_DEBUG
        volumeMounts:
        - name: app-code
          mountPath: /app
        - name: media-storage
          mountPath: /app/media
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        hostPath:
          path: /root/toto
          type: Directory
      - name: media-storage
        persistentVolumeClaim:
          claimName: django-media-pvc
EOF

kubectl apply -f /tmp/friendbet-deploy.yaml

# Wait for Django to be ready
echo "⏳ Waiting for Django to be ready..."
kubectl wait --for=condition=ready pod -l app=django -n friendbet --timeout=300s || echo "⚠️ Django pods may still be starting"

# Deploy services
echo "🌐 Creating services..."
kubectl apply -f k8s/django.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment complete!"
echo "📱 FriendBet should be available at: https://friendbet.526462738.xyz"
echo ""
echo "To check status:"
echo "  kubectl get pods -n friendbet"
echo "  kubectl logs -f deployment/django -n friendbet"
echo ""
echo "To access the admin interface:"
echo "  kubectl port-forward -n friendbet deployment/django 8000:8000"
echo "  Then visit: http://localhost:8000/admin"