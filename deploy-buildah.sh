#!/bin/bash

# Deploy FriendBet to Kubernetes using buildah + k3s

set -e

echo "🔨 Building container image with buildah..."

# Build the image using buildah
buildah bud -t friendbet:latest .

# Tag it for k3s registry
buildah tag friendbet:latest localhost/friendbet:latest

# Import into k3s containerd
echo "📦 Importing image into k3s..."
buildah push friendbet:latest oci-archive:/tmp/friendbet.tar
ctr -n k8s.io image import /tmp/friendbet.tar
rm /tmp/friendbet.tar

echo "✅ Image built and imported"

echo "🚀 Deploying to Kubernetes..."

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

# Update Django deployment to use the local image
echo "🎸 Deploying Django..."
kubectl delete deployment django -n friendbet --ignore-not-found=true

# Create deployment using our built image
cat > /tmp/django-deployment-final.yaml << 'EOF'
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
      initContainers:
      - name: migrate
        image: friendbet:latest
        command: ["python", "manage.py", "migrate", "--noinput"]
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
      containers:
      - name: django
        image: friendbet:latest
        imagePullPolicy: Never  # Use local image
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
      - name: media-storage
        persistentVolumeClaim:
          claimName: django-media-pvc
EOF

kubectl apply -f /tmp/django-deployment-final.yaml

echo "⏳ Waiting for Django to be ready..."
kubectl wait --for=condition=ready pod -l app=django -n friendbet --timeout=300s || echo "⚠️ Pods may still be initializing"

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