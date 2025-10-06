# GitHub Actions Setup Guide

This guide explains the GitHub Actions workflows configured for the ShopLite project to enforce branch protection, build validation, and merge requirements.

## 🛡️ Branch Protection Overview

The project implements a comprehensive CI/CD pipeline that ensures:

1. **No direct commits** to `main` or `develop` branches
2. **Build validation** for all Pull Requests
3. **Security scanning** and quality checks
4. **Merge protection** requiring successful builds

## 📋 Workflow Files

### 1. `branch-protection.yml`
**Purpose:** Prevents direct commits and validates PR structure

**Triggers:**
- Push to `main` or `develop` branches
- Pull Requests targeting `main` or `develop`

**Jobs:**
- **prevent-direct-commits:** Blocks direct commits to protected branches
- **validate-pr:** Validates PR structure and requirements
- **build-validation:** Basic build validation
- **security-scan:** Scans for vulnerabilities and secrets

### 2. `pr-build.yml`
**Purpose:** Comprehensive build and test pipeline for PRs

**Triggers:**
- Pull Requests targeting `main` or `develop`
- Events: `opened`, `synchronize`, `reopened`

**Jobs:**
- **build-java-services:** Builds and tests all Java microservices
- **build-frontend:** Builds and tests the React frontend
- **docker-build-test:** Tests Docker image builds
- **integration-tests:** Runs integration tests (when available)
- **security-quality:** Security and quality checks
- **build-summary:** Generates build summary and PR comments

### 3. `merge-protection.yml`
**Purpose:** Enforces successful builds before allowing merges

**Triggers:**
- Pull Requests targeting `main` or `develop`
- Events: `opened`, `synchronize`, `reopened`, `ready_for_review`

**Jobs:**
- **check-merge-readiness:** Validates PR is ready for merge
- **wait-for-checks:** Waits for all required checks to pass
- **final-validation:** Final security and validation checks
- **update-pr-status:** Updates PR with merge status

## 🔧 Required GitHub Settings

### 1. Branch Protection Rules

Configure these settings in **Settings → Branches** for both `main` and `develop`:

#### **Required Status Checks:**
- ✅ `PR Build and Test`
- ✅ `Branch Protection and PR Validation`
- ✅ `Merge Protection`

#### **Branch Protection Options:**
- ✅ **Require a pull request before merging**
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits** (optional)
- ✅ **Require linear history** (optional)

#### **Restrictions:**
- ✅ **Restrict pushes that create files** (optional)
- ✅ **Allow force pushes:** ❌ Disabled
- ✅ **Allow deletions:** ❌ Disabled

### 2. Required Repository Settings

#### **Actions Permissions:**
- ✅ **Actions:** Enabled
- ✅ **Workflow permissions:** Read and write permissions
- ✅ **Allow GitHub Actions to create and approve pull requests**

#### **Security Settings:**
- ✅ **Dependency graph:** Enabled
- ✅ **Dependabot alerts:** Enabled
- ✅ **Dependabot security updates:** Enabled
- ✅ **Code scanning:** Enabled (when available)

## 🚀 How It Works

### **For Developers:**

#### **1. Creating a Feature Branch:**
```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name

# Make your changes
git add .
git commit -m "feat: add new feature"

# Push the branch
git push origin feature/your-feature-name
```

#### **2. Creating a Pull Request:**
1. Go to GitHub and create a PR targeting `main` or `develop`
2. The workflows will automatically trigger
3. Wait for all checks to pass
4. Request reviews from team members
5. Merge when approved and all checks pass

#### **3. What Happens Automatically:**
- ✅ **Build validation** runs on every push
- ✅ **Security scanning** checks for vulnerabilities
- ✅ **Quality checks** validate code standards
- ✅ **PR comments** show build status
- ✅ **Merge protection** prevents merging failed builds

### **For Maintainers:**

#### **1. Reviewing PRs:**
- Check the build status in PR comments
- Review code changes
- Approve when ready
- Merge when all checks pass

#### **2. Handling Failed Builds:**
- Check the Actions tab for detailed logs
- Identify the failing job
- Work with the developer to fix issues
- Re-run checks after fixes

## 📊 Build Status Indicators

### **✅ Success Indicators:**
- All jobs show green checkmarks
- PR comment shows "🎉 All checks passed!"
- Merge button is enabled (when approved)

### **❌ Failure Indicators:**
- Red X marks on failed jobs
- PR comment shows "❌ Some checks failed"
- Merge button is disabled
- Detailed error logs in Actions tab

## 🔍 Troubleshooting

### **Common Issues:**

#### **1. Direct Commit Blocked:**
```
❌ Direct commits to main are not allowed.
✅ Please create a Pull Request instead.
```
**Solution:** Create a feature branch and PR

#### **2. Build Failures:**
- Check the Actions tab for detailed logs
- Look for specific error messages
- Fix the issues and push again

#### **3. Security Scan Failures:**
- Review the security scan results
- Fix any vulnerabilities found
- Remove any hardcoded secrets

#### **4. Merge Conflicts:**
- Update your branch with the latest changes
- Resolve conflicts
- Push the updated branch

### **Getting Help:**
1. Check the Actions tab for detailed logs
2. Review the PR comments for status updates
3. Check the Security tab for vulnerability details
4. Contact the team for assistance

## 🛠️ Customization

### **Adding New Checks:**
1. Edit the workflow files in `.github/workflows/`
2. Add new jobs or steps as needed
3. Update the required status checks in branch protection

### **Modifying Build Process:**
1. Update the build commands in `pr-build.yml`
2. Add new test suites or quality checks
3. Configure different environments as needed

### **Security Enhancements:**
1. Add additional security scanners
2. Configure secret scanning
3. Set up dependency vulnerability checks

## 📈 Monitoring and Metrics

### **Build Metrics:**
- Build success rate
- Average build time
- Most common failure reasons
- PR merge time

### **Security Metrics:**
- Vulnerability detection rate
- Security scan results
- Secret exposure incidents
- Dependency update frequency

## 🔄 Maintenance

### **Regular Tasks:**
- Review and update dependencies
- Monitor build performance
- Update security scanners
- Review and update workflow configurations

### **Monthly Reviews:**
- Analyze build metrics
- Review security scan results
- Update branch protection rules
- Optimize workflow performance

---

**Last Updated:** $(date)
**Maintained By:** Development Team
**Next Review:** Monthly
