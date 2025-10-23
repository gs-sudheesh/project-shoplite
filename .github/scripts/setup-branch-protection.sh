#!/bin/bash

# GitHub Branch Protection Setup Script
# This script helps configure branch protection rules for the ShopLite project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  GitHub Branch Protection Setup${NC}"
echo "=================================="
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo -e "${BLUE}📦 Repository: ${REPO}${NC}"
echo ""

# Function to set up branch protection
setup_branch_protection() {
    local branch=$1
    echo -e "${YELLOW}🔧 Setting up protection for branch: ${branch}${NC}"
    
    # Set up branch protection rules
    gh api repos/:owner/:repo/branches/${branch}/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["PR Build and Test","Branch Protection and PR Validation","Merge Protection"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false \
        --field required_conversation_resolution=true \
        --field require_linear_history=false \
        --field require_signed_commits=false
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Branch protection configured for ${branch}${NC}"
    else
        echo -e "${RED}❌ Failed to configure branch protection for ${branch}${NC}"
        return 1
    fi
}

# Set up protection for main and develop branches
echo -e "${BLUE}🔧 Configuring branch protection rules...${NC}"
echo ""

setup_branch_protection "main"
setup_branch_protection "develop"

echo ""
echo -e "${GREEN}🎉 Branch protection setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 What was configured:${NC}"
echo "  ✅ Required status checks:"
echo "     - PR Build and Test"
echo "     - Branch Protection and PR Validation"
echo "     - Merge Protection"
echo "  ✅ Require pull request reviews (1 approval)"
echo "  ✅ Require conversation resolution"
echo "  ✅ Require branches to be up to date"
echo "  ✅ Disable force pushes"
echo "  ✅ Disable branch deletion"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Test the workflows by creating a PR"
echo "  2. Verify that direct commits are blocked"
echo "  3. Ensure builds run on PR creation"
echo "  4. Confirm merge protection works"
echo ""
echo -e "${BLUE}🔗 Useful commands:${NC}"
echo "  - View branch protection: gh api repos/:owner/:repo/branches/main/protection"
echo "  - Test PR creation: Create a test PR and verify workflows run"
echo "  - Monitor builds: Check the Actions tab in GitHub"
echo ""
echo -e "${GREEN}✅ Setup complete! Your repository is now protected.${NC}"
