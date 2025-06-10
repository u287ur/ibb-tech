#!/bin/bash
set -e

KEY_NAME="jenkins-key"
INSTANCE_TYPE="t3.medium"
AMI_ID="ami-0d59d17fb3b322d0b"  # Ubuntu 24.04 LTS (us-east-1)
SECURITY_GROUP="sonarqube-sg"
USER_DATA_FILE="sonarqube-userdata.sh"

echo "📁 Using user data from: $USER_DATA_FILE"
# 🔑 Key Pair
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo "🔑 Key pair '$KEY_NAME' already exists."
else
  echo "🔑 Creating EC2 key pair: $KEY_NAME"
  aws ec2 create-key-pair --key-name "$KEY_NAME" \
    --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
  chmod 400 ${KEY_NAME}.pem
  echo "✅ Key saved to: ${KEY_NAME}.pem"
fi

# 🔐 Security Group
if aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" &>/dev/null; then
  echo "🔐 Security group '$SECURITY_GROUP' already exists."
else
  echo "🔐 Creating security group: $SECURITY_GROUP"
  SG_ID=$(aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP" \
    --description "Allow SSH and SonarQube UI" \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0

  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 9000 --cidr 0.0.0.0/0

  echo "✅ Security group '$SECURITY_GROUP' created and rules added."
fi

# 🚀 Launch EC2 Instance
echo "🚀 Launching EC2 instance for SonarQube..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-groups $SECURITY_GROUP \
  --user-data file://$USER_DATA_FILE \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SonarQubeServer}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "⏳ Waiting for EC2 instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "🌐 EC2 Public IP: $PUBLIC_IP"

# ⏳ Wait for port 9000 to be ready
echo "⏳ Waiting for SonarQube to be accessible on port 9000..."
while true; do
  if nc -z -w 2 $PUBLIC_IP 9000; then
    echo "✅ SonarQube is up!"
    break
  fi
  echo "⌛ SonarQube not ready yet... retrying in 10s"
  sleep 10
done

# 📥 Final Output
echo ""
echo -e "\033[1;32m✅ SonarQube setup complete!\033[0m"
echo -e "\033[1;34m🌐 Access SonarQube at: http://$PUBLIC_IP:9000\033[0m"
echo -e "\033[1;33m📥 SSH access: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP\033[0m"
