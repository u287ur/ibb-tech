#!/bin/bash
set -e

# Install Docker
apt update -y
apt install -y docker.io

# Start Docker
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Docker login
echo "${dockerhub_password}" | docker login -u "${dockerhub_username}" --password-stdin

# Pull image
docker pull "${dockerhub_username}/backend:${backend_image_tag}"

# Run container
docker run -d \
  -p 8000:8000 \
  -e SECRET_KEY="${secret_key}" \
  -e DEBUG=True \
  -e ALLOWED_HOSTS="*" \
  -e DB_NAME="librarydb" \
  -e DB_USER="${db_username}" \
  -e DB_PASSWORD="${db_password}" \
  -e DB_HOST="${rds_endpoint}" \
  -e DB_PORT=3306 \
  --name backend-container \
  "${dockerhub_username}/backend:${backend_image_tag}"
