#!/bin/bash
# === Disable AWS CLI pager ===
export AWS_PAGER=""
# === Color definitions ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# === Configurable Variables ===
AWS_REGION="us-east-1"
CLUSTER_NAME="flask-cluster"
SERVICE_NAME="flask-service"
TASK_NAME="flask-task"
REPO_NAME="flask-ecr-repo"
CONTAINER_NAME="flask-app"
CONTAINER_PORT=5000
SG_NAME="flask-sg"

# === Step 1: Get AWS Account Info ===
echo -e "${CYAN}${BOLD}Step 1: Getting AWS account info...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
 echo -e "${RED}❌ AWS CLI not configured. Run 'aws configure' first.${NC}"
 exit 1
fi
echo -e "${GREEN}✔ AWS Account ID: $ACCOUNT_ID${NC}"

# === Step 2: Get default VPC and Subnet ===
echo -e "\n${CYAN}${BOLD}Step 2: Fetching default VPC and subnet...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query "Subnets[0].SubnetId" --output text)
echo -e "${GREEN}✔ VPC ID: $VPC_ID | Subnet ID: $SUBNET_ID${NC}"

# === Step 3: Check/Create Security Group ===
echo -e "\n${CYAN}${BOLD}Step 3: Creating or using security group '${SG_NAME}'...${NC}"
SG_ID=$(aws ec2 describe-security-groups \
 --filters Name=group-name,Values=$SG_NAME Name=vpc-id,Values=$VPC_ID \
 --query "SecurityGroups[0].GroupId" \
 --output text 2>/dev/null)

if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
 SG_ID=$(aws ec2 create-security-group \
   --group-name $SG_NAME \
   --description "Allow TCP $CONTAINER_PORT" \
   --vpc-id $VPC_ID \
   --query 'GroupId' --output text)
 aws ec2 authorize-security-group-ingress \
   --group-id $SG_ID \
   --protocol tcp --port $CONTAINER_PORT --cidr 0.0.0.0/0
 echo -e "${GREEN}✔ Security group created: $SG_ID${NC}"
else
 echo -e "${GREEN}✔ Using existing security group: $SG_ID${NC}"
fi

# === Step 4: Create ECR Repository if needed ===
echo -e "\n${CYAN}${BOLD}Step 4: Creating or checking ECR repository '${REPO_NAME}'...${NC}"
aws ecr describe-repositories --repository-names $REPO_NAME >/dev/null 2>&1
if [ $? -ne 0 ]; then
 aws ecr create-repository --repository-name $REPO_NAME
 echo -e "${GREEN}✔ ECR repository created.${NC}"
else
 echo -e "${GREEN}✔ ECR repository already exists.${NC}"
fi

IMAGE_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"

# === Step 5: Create IAM Role if needed ===
echo -e "\n${CYAN}${BOLD}Step 5: Creating or checking IAM Role 'ecsTaskExecutionRole'...${NC}"
aws iam get-role --role-name ecsTaskExecutionRole >/dev/null 2>&1
if [ $? -ne 0 ]; then
 aws iam create-role --role-name ecsTaskExecutionRole \
   --assume-role-policy-document '{
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Service": "ecs-tasks.amazonaws.com" },
       "Action": "sts:AssumeRole"
     }]
   }'
 aws iam attach-role-policy \
   --role-name ecsTaskExecutionRole \
   --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
 echo -e "${YELLOW}⏳ Waiting 10 seconds for IAM propagation...${NC}"
 sleep 10
else
 echo -e "${GREEN}✔ IAM Role already exists.${NC}"
fi

# === Step 6: Create ECS Cluster if needed ===
echo -e "\n${CYAN}${BOLD}Step 6: Creating or checking ECS Cluster '${CLUSTER_NAME}'...${NC}"
aws ecs describe-clusters --clusters $CLUSTER_NAME --query "clusters[0].status" --output text | grep -q ACTIVE
if [ $? -ne 0 ]; then
 aws ecs create-cluster --cluster-name $CLUSTER_NAME
 echo -e "${GREEN}✔ ECS Cluster created.${NC}"
else
 echo -e "${GREEN}✔ ECS Cluster already exists.${NC}"
fi

# === Step 7: Register Task Definition ===
echo -e "\n${CYAN}${BOLD}Step 7: Registering ECS Task Definition '${TASK_NAME}'...${NC}"
aws ecs register-task-definition \
 --family $TASK_NAME \
 --requires-compatibilities "FARGATE" \
 --network-mode "awsvpc" \
 --cpu "256" \
 --memory "512" \
 --execution-role-arn arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole \
 --container-definitions "[
   {
     \"name\": \"$CONTAINER_NAME\",
     \"image\": \"$IMAGE_URL\",
     \"portMappings\": [
       {
         \"containerPort\": $CONTAINER_PORT,
         \"protocol\": \"tcp\"
       }
     ],
     \"essential\": true
   }
 ]"
echo -e "${GREEN}✔ Task definition registered.${NC}"

# === Step 8: Create ECS Service ===
echo -e "\n${CYAN}${BOLD}Step 8: Creating ECS Service '${SERVICE_NAME}'...${NC}"
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].status" --output text | grep -q ACTIVE
if [ $? -ne 0 ]; then
 aws ecs create-service \
   --cluster $CLUSTER_NAME \
   --service-name $SERVICE_NAME \
   --task-definition $TASK_NAME \
   --launch-type FARGATE \
   --desired-count 1 \
   --network-configuration "awsvpcConfiguration={
     subnets=[\"$SUBNET_ID\"],
     securityGroups=[\"$SG_ID\"],
     assignPublicIp=\"ENABLED\"
   }"
 echo -e "${GREEN}✔ ECS Service created.${NC}"
else
 echo -e "${GREEN}✔ ECS Service already exists.${NC}"
fi

# === Step 9: Docker login to ECR ===
echo -e "\n${CYAN}${BOLD}Step 9: Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
if [ $? -ne 0 ]; then
 echo -e "${RED}❌ Docker login failed. Check IAM ECR permissions.${NC}"
 exit 1
fi
echo -e "${GREEN}✔ Docker login successful.${NC}"

# === Step 10: Build & Push Docker image with correct platform ===
echo -e "\n${CYAN}${BOLD}Step 10: Building Docker image for linux/amd64 (Fargate)...${NC}"
docker buildx build --platform linux/amd64 -t $REPO_NAME . --load
docker tag $REPO_NAME:latest $IMAGE_URL
docker push $IMAGE_URL
echo -e "${GREEN}✔ Docker image pushed to ECR.${NC}"

# === Step 11: Force ECS service to redeploy ===
echo -e "\n${CYAN}${BOLD}Step 11: Forcing ECS Service to redeploy new image...${NC}"
aws ecs update-service \
 --cluster $CLUSTER_NAME \
 --service $SERVICE_NAME \
 --force-new-deployment >/dev/null 2>&1

if [ $? -eq 0 ]; then
 echo -e "${GREEN}✔ ECS Service successfully redeployed with latest image.${NC}"
else
 echo -e "${RED}❌ Failed to force ECS Service redeployment.${NC}"
fi

# === DONE ===
echo -e "\n${CYAN}${BOLD}🎉 Setup complete! Your Flask app is deployed on AWS ECS Fargate.${NC}\n"
