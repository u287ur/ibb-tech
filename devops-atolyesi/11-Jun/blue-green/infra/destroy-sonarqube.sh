#!/bin/bash
set -e

KEY_NAME="jenkins-key"
SECURITY_GROUP="sonarqube-sg"
TAG_NAME="SonarQubeServer"

echo "🧨 Destroying resources tagged with: $TAG_NAME"

# 🔥 1. EC2 Instance'ı durdur ve sil
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$TAG_NAME" \
  --query "Reservations[].Instances[?State.Name != 'terminated'].InstanceId" \
  --output text)

if [ -n "$INSTANCE_ID" ]; then
  echo "🛑 Terminating EC2 instance: $INSTANCE_ID"
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

  echo "⏳ Waiting for termination..."
  aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
  echo "✅ Instance terminated."
else
  echo "ℹ️ No active instance found with tag: $TAG_NAME"
fi

# 🔐 2. Security Group'u sil
SG_ID=$(aws ec2 describe-security-groups \
  --group-names "$SECURITY_GROUP" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "")

if [ -n "$SG_ID" ]; then
  echo "🧯 Deleting security group: $SECURITY_GROUP"
  aws ec2 delete-security-group --group-id "$SG_ID"
  echo "✅ Security group deleted."
else
  echo "ℹ️ No security group named $SECURITY_GROUP found."
fi

# 🔑 3. Key Pair sil
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo "🔑 Deleting key pair: $KEY_NAME"
  aws ec2 delete-key-pair --key-name "$KEY_NAME"
  rm -f "${KEY_NAME}.pem"
  echo "✅ Key pair and PEM file deleted."
else
  echo "ℹ️ Key pair $KEY_NAME not found."
fi

echo -e "\n✅ \033[1;32mCleanup complete.\033[0m"
