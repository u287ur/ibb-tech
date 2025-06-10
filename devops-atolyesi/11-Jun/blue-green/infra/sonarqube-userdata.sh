#!/bin/bash
set -e

echo "📦 Updating system..."
apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -yq

echo "☕ Installing Java 17..."
apt install -y openjdk-17-jdk unzip wget gnupg2

echo "✅ Java version:"
java -version

echo "⬇️ Downloading SonarQube..."
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
unzip sonarqube-10.3.0.82913.zip
mv sonarqube-10.3.0.82913 sonarqube

echo "👤 Creating sonar user..."
useradd -r -s /bin/false sonar
chown -R sonar:sonar /opt/sonarqube

echo "🔧 Creating SonarQube systemd service..."
cat <<EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Starting SonarQube service..."
systemctl daemon-reexec
systemctl enable sonar
systemctl start sonar

echo "✅ SonarQube setup completed!"
