#!/bin/bash

# Setup ECR Repositories for ShopLite Microservices
# This script creates ECR repositories and builds/pushes Docker images

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}
PROJECT_NAME="shoplite"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Services to create repositories for
SERVICES=(
    "eureka-server"
    "api-gateway"
    "order-service"
    "catalog-service"
    "auth-service"
    "frontend"
)

echo -e "${BLUE}🚀 Setting up ECR repositories for ShopLite microservices${NC}"
echo -e "${BLUE}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${BLUE}AWS Region: ${AWS_REGION}${NC}"
echo ""

# Function to create ECR repository
create_ecr_repository() {
    local service_name=$1
    local repo_name="${PROJECT_NAME}-${service_name}"
    
    echo -e "${YELLOW}📦 Creating ECR repository: ${repo_name}${NC}"
    
    # Check if repository already exists
    if aws ecr describe-repositories --repository-names "$repo_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Repository ${repo_name} already exists${NC}"
    else
        # Create repository
        aws ecr create-repository \
            --repository-name "$repo_name" \
            --region "$AWS_REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        
        echo -e "${GREEN}✅ Created repository: ${repo_name}${NC}"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    local service_name=$1
    local repo_name="${PROJECT_NAME}-${service_name}"
    local image_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo_name}:latest"
    
    echo -e "${YELLOW}🔨 Building and pushing image for ${service_name}${NC}"
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Build image
    echo -e "${BLUE}Building Docker image for ${service_name}...${NC}"
    docker build -t "$repo_name:latest" -f "${service_name}/Dockerfile" .
    
    # Tag image
    docker tag "$repo_name:latest" "$image_uri"
    
    # Push image
    echo -e "${BLUE}Pushing image to ECR...${NC}"
    docker push "$image_uri"
    
    echo -e "${GREEN}✅ Successfully pushed ${image_uri}${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Creating ECR repositories...${NC}"
    for service in "${SERVICES[@]}"; do
        create_ecr_repository "$service"
    done
    
    echo ""
    echo -e "${BLUE}🔨 Building and pushing Docker images...${NC}"
    for service in "${SERVICES[@]}"; do
        build_and_push_image "$service"
    done
    
    echo ""
    echo -e "${GREEN}🎉 ECR setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Summary:${NC}"
    echo -e "${BLUE}  - Created ${#SERVICES[@]} ECR repositories${NC}"
    echo -e "${BLUE}  - Built and pushed ${#SERVICES[@]} Docker images${NC}"
    echo -e "${BLUE}  - All images are tagged as 'latest'${NC}"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo -e "${YELLOW}  1. Set environment variables for AWS deployment${NC}"
    echo -e "${YELLOW}  2. Deploy infrastructure using CloudFormation${NC}"
    echo -e "${YELLOW}  3. Deploy services to ECS Fargate${NC}"
    echo ""
    echo -e "${BLUE}🔗 ECR Repository URLs:${NC}"
    for service in "${SERVICES[@]}"; do
        local repo_name="${PROJECT_NAME}-${service}"
        echo -e "${BLUE}  - ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo_name}:latest${NC}"
    done
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
    echo ""
}

# Run the script
check_prerequisites
main
