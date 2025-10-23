#!/bin/bash

# Cleanup AWS Resources for ShopLite
# This script removes all AWS resources created for ShopLite deployment

set -e

# Configuration
ENVIRONMENT=${ENVIRONMENT:-dev}
AWS_REGION=${AWS_REGION:-ap-southeast-2}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up AWS resources for ShopLite${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}AWS Region: ${AWS_REGION}${NC}"
echo ""

# Function to delete CloudFormation stack
delete_stack() {
    local stack_name=$1
    
    echo -e "${YELLOW}🗑️  Deleting stack: ${stack_name}${NC}"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${BLUE}Deleting stack ${stack_name}...${NC}"
        aws cloudformation delete-stack \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
        
        echo -e "${BLUE}Waiting for stack deletion to complete...${NC}"
        aws cloudformation wait stack-delete-complete \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
        
        echo -e "${GREEN}✅ Stack ${stack_name} deleted successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Stack ${stack_name} does not exist${NC}"
    fi
}

# Function to delete ECR repositories
delete_ecr_repositories() {
    echo -e "${YELLOW}🗑️  Deleting ECR repositories...${NC}"
    
    local repositories=(
        "shoplite-eureka"
        "shoplite-api-gateway"
        "shoplite-order"
        "shoplite-catalog"
        "shoplite-auth"
        "shoplite-frontend"
    )
    
    for repo in "${repositories[@]}"; do
        echo -e "${BLUE}Deleting ECR repository: ${repo}${NC}"
        if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
            # Delete all images first
            aws ecr list-images --repository-name "$repo" --region "$AWS_REGION" --query 'imageIds[*]' --output json | \
            aws ecr batch-delete-image --repository-name "$repo" --region "$AWS_REGION" --image-ids file:///dev/stdin 2>/dev/null || true
            
            # Delete repository
            aws ecr delete-repository --repository-name "$repo" --region "$AWS_REGION" --force
            echo -e "${GREEN}✅ ECR repository ${repo} deleted${NC}"
        else
            echo -e "${YELLOW}⚠️  ECR repository ${repo} does not exist${NC}"
        fi
    done
}

# Function to delete CloudWatch log groups
delete_log_groups() {
    echo -e "${YELLOW}🗑️  Deleting CloudWatch log groups...${NC}"
    
    local log_groups=(
        "/ecs/${ENVIRONMENT}-shoplite"
        "/aws/msk/${ENVIRONMENT}-shoplite"
    )
    
    for log_group in "${log_groups[@]}"; do
        echo -e "${BLUE}Deleting log group: ${log_group}${NC}"
        if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$AWS_REGION" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
            aws logs delete-log-group --log-group-name "$log_group" --region "$AWS_REGION"
            echo -e "${GREEN}✅ Log group ${log_group} deleted${NC}"
        else
            echo -e "${YELLOW}⚠️  Log group ${log_group} does not exist${NC}"
        fi
    done
}

# Main cleanup function
main() {
    echo -e "${BLUE}🔧 Starting cleanup process...${NC}"
    
    # Delete stacks in reverse order (dependencies first)
    delete_stack "${ENVIRONMENT}-shoplite-ecs"
    delete_stack "${ENVIRONMENT}-shoplite-databases"
    delete_stack "${ENVIRONMENT}-shoplite-vpc"
    
    # Delete ECR repositories
    delete_ecr_repositories
    
    # Delete CloudWatch log groups
    delete_log_groups
    
    echo ""
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Cleanup Summary:${NC}"
    echo -e "${BLUE}  - Environment: ${ENVIRONMENT}${NC}"
    echo -e "${BLUE}  - AWS Region: ${AWS_REGION}${NC}"
    echo -e "${BLUE}  - All CloudFormation stacks deleted${NC}"
    echo -e "${BLUE}  - All ECR repositories deleted${NC}"
    echo -e "${BLUE}  - All CloudWatch log groups deleted${NC}"
    echo ""
    echo -e "${YELLOW}💡 Note: Some resources may take a few minutes to fully delete${NC}"
    echo -e "${YELLOW}  Check AWS Console to verify all resources are removed${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
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

# Function to show what will be deleted
show_preview() {
    echo -e "${BLUE}📋 Resources that will be deleted:${NC}"
    echo ""
    
    # Check CloudFormation stacks
    echo -e "${YELLOW}CloudFormation Stacks:${NC}"
    local stacks=(
        "${ENVIRONMENT}-shoplite-ecs"
        "${ENVIRONMENT}-shoplite-databases"
        "${ENVIRONMENT}-shoplite-vpc"
    )
    
    for stack in "${stacks[@]}"; do
        if aws cloudformation describe-stacks --stack-name "$stack" --region "$AWS_REGION" >/dev/null 2>&1; then
            echo -e "${RED}  ❌ ${stack} (exists)${NC}"
        else
            echo -e "${GREEN}  ✅ ${stack} (not found)${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}ECR Repositories:${NC}"
    local repositories=(
        "shoplite-eureka"
        "shoplite-api-gateway"
        "shoplite-order"
        "shoplite-catalog"
        "shoplite-auth"
        "shoplite-frontend"
    )
    
    for repo in "${repositories[@]}"; do
        if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
            echo -e "${RED}  ❌ ${repo} (exists)${NC}"
        else
            echo -e "${GREEN}  ✅ ${repo} (not found)${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}CloudWatch Log Groups:${NC}"
    local log_groups=(
        "/ecs/${ENVIRONMENT}-shoplite"
        "/aws/msk/${ENVIRONMENT}-shoplite"
    )
    
    for log_group in "${log_groups[@]}"; do
        if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$AWS_REGION" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
            echo -e "${RED}  ❌ ${log_group} (exists)${NC}"
        else
            echo -e "${GREEN}  ✅ ${log_group} (not found)${NC}"
        fi
    done
}

# Parse command line arguments
case "${1:-cleanup}" in
    "cleanup")
        check_prerequisites
        main
        ;;
    "preview")
        show_preview
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [cleanup|preview|help]"
        echo ""
        echo "Commands:"
        echo "  cleanup - Delete all AWS resources (default)"
        echo "  preview - Show what resources will be deleted"
        echo "  help    - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  ENVIRONMENT  - Environment name (default: dev)"
        echo "  AWS_REGION   - AWS region (default: us-east-1)"
        echo ""
        echo "⚠️  WARNING: This will permanently delete all AWS resources!"
        echo "   Make sure you want to delete everything before running this script."
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
