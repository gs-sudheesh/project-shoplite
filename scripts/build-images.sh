#!/bin/bash

# Build Docker Images for ShopLite Microservices
# This script builds all Docker images locally for testing

set -e

# Configuration
PROJECT_NAME="shoplite"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Services to build
SERVICES=(
    "eureka-server"
    "api-gateway"
    "order-service"
    "catalog-service"
    "auth-service"
    "frontend"
)

echo -e "${BLUE}🔨 Building Docker images for ShopLite microservices${NC}"
echo ""

# Function to build Docker image
build_image() {
    local service_name=$1
    local image_name="${PROJECT_NAME}-${service_name}"
    
    echo -e "${YELLOW}🔨 Building image for ${service_name}...${NC}"
    
    # Check if Dockerfile exists
    if [ ! -f "${service_name}/Dockerfile" ]; then
        echo -e "${RED}❌ Dockerfile not found for ${service_name}${NC}"
        return 1
    fi
    
    # Build image
    docker build -t "$image_name:latest" -f "${service_name}/Dockerfile" .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully built ${image_name}:latest${NC}"
    else
        echo -e "${RED}❌ Failed to build ${image_name}${NC}"
        return 1
    fi
}

# Function to show image details
show_image_details() {
    local service_name=$1
    local image_name="${PROJECT_NAME}-${service_name}"
    
    echo -e "${BLUE}📊 Image details for ${service_name}:${NC}"
    docker images "$image_name:latest" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
}

# Main execution
main() {
    local failed_builds=()
    
    for service in "${SERVICES[@]}"; do
        if build_image "$service"; then
            show_image_details "$service"
        else
            failed_builds+=("$service")
        fi
    done
    
    echo -e "${BLUE}📋 Build Summary:${NC}"
    echo -e "${GREEN}✅ Successful builds: $((${#SERVICES[@]} - ${#failed_builds[@]}))${NC}"
    
    if [ ${#failed_builds[@]} -gt 0 ]; then
        echo -e "${RED}❌ Failed builds: ${#failed_builds[@]}${NC}"
        echo -e "${RED}Failed services: ${failed_builds[*]}${NC}"
        exit 1
    else
        echo -e "${GREEN}🎉 All images built successfully!${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo -e "${YELLOW}  1. Test images locally: docker-compose -f compose-aws.yml up${NC}"
    echo -e "${YELLOW}  2. Push to ECR: ./scripts/setup-ecr.sh${NC}"
    echo -e "${YELLOW}  3. Deploy to AWS: ./scripts/deploy-aws.sh${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon is not running. Please start Docker first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
    echo ""
}

# Run the script
check_prerequisites
main
