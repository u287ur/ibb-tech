
#!/bin/bash
# === Disable AWS CLI pager ===
export AWS_PAGER=""
# === Color codes ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# === Configuration ===
AWS_REGION="us-east-1"
CLUSTER_NAME="flask-cluster"
SERVICE_NAME="flask-service"
TASK_NAME="flask-task"
REPO_NAME="flask-ecr-repo"
SG_NAME="flask-sg"

# === Get AWS account ID ===
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ $? -ne 0 ]; then
 echo -e "${RED}❌ Failed to get AWS account ID. Make sure AWS CLI is configured.${NC}"
 exit 1
fi

echo -e "${CYAN}${BOLD}🧹 Starting cleanup of AWS ECS and ECR resources...${NC}"

# === Step 1: Stop running tasks (if any) ===
echo -e "\n${CYAN}${BOLD}Step 1: Checking for running ECS tasks...${NC}"
TASKS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query "taskArns[]" --output text)
if [ -n "$TASKS" ]; then
 echo -e "${YELLOW}Stopping running tasks...${NC}"
 for task in $TASKS; do
   aws ecs stop-task --cluster $CLUSTER_NAME --task $task >/dev/null 2>&1
   echo -e "${GREEN}✔ Stopped task: $task${NC}"
 done
else
 echo -e "${GREEN}✔ No running tasks found.${NC}"
fi

# === Step 2: Delete ECS Service ===
echo -e "\n${CYAN}${BOLD}Step 2: Deleting ECS service '${SERVICE_NAME}'...${NC}"
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].status" --output text | grep -q "ACTIVE"
if [ $? -eq 0 ]; then
 aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force >/dev/null 2>&1
 echo -e "${GREEN}✔ Service deleted.${NC}"
 echo -e "${YELLOW}⏳ Waiting for service to become inactive...${NC}"
 aws ecs wait services-inactive --cluster $CLUSTER_NAME --services $SERVICE_NAME
else
 echo -e "${GREEN}✔ ECS service already deleted or not found.${NC}"
fi

# === Step 3: Delete ECS Cluster ===
echo -e "\n${CYAN}${BOLD}Step 3: Deleting ECS cluster '${CLUSTER_NAME}'...${NC}"
aws ecs delete-cluster --cluster $CLUSTER_NAME >/dev/null 2>&1
if [ $? -eq 0 ]; then
 echo -e "${GREEN}✔ Cluster deleted.${NC}"
else
 echo -e "${YELLOW}⚠️ Cluster not found or already deleted.${NC}"
fi

# === Step 4: Deregister all Task Definitions ===
echo -e "\n${CYAN}${BOLD}Step 4: Deregistering ECS Task Definitions (family: $TASK_NAME)...${NC}"
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $TASK_NAME --query "taskDefinitionArns[]" --output text)
if [ -n "$TASK_DEFS" ]; then
 for def in $TASK_DEFS; do
   aws ecs deregister-task-definition --task-definition $def >/dev/null 2>&1
   echo -e "${GREEN}✔ Deregistered: $def${NC}"
 done
else
 echo -e "${GREEN}✔ No task definitions to deregister.${NC}"
fi

# === Step 5: Delete ECR Repository ===
echo -e "\n${CYAN}${BOLD}Step 5: Deleting ECR repository '${REPO_NAME}'...${NC}"
aws ecr delete-repository --repository-name $REPO_NAME --force >/dev/null 2>&1
if [ $? -eq 0 ]; then
 echo -e "${GREEN}✔ ECR repository deleted.${NC}"
else
 echo -e "${YELLOW}⚠️ Repository not found or already deleted.${NC}"
fi
# === Step 6: Delete Security Group ===
echo -e "\n${CYAN}${BOLD}Step 6: Deleting Security Group '${SG_NAME}'...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$SG_NAME Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
 aws ec2 delete-security-group --group-id $SG_ID >/dev/null 2>&1
 if [ $? -eq 0 ]; then
   echo -e "${GREEN}✔ Security group deleted.${NC}"
 else
   echo -e "${YELLOW}⚠️ Could not delete security group. It might still be attached or in use.${NC}"
 fi
else
 echo -e "${GREEN}✔ Security group not found or already deleted.${NC}"
fi

# === Done ===
echo -e "\n${CYAN}${BOLD}✅ Cleanup completed successfully.${NC}\n"


