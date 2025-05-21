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

# === Input Parameters ===
echo -e "${CYAN}${BOLD}🔧 ECS Setup Script${NC}"

echo -ne "${BOLD}VPC Name Tag${NC} [${YELLOW}my-vpc${NC}]: "; read VPC_NAME
VPC_NAME=${VPC_NAME:-my-vpc}

echo -ne "${BOLD}AWS Region${NC} [${YELLOW}us-east-1${NC}]: "; read AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

echo -ne "${BOLD}Cluster Name${NC} [${YELLOW}ecs-cluster${NC}]: "; read CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-ecs-cluster}

echo -ne "${BOLD}Service Name${NC} [${YELLOW}web-service${NC}]: "; read SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-web-service}

echo -ne "${BOLD}Task Name${NC} [${YELLOW}web-task${NC}]: "; read TASK_NAME
TASK_NAME=${TASK_NAME:-web-task}

echo -ne "${BOLD}Container Name${NC} [${YELLOW}web-container${NC}]: "; read CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-web-container}

echo -ne "${BOLD}Container Port${NC} [${YELLOW}5000${NC}]: "; read CONTAINER_PORT
CONTAINER_PORT=${CONTAINER_PORT:-5000}

echo -ne "${BOLD}ECR Repo Name${NC} [${YELLOW}web-ecr${NC}]: "; read REPO_NAME
REPO_NAME=${REPO_NAME:-web-ecr}

echo -ne "${BOLD}Do you want to use Load Balancer? (yes/no)${NC} [${YELLOW}yes${NC}]: "; read USE_LB
USE_LB=${USE_LB:-yes}

# === Get AWS Account ID ===
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✔ AWS Account ID: $ACCOUNT_ID${NC}"

# === Create VPC and Subnets in 2 AZs ===
echo -e "${CYAN}🔧 Creating new VPC and networking components...${NC}"
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text --region $AWS_REGION)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME --region $AWS_REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value":true}' --region $AWS_REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}' --region $AWS_REGION

AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[*].ZoneName' --output text --region $AWS_REGION))
SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ${AZS[0]} --query 'Subnet.SubnetId' --output text --region $AWS_REGION)
SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ${AZS[1]} --query 'Subnet.SubnetId' --output text --region $AWS_REGION)
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --region $AWS_REGION)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $AWS_REGION

RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $AWS_REGION)
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $AWS_REGION
aws ec2 associate-route-table --subnet-id $SUBNET1_ID --route-table-id $RT_ID --region $AWS_REGION
aws ec2 associate-route-table --subnet-id $SUBNET2_ID --route-table-id $RT_ID --region $AWS_REGION

# === Security Group ===
SG_ID=$(aws ec2 create-security-group --group-name ${SERVICE_NAME}-sg --description "Allow traffic" --vpc-id $VPC_ID --query 'GroupId' --output text --region $AWS_REGION)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port $CONTAINER_PORT --cidr 0.0.0.0/0 --region $AWS_REGION

# === Create ECR Repo ===
aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION >/dev/null 2>&1 || \
aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION
IMAGE_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"

# === Create IAM Role ===
aws iam get-role --role-name ecsTaskExecutionRole >/dev/null 2>&1 || {
  aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{"Effect": "Allow","Principal": {"Service": "ecs-tasks.amazonaws.com"},"Action": "sts:AssumeRole"}]
  }'
  aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
  sleep 10
}

# === ECS Cluster ===
STATUS=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION --query "clusters[0].status" --output text 2>/dev/null)
if [[ "$STATUS" != "ACTIVE" ]]; then
  echo -e "${YELLOW}⚠ Cluster '$CLUSTER_NAME' not active or not found. Recreating...${NC}"
  aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION
else
  echo -e "${GREEN}✔ ECS Cluster already active.${NC}"
fi

# === Register Task Definition ===
aws ecs register-task-definition \
  --family $TASK_NAME \
  --requires-compatibilities FARGATE \
  --network-mode awsvpc \
  --cpu "256" \
  --memory "512" \
  --execution-role-arn arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole \
  --container-definitions "[
    {\"name\": \"$CONTAINER_NAME\",\"image\": \"$IMAGE_URL\",\"portMappings\": [{\"containerPort\": $CONTAINER_PORT}],\"essential\": true}
  ]" --region $AWS_REGION

# === Docker Build and Push ===
echo -e "${CYAN}📦 Building and pushing Docker image...${NC}"
[[ ! -f Dockerfile ]] && echo -e "FROM python:3.9-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install -r requirements.txt\nCOPY . .\nCMD [\"python\", \"app.py\"]" > Dockerfile
[[ ! -f app.py ]] && echo -e "from flask import Flask\napp = Flask(__name__)\n@app.route('/')\ndef home():\n    return 'Hello from Flask on ECS!'\nif __name__ == '__main__':\n    app.run(host='0.0.0.0', port=$CONTAINER_PORT)" > app.py
[[ ! -f requirements.txt ]] && echo flask > requirements.txt

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
docker buildx build --platform linux/amd64 -t $REPO_NAME . --load
docker tag $REPO_NAME:latest $IMAGE_URL
docker push $IMAGE_URL

# === Create Load Balancer if requested ===
if [[ "$USE_LB" == "yes" ]]; then
  echo -e "${CYAN}🌐 Creating Load Balancer...${NC}"
  LB_SG_ID=$(aws ec2 create-security-group --group-name ${SERVICE_NAME}-lb-sg --description "ALB access" --vpc-id $VPC_ID --query 'GroupId' --output text --region $AWS_REGION)
  aws ec2 authorize-security-group-ingress --group-id $LB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION

  ALB_NAME=${SERVICE_NAME}-alb
  TG_NAME=${SERVICE_NAME}-tg

  ALB_ARN=$(aws elbv2 create-load-balancer --name $ALB_NAME --subnets $SUBNET1_ID $SUBNET2_ID --security-groups $LB_SG_ID --scheme internet-facing --type application --query "LoadBalancers[0].LoadBalancerArn" --output text --region $AWS_REGION)
  TG_ARN=$(aws elbv2 create-target-group --name $TG_NAME --protocol HTTP --port $CONTAINER_PORT --vpc-id $VPC_ID --target-type ip --query "TargetGroups[0].TargetGroupArn" --output text --region $AWS_REGION)
  aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN --region $AWS_REGION

  LB_DNS=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query "LoadBalancers[0].DNSName" --output text --region $AWS_REGION)
fi

# === Create ECS Service ===
SERVICE_OPTS=(--cluster $CLUSTER_NAME --service-name $SERVICE_NAME --task-definition $TASK_NAME --desired-count 1 --launch-type FARGATE --region $AWS_REGION)
SERVICE_OPTS+=(--network-configuration "awsvpcConfiguration={subnets=[$SUBNET1_ID,$SUBNET2_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}")
[[ "$USE_LB" == "yes" ]] && SERVICE_OPTS+=(--load-balancers "targetGroupArn=$TG_ARN,containerName=$CONTAINER_NAME,containerPort=$CONTAINER_PORT")
aws ecs create-service "${SERVICE_OPTS[@]}"

# === Wait for task IP if no LB ===
if [[ "$USE_LB" != "yes" ]]; then
  echo -e "${CYAN}⏳ Waiting for ECS task to be RUNNING...${NC}"
  for i in {1..10}; do
    TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query 'taskArns[0]' --output text --region $AWS_REGION)
    [[ "$TASK_ARN" != "None" && "$TASK_ARN" != "" ]] && break
    sleep 5
  done

  if [[ -n "$TASK_ARN" ]]; then
    aws ecs wait tasks-running --cluster $CLUSTER_NAME --tasks $TASK_ARN --region $AWS_REGION
    ENI_ID=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --region $AWS_REGION)
    TASK_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Association.PublicIp' --output text --region $AWS_REGION)
  fi
fi

# === Output Summary ===
echo -e "\n${GREEN}${BOLD}✅ Setup Complete!${NC}"
[[ "$USE_LB" == "yes" ]] && {
  echo -e "${CYAN}ALB DNS: http://$LB_DNS${NC}"
  echo -e "${YELLOW}⚠ Application may take 30–60 seconds to become reachable at the above URL.${NC}"
  echo -e "${YELLOW}  Test it with: curl -I http://$LB_DNS${NC}"
}
[[ "$TASK_IP" != "" ]] && {
  echo -e "${CYAN}Task Public IP: http://$TASK_IP${NC}"
  echo -e "${YELLOW}⚠ Task may take 20–30 seconds to become responsive.${NC}"
  echo -e "${YELLOW}  Test it with: curl -I http://$TASK_IP:${CONTAINER_PORT}${NC}"
}

# === Save to output.txt ===
cat <<EOF > output.txt
AWS_REGION=$AWS_REGION
CLUSTER_NAME=$CLUSTER_NAME
SERVICE_NAME=$SERVICE_NAME
TASK_NAME=$TASK_NAME
CONTAINER_NAME=$CONTAINER_NAME
CONTAINER_PORT=$CONTAINER_PORT
REPO_NAME=$REPO_NAME
IMAGE_URL=$IMAGE_URL
VPC_ID=$VPC_ID
SUBNET1_ID=$SUBNET1_ID
SUBNET2_ID=$SUBNET2_ID
SECURITY_GROUP_ID=$SG_ID
USE_LB=$USE_LB
ALB_ARN=$ALB_ARN
TG_ARN=$TG_ARN
LB_DNS=$LB_DNS
TASK_IP=$TASK_IP
EOF
