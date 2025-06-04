#!/bin/bash
set -e

echo "📦 Updating system packages..."
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -yq --with-new-pkgs

echo "☕ Installing Java 21..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y openjdk-21-jdk

echo "🐳 Installing Docker..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "🧰 Installing AWS CLI..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y unzip curl
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

echo "📦 Installing Terraform..."
wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm -f terraform_1.6.6_linux_amd64.zip
terraform -version

echo "🔐 Adding Jenkins GPG key..."
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "📦 Adding Jenkins repository..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "📦 Installing Jenkins..."
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y jenkins

echo "🔐 Granting Docker access to Jenkins user..."
sudo usermod -aG docker jenkins

echo "🚀 Starting Jenkins and Docker services..."
sudo systemctl enable jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins

echo "✅ Jenkins installation completed!"
echo "🔑 Initial Jenkins Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
