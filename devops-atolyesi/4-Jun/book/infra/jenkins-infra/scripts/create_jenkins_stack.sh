#!/bin/bash
# AWS CLI ile Jenkins EC2, IAM ve S3 kurulumu

REGION="eu-central-1"
JENKINS_ROLE_NAME="JenkinsRole"
JENKINS_INSTANCE_PROFILE="JenkinsProfile"
JENKINS_BUCKET="tf-state-hakan"
LOCK_TABLE="terraform-locks"
KEY_NAME="jenkins-key"
AMI_ID="ami-0c02fb55956c7d316"  # Ubuntu 20.04 (Frankfurt)
SG_ID="sg-xxxxxxxxxxxx"        # Önceden oluşturulmuş bir SG kullan

# 1. IAM Policy oluştur
aws iam create-policy --policy-name JenkinsPolicy \
  --policy-document file://jenkins-user-policy.json

# 2. IAM Role oluştur
aws iam create-role --role-name $JENKINS_ROLE_NAME \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name $JENKINS_ROLE_NAME \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/JenkinsPolicy

# 3. EC2 Instance Profile oluştur
aws iam create-instance-profile --instance-profile-name $JENKINS_INSTANCE_PROFILE
aws iam add-role-to-instance-profile --instance-profile-name $JENKINS_INSTANCE_PROFILE --role-name $JENKINS_ROLE_NAME

# 4. S3 ve DynamoDB remote backend için oluştur
aws s3api create-bucket --bucket $JENKINS_BUCKET --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

aws dynamodb create-table \
    --table-name $LOCK_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

# 5. Jenkins EC2 başlat
aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type t3.small \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --iam-instance-profile Name=$JENKINS_INSTANCE_PROFILE \
  --user-data file://jenkins_setup.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-ci}]' \
  --region $REGION

echo "✅ Jenkins altyapısı kuruldu"
