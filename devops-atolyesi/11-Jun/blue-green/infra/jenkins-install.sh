#!/bin/bash
set -e

KEY_NAME="jenkins-key"
INSTANCE_TYPE="t3.small"
AMI_ID="ami-0d59d17fb3b322d0b"  # Ubuntu 24.04 LTS (us-east-1)
SECURITY_GROUP="jenkins-sg"
USER_DATA_FILE="jenkins-userdata.sh"

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
    --description "Allow SSH and Jenkins UI access" \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0

  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 8080 --cidr 0.0.0.0/0

  echo "✅ Security group '$SECURITY_GROUP' created and rules added."
fi

# 🚀 Launch EC2 Instance
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-groups $SECURITY_GROUP \
  --user-data file://$USER_DATA_FILE \
  --block-device-mappings '[{
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "VolumeSize": 50,
      "VolumeType": "gp2",
      "DeleteOnTermination": true
    }
  }]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=JenkinsServer}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "⏳ Waiting for EC2 instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "🌐 EC2 Public IP: $PUBLIC_IP"

# 🕓 Wait for Jenkins on port 8080
echo "⏳ Waiting for Jenkins to start on port 8080..."
while true; do
  if nc -z -w 2 $PUBLIC_IP 8080; then
    echo "✅ Jenkins is accessible on port 8080. Proceeding to fetch admin password..."
    break
  fi
  echo "⌛ Jenkins not ready yet. Retrying in 10 seconds..."
  sleep 10
done

# 🔑 Fetch Jenkins Admin Password
MAX_ATTEMPTS=30
SLEEP_INTERVAL=10
ATTEMPT=1
ADMIN_PASS=""

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
  echo "⌛ Attempt $ATTEMPT: Fetching Jenkins admin password..."

  OUTPUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP \
    'sudo cat /var/lib/jenkins/secrets/initialAdminPassword' 2>&1 | grep -v "Warning:")

  if [[ "$OUTPUT" =~ "Permission denied" ]]; then
    echo -e "❌ SSH access denied."
    echo -e "Details: $OUTPUT"
    break
  elif [[ "$OUTPUT" =~ "No such file" ]]; then
    echo -e "⏳ Password file not yet available. Jenkins might still be starting..."
  elif [[ -n "$OUTPUT" ]]; then
    ADMIN_PASS="$OUTPUT"
    echo -e "\n✅ Jenkins Admin password retrieved successfully!"
    echo -e "🌐 Jenkins URL: http://$PUBLIC_IP:8080"
    echo -e "🔑 Admin Password: $ADMIN_PASS"
    break
  else
    echo -e "⚠️ Unexpected output:\n$OUTPUT"
  fi

  ((ATTEMPT++))
  sleep $SLEEP_INTERVAL
done

# 📥 SSH connection info
echo ""
echo -e "📥 SSH access: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
