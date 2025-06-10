#!/bin/bash
set -e

# ---- Configuration ----
JENKINS_TAG="JenkinsServer"
SONARQUBE_TAG="SonarQubeServer"
KEY_NAME="jenkins-key"
SECURITY_GROUP="sonarqube-sg"

# ---- Functions ----

function get_instance_info() {
  local TAG=$1
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$TAG" "Name=instance-state-name,Values=running,stopped" \
    --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,LaunchTime]" \
    --output table
}

function get_instance_id() {
  local TAG=$1
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$TAG" "Name=instance-state-name,Values=running,stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
}

function get_sg_id() {
  aws ec2 describe-security-groups \
    --group-names "$SECURITY_GROUP" \
    --query "SecurityGroups[0].GroupId" \
    --output text 2>/dev/null || echo ""
}

# ---- Summary ----

echo -e "\n🔍 Fetching EC2 instance details..."

echo -e "\n🔧 Jenkins EC2:"
get_instance_info "$JENKINS_TAG"

echo -e "\n🔧 SonarQube EC2:"
get_instance_info "$SONARQUBE_TAG"

echo -e "\n🔐 Checking Security Group: $SECURITY_GROUP"
SG_ID=$(get_sg_id)
if [ -n "$SG_ID" ]; then
  echo "✅ Security Group exists: $SG_ID"
else
  echo "ℹ️ Security Group not found."
fi

echo -e "\n🔑 Checking Key Pair: $KEY_NAME"
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo "✅ Key Pair exists."
else
  echo "ℹ️ Key Pair not found."
fi

# ---- Confirmation ----
echo -e "\n⚠️ \033[1;33mWARNING: The above resources will be permanently deleted!\033[0m"
read -p "❓ Do you want to continue? Type 'yes' to proceed: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Deletion cancelled by user."
  exit 1
fi

# ---- Delete EC2 Instances ----

for TAG in "$JENKINS_TAG" "$SONARQUBE_TAG"; do
  INSTANCE_ID=$(get_instance_id "$TAG")
  if [ -n "$INSTANCE_ID" ]; then
    echo -e "\n🗑️ Terminating EC2 instance ($TAG): $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
    echo "⏳ Waiting for termination..."
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
    echo "✅ Instance terminated."
  else
    echo "ℹ️ No instance found with tag: $TAG"
  fi
done

# ---- Delete Security Group ----

if [ -n "$SG_ID" ]; then
  echo -e "\n🧯 Deleting Security Group: $SECURITY_GROUP"
  aws ec2 delete-security-group --group-id "$SG_ID"
  echo "✅ Security Group deleted."
else
  echo "ℹ️ Security Group not found, skipping."
fi

# ---- Delete Key Pair ----

if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  echo -e "\n🔑 Deleting Key Pair: $KEY_NAME"
  aws ec2 delete-key-pair --key-name "$KEY_NAME"
  rm -f "${KEY_NAME}.pem"
  echo "✅ Key Pair and PEM file deleted."
else
  echo "ℹ️ Key Pair not found, skipping."
fi

echo -e "\n✅ \033[1;32mAll selected resources have been safely deleted.\033[0m"
