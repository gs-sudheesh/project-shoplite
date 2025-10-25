#!/bin/bash

# Deploy ShopLite Microservices to AWS
# This script deploys the complete infrastructure and services to AWS

set -e

# Track deployed stacks for cleanup on failure
DEPLOYED_STACKS=()

# Configuration
ENVIRONMENT=${ENVIRONMENT:-dev}
AWS_REGION=${AWS_REGION:-ap-southeast-2}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}

# Load environment variables from template
if [ -f "aws/environment/${ENVIRONMENT}.env" ]; then
    echo -e "${BLUE}📋 Loading environment variables from aws/environment/${ENVIRONMENT}.env${NC}"
    set -a  # automatically export all variables
    source "aws/environment/${ENVIRONMENT}.env"
    set +a
else
    echo -e "${YELLOW}⚠️  Environment file aws/environment/${ENVIRONMENT}.env not found${NC}"
    echo -e "${YELLOW}   Using default values and environment variables${NC}"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying ShopLite microservices to AWS${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${BLUE}AWS Region: ${AWS_REGION}${NC}"
echo ""

# Function to deploy CloudFormation stack
deploy_stack() {
    local stack_name=$1
    local template_file=$2
    shift 2
    local parameters=("$@")
    
    echo -e "${YELLOW}📦 Deploying stack: ${stack_name}${NC}"
    
    # Validate CloudFormation template first
    echo -e "${BLUE}🔍 Validating CloudFormation template: ${template_file}${NC}"
    if ! aws cloudformation validate-template --template-body "file://$template_file" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${RED}❌ CloudFormation template validation failed for ${template_file}${NC}"
        echo -e "${YELLOW}📋 Validation errors:${NC}"
        aws cloudformation validate-template --template-body "file://$template_file" --region "$AWS_REGION"
        exit 1
    fi
    echo -e "${GREEN}✅ CloudFormation template validation passed${NC}"
    
    # Check if stack exists and clean up if in failed state
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        local stack_status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query 'Stacks[0].StackStatus' --output text)
        echo -e "${BLUE}Stack ${stack_name} exists with status: ${stack_status}${NC}"
        
        # If stack is in failed state, delete it first
        if [[ "$stack_status" == "ROLLBACK_COMPLETE" || "$stack_status" == "CREATE_FAILED" || "$stack_status" == "UPDATE_ROLLBACK_COMPLETE" ]]; then
            echo -e "${YELLOW}🗑️  Deleting failed stack ${stack_name}...${NC}"
            aws cloudformation delete-stack --stack-name "$stack_name" --region "$AWS_REGION"
            echo -e "${BLUE}Waiting for stack deletion to complete...${NC}"
            aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region "$AWS_REGION"
            echo -e "${GREEN}✅ Failed stack ${stack_name} deleted successfully${NC}"
        fi
    fi
    
    # Check if stack exists again (after potential cleanup)
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${BLUE}Stack ${stack_name} exists, updating...${NC}"
        aws cloudformation update-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters "${parameters[@]}" \
            --capabilities CAPABILITY_IAM \
            --region "$AWS_REGION"
        
        echo -e "${BLUE}Waiting for stack update to complete...${NC}"
        aws cloudformation wait stack-update-complete \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
    else
        echo -e "${BLUE}Stack ${stack_name} does not exist, creating...${NC}"
        aws cloudformation create-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters "${parameters[@]}" \
            --capabilities CAPABILITY_IAM \
            --region "$AWS_REGION"
        
        echo -e "${BLUE}Waiting for stack creation to complete...${NC}"
        echo -e "${YELLOW}⏳ This may take 10-15 minutes for database stacks...${NC}"
        
        # Add timeout for database stacks (20 minutes)
        if [[ "$stack_name" == *"databases"* ]]; then
            timeout 1200 aws cloudformation wait stack-create-complete \
                --stack-name "$stack_name" \
                --region "$AWS_REGION" || {
                echo -e "${RED}❌ Stack creation timed out or failed${NC}"
                echo -e "${YELLOW}🔍 Checking stack status...${NC}"
                aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query 'Stacks[0].StackStatus' --output text
                echo -e "${YELLOW}📋 Recent stack events:${NC}"
                aws cloudformation describe-stack-events --stack-name "$stack_name" --region "$AWS_REGION" --query 'StackEvents[0:5].[Timestamp,ResourceStatus,ResourceStatusReason]' --output table
                exit 1
            }
        else
            aws cloudformation wait stack-create-complete \
                --stack-name "$stack_name" \
                --region "$AWS_REGION" || {
                echo -e "${RED}❌ Stack creation failed${NC}"
                echo -e "${YELLOW}🔍 Checking stack status...${NC}"
                aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query 'Stacks[0].StackStatus' --output text
                exit 1
            }
        fi
    fi
    
    echo -e "${GREEN}✅ Stack ${stack_name} deployed successfully${NC}"
    
    # Add to deployed stacks list for cleanup tracking
    DEPLOYED_STACKS+=("$stack_name")
}

# Function to get stack outputs
get_stack_output() {
    local stack_name=$1
    local output_key=$2
    
    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text
}

# Function to cleanup on failure
cleanup_on_failure() {
    echo -e "${RED}❌ Deployment failed! Starting cleanup...${NC}"
    echo -e "${YELLOW}🧹 Cleaning up deployed stacks...${NC}"
    
    # Delete stacks in reverse order (dependencies first)
    for ((i=${#DEPLOYED_STACKS[@]}-1; i>=0; i--)); do
        local stack_name="${DEPLOYED_STACKS[i]}"
        echo -e "${YELLOW}🗑️  Deleting stack: ${stack_name}${NC}"
        
        if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
            aws cloudformation delete-stack --stack-name "$stack_name" --region "$AWS_REGION" || true
            echo -e "${BLUE}Stack ${stack_name} deletion initiated${NC}"
        fi
    done
    
    echo -e "${YELLOW}⚠️  Cleanup initiated. Check AWS Console to verify all resources are removed.${NC}"
    echo -e "${YELLOW}   You can also run './scripts/cleanup-aws.sh' to ensure complete cleanup.${NC}"
}

# Set up error trap
trap cleanup_on_failure ERR

# Main deployment function
main() {
    echo -e "${BLUE}🔧 Deploying infrastructure...${NC}"
    
    # 1. Deploy VPC infrastructure
    deploy_stack \
        "${ENVIRONMENT}-shoplite-vpc" \
        "aws/infrastructure/cloudformation/vpc.yml" \
        "ParameterKey=Environment,ParameterValue=${ENVIRONMENT}"
    
    # 2. Deploy databases
    deploy_stack \
        "${ENVIRONMENT}-shoplite-databases" \
        "aws/infrastructure/cloudformation/databases.yml" \
        "ParameterKey=Environment,ParameterValue=${ENVIRONMENT}" \
        "ParameterKey=DBUsername,ParameterValue=${DB_USERNAME}" \
        "ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD}" \
        "ParameterKey=DocumentDBUsername,ParameterValue=${DOCUMENTDB_USERNAME}" \
        "ParameterKey=DocumentDBPassword,ParameterValue=${DOCUMENTDB_PASSWORD}"
    
    # 3. Deploy ECS infrastructure
    deploy_stack \
        "${ENVIRONMENT}-shoplite-ecs" \
        "aws/infrastructure/cloudformation/ecs.yml" \
        "ParameterKey=Environment,ParameterValue=${ENVIRONMENT}" \
        "ParameterKey=AWSAccountId,ParameterValue=${AWS_ACCOUNT_ID}" \
        "ParameterKey=AWSRegion,ParameterValue=${AWS_REGION}" \
        "ParameterKey=Auth0IssuerURI,ParameterValue=${AUTH0_ISSUER_URI}" \
        "ParameterKey=Auth0Audience,ParameterValue=${AUTH0_AUDIENCE}" \
        "ParameterKey=CORSAllowedOrigins,ParameterValue=${CORS_ALLOWED_ORIGINS}" \
        "ParameterKey=DBUsername,ParameterValue=${DB_USERNAME}" \
        "ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD}" \
        "ParameterKey=DocumentDBUsername,ParameterValue=${DOCUMENTDB_USERNAME}" \
        "ParameterKey=DocumentDBPassword,ParameterValue=${DOCUMENTDB_PASSWORD}"
    
    echo ""
    echo -e "${GREEN}🎉 Infrastructure deployment completed successfully!${NC}"
    echo ""
    
    # Get ALB DNS name
    ALB_DNS=$(get_stack_output "${ENVIRONMENT}-shoplite-ecs" "ALBDNSName")
    
    echo -e "${BLUE}📋 Deployment Summary:${NC}"
    echo -e "${BLUE}  - Environment: ${ENVIRONMENT}${NC}"
    echo -e "${BLUE}  - AWS Region: ${AWS_REGION}${NC}"
    echo -e "${BLUE}  - AWS Account: ${AWS_ACCOUNT_ID}${NC}"
    echo -e "${BLUE}  - ALB DNS: ${ALB_DNS}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo -e "${YELLOW}  1. Wait for services to start (5-10 minutes)${NC}"
    echo -e "${YELLOW}  2. Test the application: http://${ALB_DNS}${NC}"
    echo -e "${YELLOW}  3. Check ECS services in AWS Console${NC}"
    echo -e "${YELLOW}  4. Monitor logs in CloudWatch${NC}"
    echo ""
    echo -e "${BLUE}🔗 Useful URLs:${NC}"
    echo -e "${BLUE}  - Application: http://${ALB_DNS}${NC}"
    echo -e "${BLUE}  - API Gateway: http://${ALB_DNS}/api${NC}"
    echo -e "${BLUE}  - Jaeger UI: http://${ALB_DNS}:16686${NC}"
    echo -e "${BLUE}  - ECS Console: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters${NC}"
    echo -e "${BLUE}  - CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups${NC}"
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
    
    # Check if CloudFormation templates exist
    if [ ! -f "aws/infrastructure/cloudformation/vpc.yml" ]; then
        echo -e "${RED}❌ CloudFormation templates not found. Please run from project root.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
    echo ""
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}📊 Deployment Status:${NC}"
    
    # Check VPC stack
    if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-shoplite-vpc" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ VPC Stack: Deployed${NC}"
    else
        echo -e "${RED}❌ VPC Stack: Not deployed${NC}"
    fi
    
    # Check Databases stack
    if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-shoplite-databases" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Databases Stack: Deployed${NC}"
    else
        echo -e "${RED}❌ Databases Stack: Not deployed${NC}"
    fi
    
    # Check ECS stack
    if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-shoplite-ecs" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ECS Stack: Deployed${NC}"
    else
        echo -e "${RED}❌ ECS Stack: Not deployed${NC}"
    fi
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        main
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [deploy|status|help]"
        echo ""
        echo "Commands:"
        echo "  deploy  - Deploy infrastructure to AWS (default)"
        echo "  status  - Show deployment status"
        echo "  help    - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  ENVIRONMENT  - Environment name (default: dev)"
        echo "  AWS_REGION   - AWS region (default: us-east-1)"
        echo "  AWS_ACCOUNT_ID - AWS account ID (auto-detected)"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
