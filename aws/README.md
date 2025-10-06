# AWS Deployment Guide for ShopLite Microservices

This guide provides step-by-step instructions for deploying the ShopLite microservices to AWS using ECS Fargate, RDS, DocumentDB, and MSK.

## 🏗️ Architecture Overview

The AWS deployment uses the following services:

- **ECS Fargate**: Container orchestration for microservices
- **RDS PostgreSQL**: Managed database for orders and auth services
- **DocumentDB**: Managed MongoDB-compatible database for catalog service
- **MSK**: Managed Kafka for event streaming
- **Application Load Balancer**: Traffic routing and load balancing
- **CloudWatch**: Logging and monitoring
- **ECR**: Container image registry
- **Service Discovery**: Internal service communication

## 📋 Prerequisites

### 1. AWS CLI Setup
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
```

### 2. Docker Setup
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Required Environment Variables
```bash
# Set your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ENVIRONMENT=dev
```

## 🚀 Deployment Steps

### Step 1: Build and Push Docker Images

```bash
# Build all Docker images
./scripts/build-images.sh

# Push images to ECR
./scripts/setup-ecr.sh
```

### Step 2: Deploy Infrastructure

```bash
# Deploy all AWS infrastructure
./scripts/deploy-aws.sh

# Check deployment status
./scripts/deploy-aws.sh status
```

### Step 3: Verify Deployment

```bash
# Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name dev-shoplite-ecs \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
  --output text)

# Test the application
curl http://$ALB_DNS/health
```

## 📊 Cost Estimation

### Development Environment (1-day testing)
| Service | Cost/Day | Notes |
|---------|----------|-------|
| ECS Fargate | $2-5 | 5 services, 0.25 vCPU each |
| RDS PostgreSQL | $1-3 | db.t3.micro, single AZ |
| DocumentDB | $2-4 | db.t3.medium, single AZ |
| MSK | $3-6 | 2 brokers, kafka.t3.small |
| ALB | $1-2 | Application Load Balancer |
| **Total** | **$9-20/day** | **~$15 average** |

### Production Environment
| Service | Cost/Month | Notes |
|---------|------------|-------|
| ECS Fargate | $50-100 | 5 services, 0.5 vCPU each |
| RDS PostgreSQL | $30-50 | db.t3.small, Multi-AZ |
| DocumentDB | $60-100 | db.t3.medium, Multi-AZ |
| MSK | $100-200 | 3 brokers, kafka.m5.large |
| ALB | $20-30 | Application Load Balancer |
| **Total** | **$260-480/month** | **~$370 average** |

## 🔧 Configuration Files

### Environment Configuration
- `aws/environment/dev.env` - Development environment variables
- `aws/environment/staging.env` - Staging environment variables
- `aws/environment/prod.env` - Production environment variables

### CloudFormation Templates
- `aws/infrastructure/cloudformation/vpc.yml` - VPC and networking
- `aws/infrastructure/cloudformation/databases.yml` - RDS, DocumentDB, MSK
- `aws/infrastructure/cloudformation/ecs.yml` - ECS cluster and services

### Docker Configuration
- `compose-aws.yml` - Docker Compose for AWS deployment
- `*/Dockerfile` - Dockerfiles for each microservice

## 🛠️ Scripts

### Build and Deploy Scripts
- `scripts/build-images.sh` - Build Docker images locally
- `scripts/setup-ecr.sh` - Create ECR repositories and push images
- `scripts/deploy-aws.sh` - Deploy infrastructure to AWS
- `scripts/cleanup-aws.sh` - Clean up AWS resources

### Usage Examples
```bash
# Build images
./scripts/build-images.sh

# Deploy to AWS
./scripts/deploy-aws.sh

# Check status
./scripts/deploy-aws.sh status

# Clean up
./scripts/cleanup-aws.sh
```

## 🔍 Monitoring and Troubleshooting

### CloudWatch Logs
```bash
# View ECS service logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/dev-shoplite"

# Stream logs
aws logs tail /ecs/dev-shoplite --follow
```

### ECS Service Status
```bash
# List ECS services
aws ecs list-services --cluster dev-shoplite-cluster

# Describe service
aws ecs describe-services --cluster dev-shoplite-cluster --services dev-shoplite-eureka-server
```

### Health Checks
```bash
# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check ECS task health
aws ecs describe-tasks --cluster dev-shoplite-cluster --tasks <task-arn>
```

## 🔐 Security Considerations

### Network Security
- All services run in private subnets
- Security groups restrict traffic between services
- ALB provides public access only to frontend and API gateway

### Data Security
- RDS and DocumentDB use encryption at rest
- MSK uses encryption in transit and at rest
- ECR images are scanned for vulnerabilities

### Access Control
- IAM roles with minimal required permissions
- ECS tasks use task execution roles
- No hardcoded credentials in containers

## 🚨 Troubleshooting

### Common Issues

#### 1. ECS Tasks Failing to Start
```bash
# Check task definition
aws ecs describe-task-definition --task-definition dev-shoplite-eureka-server

# Check service events
aws ecs describe-services --cluster dev-shoplite-cluster --services dev-shoplite-eureka-server
```

#### 2. Database Connection Issues
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier dev-shoplite-orders-db

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>
```

#### 3. Load Balancer Issues
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names dev-shoplite-alb

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS DocumentDB Documentation](https://docs.aws.amazon.com/documentdb/)
- [AWS MSK Documentation](https://docs.aws.amazon.com/msk/)
- [CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs for error details
3. Check AWS service health status
4. Refer to AWS documentation for specific services
