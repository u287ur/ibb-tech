#!/bin/bash

# === Disable AWS CLI pager ===
export AWS_PAGER=""

# === Colors ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# === Load output.txt ===
if [[ ! -f output.txt ]]; then
  echo -e "${RED}❌ output.txt not found.${NC}"
  exit 1
fi

while IFS='=' read -r key value; do
  export "$key"="$value"
done < output.txt

VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text --region "$AWS_REGION")

echo -e "${YELLOW}${BOLD}\nResources to delete:${NC}"
[[ "$SERVICE_NAME" ]] && echo -e "${BOLD}- ECS Service:${NC} ${CYAN}$SERVICE_NAME${NC}"
[[ "$CLUSTER_NAME" ]] && echo -e "${BOLD}- ECS Cluster:${NC} ${CYAN}$CLUSTER_NAME${NC}"
[[ "$TASK_NAME" ]] && echo -e "${BOLD}- Task Definition:${NC} ${CYAN}$TASK_NAME${NC}"
[[ "$REPO_NAME" ]] && echo -e "${BOLD}- ECR Repo:${NC} ${CYAN}$REPO_NAME${NC}"
[[ "$VPC_ID" ]] && echo -e "${BOLD}- VPC:${NC} ${CYAN}$VPC_ID${NC} (${VPC_NAME:-no-name})"
[[ "$USE_LB" == "yes" ]] && {
  echo -e "${BOLD}- Load Balancer:${NC} ${CYAN}$ALB_ARN${NC}"
  echo -e "${BOLD}- Target Group:${NC} ${CYAN}$TG_ARN${NC}"
}

read -p $'\nProceed with deletion? (yes/no): ' CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo -e "${RED}❌ Cancelled.${NC}"
  exit 0
fi

# === ECS ===
echo -e "${CYAN}🧨 Deleting ECS...${NC}"
aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 0 --region "$AWS_REGION" 2>/dev/null
sleep 5
aws ecs delete-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --force --region "$AWS_REGION" 2>/dev/null
aws ecs deregister-task-definition --task-definition "$TASK_NAME" --region "$AWS_REGION" 2>/dev/null
aws ecs delete-cluster --cluster "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null
aws ecr delete-repository --repository-name "$REPO_NAME" --force --region "$AWS_REGION" 2>/dev/null

# === ALB ===
if [[ "$USE_LB" == "yes" ]]; then
  echo -e "${CYAN}🧨 Deleting Load Balancer...${NC}"
  LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" \
    --query 'Listeners[0].ListenerArn' --output text --region "$AWS_REGION" 2>/dev/null)
  if [[ -n "$LISTENER_ARN" ]]; then
    aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" --region "$AWS_REGION"
  fi
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$AWS_REGION"
  aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" --region "$AWS_REGION"
  if [[ -n "$TG_ARN" ]]; then
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$AWS_REGION"
  fi
  sleep 5
fi

# === ENIs ===
echo -e "${CYAN}🔍 Cleaning ENIs...${NC}"
ENIS=$(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text --region "$AWS_REGION")
for eni in $ENIS; do
  for i in {1..6}; do
    STATUS=$(aws ec2 describe-network-interfaces --network-interface-ids "$eni" \
      --query 'NetworkInterfaces[0].Status' --output text --region "$AWS_REGION" 2>/dev/null)
    if [[ "$STATUS" == "available" ]]; then
      aws ec2 delete-network-interface --network-interface-id "$eni" --region "$AWS_REGION"
      echo -e "${GREEN}✔ ENI $eni deleted.${NC}"
      break
    elif [[ "$STATUS" == "None" || "$STATUS" == "" ]]; then
      break
    fi
    sleep 5
  done
done

# === Internet Gateway ===
echo -e "${CYAN}🛠 Detach & Delete IGW...${NC}"
IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' --output text --region "$AWS_REGION")
if [[ -n "$IGW_ID" && "$IGW_ID" != "None" ]]; then
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION"
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$AWS_REGION"
fi

# === Subnets ===
[[ -n "$SUBNET1_ID" ]] && aws ec2 delete-subnet --subnet-id "$SUBNET1_ID" --region "$AWS_REGION"
[[ -n "$SUBNET2_ID" ]] && aws ec2 delete-subnet --subnet-id "$SUBNET2_ID" --region "$AWS_REGION"

# === Route Table ===
MAIN_ASSOC_ID=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" \
  --query "RouteTables[?Associations[?Main==\`true\`]].Associations[0].RouteTableAssociationId" \
  --output text --region "$AWS_REGION")

MAIN_RT_ID=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" \
  --query "RouteTables[?Associations[?Main==\`true\`]].RouteTableId" \
  --output text --region "$AWS_REGION")

NEW_RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --query 'RouteTable.RouteTableId' --output text --region "$AWS_REGION")

aws ec2 replace-route-table-association \
  --association-id "$MAIN_ASSOC_ID" \
  --route-table-id "$NEW_RT_ID" --region "$AWS_REGION"
sleep 3
aws ec2 delete-route-table --route-table-id "$MAIN_RT_ID" --region "$AWS_REGION" 2>/dev/null

ROUTE_TABLES=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'RouteTables[*].RouteTableId' --output text --region "$AWS_REGION")
for rtb in $ROUTE_TABLES; do
  aws ec2 delete-route-table --route-table-id "$rtb" --region "$AWS_REGION" 2>/dev/null
done

# === SG ===
[[ -n "$SECURITY_GROUP_ID" ]] && aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" --region "$AWS_REGION"
[[ -n "$LB_SG_ID" ]] && aws ec2 delete-security-group --group-id "$LB_SG_ID" --region "$AWS_REGION"

# === VPC ===
echo -e "${CYAN}🧨 Deleting VPC...${NC}"
for i in {1..10}; do
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" && {
    echo -e "${GREEN}✔ VPC $VPC_ID deleted.${NC}"
    break
  } || {
    echo -e "${RED}❌ VPC still has dependencies. Retry ($i)...${NC}"
    sleep 10
  }
done

# === Final ===
echo -e "${GREEN}✅ Cleanup complete.${NC}"
