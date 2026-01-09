#!/bin/bash

# Deploy FriendBet to Kubernetes using direct Python image

set -e

echo "🚀 Deploying FriendBet to Kubernetes (using hostPath approach)..."

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

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n friendbet --timeout=120s
echo "✅ PostgreSQL is ready"

# Create a simpler deployment that pulls Python image and installs dependencies
cat > /tmp/django-deployment.yaml << 'EOF'
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
            set -e
            echo "📦 Installing system dependencies..."
            apt-get update && apt-get install -y gcc postgresql-client && rm -rf /var/lib/apt/lists/*
            
            echo "🐍 Installing Python dependencies..."
            pip install --no-cache-dir \
              django==4.2.17 \
              psycopg2-binary==2.9.9 \
              social-auth-app-django==5.4.3 \
              gunicorn==21.2.0 \
              pillow==10.4.0
            
            echo "🗄️ Running migrations..."
            python manage.py migrate --noinput
            
            echo "🎨 Collecting static files..."
            python manage.py collectstatic --noinput
            
            echo "🚀 Starting Gunicorn..."
            gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 2 --threads 4
            
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
        emptyDir: {}
EOF

echo "🎸 Deploying Django..."
kubectl delete deployment django -n friendbet --ignore-not-found=true
kubectl apply -f /tmp/django-deployment.yaml

echo "⏳ Waiting for Django to start (this may take a few minutes)..."
sleep 30

# Check pod status
echo "📊 Current pod status:"
kubectl get pods -n friendbet

# Wait for Django to be ready (with timeout)
echo "⏳ Waiting for Django pod to be ready..."
timeout 180 bash -c 'until kubectl get pods -n friendbet -l app=django -o jsonpath="{.items[0].status.phase}" | grep -q "Running"; do sleep 5; echo "Waiting..."; done' || echo "⚠️ Pods may still be initializing"

# Deploy services and ingress
echo "🌐 Deploying services and ingress..."
kubectl apply -f k8s/django.yaml
kubectl apply -f k8s/ingress.yaml

echo ""
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