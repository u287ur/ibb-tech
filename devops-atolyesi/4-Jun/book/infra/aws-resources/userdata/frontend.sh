#!/bin/bash
set -e

echo "🔧 Installing Docker..."
apt update -y && apt install -y docker.io

echo "👤 Starting Docker..."
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

echo "🔐 Logging into Docker Hub..."
echo "${dockerhub_password}" | docker login -u "${dockerhub_username}" --password-stdin || {
  echo "❌ Docker login failed"
  exit 1
}

echo "⬇️ Pulling frontend Docker image..."
docker pull "${dockerhub_username}/frontend:${frontend_image_tag}" || {
  echo "❌ Docker pull failed"
  exit 1
}

echo "🚀 Running frontend container..."
docker rm -f frontend-container || true
docker run -d \
  -p 8080:8080 \
  --name frontend-container \
  "${dockerhub_username}/frontend:${frontend_image_tag}" || {
  echo "❌ Docker run failed"
  exit 1
}
