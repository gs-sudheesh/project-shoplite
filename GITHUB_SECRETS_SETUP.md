# GitHub Secrets Setup Guide

This guide explains how to configure GitHub secrets for secure deployment of the ShopLite microservices application.

## Overview

The application has been refactored to use environment variables and GitHub secrets instead of hardcoded values. This ensures sensitive information like passwords, API keys, and configuration details are not exposed in the codebase.

## Required GitHub Secrets

### AWS Configuration
- `AWS_ACCESS_KEY_ID` - AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for deployment  
- `AWS_ACCOUNT_ID` - Your AWS account ID (12-digit number)

### Auth0 Configuration
- `AUTH0_ISSUER_URI` - Your Auth0 domain (e.g., `https://your-domain.auth0.com/`)
- `AUTH0_AUDIENCE` - Your Auth0 API audience (e.g., `https://api.shoplite.com`)

### Database Configuration
- `DB_USERNAME` - PostgreSQL database username (default: `shoplite`)
- `DB_PASSWORD` - PostgreSQL database password
- `DOCUMENTDB_USERNAME` - DocumentDB username (default: `shoplite`)
- `DOCUMENTDB_PASSWORD` - DocumentDB password

### CORS Configuration
- `CORS_ALLOWED_ORIGINS` - Comma-separated list of allowed origins (e.g., `http://localhost:5173,https://yourdomain.com`)

### Load Balancer Configuration
- `ALB_DNS_NAME` - Application Load Balancer DNS name (will be set after first deployment)

### ECS Configuration (Optional)
- `ECS_CAPACITY_PROVIDER` - ECS capacity provider (default: `FARGATE_SPOT`)
- `ECS_CPU` - ECS task CPU units (default: `256`)
- `ECS_MEMORY` - ECS task memory in MB (default: `512`)

### Security Configuration (Optional)
- `ENABLE_ENCRYPTION` - Enable encryption (default: `true`)
- `ENABLE_SSL` - Enable SSL/TLS (default: `false` for dev, `true` for prod)

### Backup Configuration (Optional)
- `BACKUP_RETENTION_DAYS` - Database backup retention in days (default: `1`)
- `LOG_RETENTION_DAYS` - CloudWatch log retention in days (default: `7`)

## How to Set Up GitHub Secrets

### 1. Navigate to Repository Settings
1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### 2. Add Repository Secrets
1. Click **New repository secret**
2. Enter the secret name (exactly as listed above)
3. Enter the secret value
4. Click **Add secret**
5. Repeat for all required secrets

### 3. Set Up Environment-Specific Secrets (Recommended)
For better security, set up environment-specific secrets:

1. In **Secrets and variables** → **Actions**
2. Click **Environments** tab
3. Create environments: `dev`, `staging`, `prod`
4. For each environment, add the appropriate secrets

## File Structure

```
project-shoplite/
├── aws/
│   └── environment/
│       ├── dev.env.template          # Template with placeholder values
│       └── dev.env                   # Actual values (ignored by git)
├── .github/
│   └── workflows/
│       └── deploy-aws.yml.template   # GitHub Actions workflow template
├── scripts/
│   ├── deploy-aws.sh                 # Updated to use environment variables
│   ├── setup-ecr.sh                  # ECR setup script
│   ├── build-images.sh               # Docker build script
│   └── cleanup-aws.sh                # Cleanup script
└── GITHUB_SECRETS_SETUP.md           # This file
```

## Usage

### Local Development
1. Copy the template: `cp aws/environment/dev.env.template aws/environment/dev.env`
2. Fill in actual values in `dev.env`
3. Run deployment scripts locally

### GitHub Actions Deployment
1. Copy the workflow template: `cp .github/workflows/deploy-aws.yml.template .github/workflows/deploy-aws.yml`
2. Set up all required secrets in GitHub
3. Push to trigger deployment or use manual workflow dispatch

### Environment Variables Priority
1. GitHub Secrets (highest priority)
2. Environment file (`aws/environment/{env}.env`)
3. Default values in scripts (lowest priority)

## Security Best Practices

1. **Never commit actual secrets** to the repository
2. **Use environment-specific secrets** for different deployment environments
3. **Rotate secrets regularly** especially database passwords and API keys
4. **Use least privilege principle** for AWS IAM roles
5. **Enable MFA** on your GitHub account
6. **Review secret access logs** regularly

## Troubleshooting

### Common Issues

1. **Missing secrets**: Ensure all required secrets are set in GitHub
2. **Wrong environment**: Check that the correct environment is selected
3. **Permission errors**: Verify AWS credentials have necessary permissions
4. **Template not found**: Ensure you've copied the template files

### Validation Commands

```bash
# Check if environment file exists
ls -la aws/environment/

# Validate environment variables
source aws/environment/dev.env && env | grep -E "(AWS|AUTH0|DB_)"

# Test AWS credentials
aws sts get-caller-identity
```

## Migration from Hardcoded Values

If you're migrating from hardcoded values:

1. **Backup your current configuration**
2. **Set up GitHub secrets** with your current values
3. **Test deployment** in a dev environment first
4. **Update production** after successful testing

## Support

For issues or questions:
1. Check the GitHub Actions logs for detailed error messages
2. Verify all secrets are correctly set
3. Ensure AWS credentials have proper permissions
4. Review the CloudFormation stack events in AWS Console
