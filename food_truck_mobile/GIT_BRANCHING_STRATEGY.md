# Food Truck App - Git Branching Strategy & Safety Guide

## 🛡️ CRITICAL SAFETY RULES

### NEVER work directly on these branches:
- `main` (or `master`) - Production code
- `develop` - Development integration branch

### ALWAYS create feature branches for ANY changes

## 📋 Branch Structure

```
main (production)
  └── develop (integration)
       ├── feature/social-media-fix
       ├── feature/api-endpoints
       ├── bugfix/404-errors
       └── hotfix/critical-issue
```

## 🚀 Safe Development Workflow

### 1. Starting New Work
```bash
# Always start from develop
git checkout develop
git pull origin develop

# Create a new feature branch
git checkout -b feature/your-feature-name

# Example:
git checkout -b feature/fix-social-media-404
```

### 2. Making Changes Safely
```bash
# Make your changes
# Test thoroughly locally

# Stage specific files (NOT everything)
git add lib/specific-file.dart
git add android/specific-file.gradle

# NEVER use: git add . (too dangerous)

# Commit with descriptive message
git commit -m "fix: resolve 404 error in social media API calls"
```

### 3. Before Pushing - CRITICAL CHECKS
```bash
# 1. Check what you're about to commit
git status
git diff --staged

# 2. Make sure you're on the right branch
git branch

# 3. Test the app locally
flutter test
flutter build appbundle --release

# 4. Pull latest changes
git pull origin develop
```

### 4. Push to GitHub
```bash
# Push your feature branch
git push origin feature/your-feature-name
```

### 5. Create Pull Request
1. Go to GitHub
2. Click "New Pull Request"
3. Base: `develop` <- Compare: `feature/your-feature-name`
4. Review ALL changes
5. Add description of what you fixed/added
6. Request review from team member (if available)

## 🔄 Daily Backup Strategy

### Automatic Safety Net
```bash
# Create a daily backup branch
git checkout -b backup/$(date +%Y-%m-%d)
git add .
git commit -m "Daily backup - $(date +%Y-%m-%d)"
git push origin backup/$(date +%Y-%m-%d)
```

### Local Backup Script
Create `backup.sh`:
```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/mnt/e/FoodTruckBackups/$DATE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Copy entire project
cp -r . "$BACKUP_DIR"

# Create zip archive
zip -r "$BACKUP_DIR.zip" "$BACKUP_DIR"

echo "Backup created at: $BACKUP_DIR"
```

## 🚨 Emergency Recovery

### If Something Goes Wrong
```bash
# DON'T PANIC! Check current status
git status
git log --oneline -10

# If you made unwanted changes (not committed)
git checkout -- .

# If you committed but didn't push
git reset --soft HEAD~1

# If you need to go back to a specific commit
git log --oneline
git checkout <commit-hash>
```

### Finding Lost Work
```bash
# Git keeps everything for 30 days
git reflog

# Recover a deleted branch
git checkout -b recovered-branch <commit-hash>
```

## 📝 Commit Message Format

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `test:` Adding tests
- `chore:` Maintenance

Examples:
```
fix: resolve 404 error in social media dashboard
feat: add image upload to truck profile
refactor: optimize API service error handling
```

## 🔐 Protecting Sensitive Files

### Files that should NEVER be committed:
- `android/key.properties`
- `android/app/*.keystore`
- `.env` files
- Any file with passwords/API keys

### Before EVERY commit:
```bash
# Check for sensitive data
git diff --staged | grep -i "password\|api_key\|secret"
```

## 📊 Branch Naming Convention

- `feature/` - New features
- `bugfix/` - Non-critical bug fixes
- `hotfix/` - Critical production fixes
- `release/` - Release preparation
- `backup/` - Daily backups

Examples:
- `feature/add-payment-integration`
- `bugfix/fix-map-loading-issue`
- `hotfix/critical-crash-on-login`
- `release/v2.3.0`

## 🛠️ Setting Up Branch Protection on GitHub

1. Go to Settings → Branches
2. Add rule for `main`:
   - ✅ Require pull request reviews
   - ✅ Dismiss stale reviews
   - ✅ Require status checks
   - ✅ Include administrators
3. Add rule for `develop`:
   - ✅ Require pull request reviews
   - ✅ Require up-to-date branches

## 💾 Multiple Backup Strategy

1. **GitHub** - Primary version control
2. **Local Git** - On your computer
3. **External Drive** - Daily backups
4. **Cloud Storage** - Weekly backups (Google Drive/Dropbox)

## 🚀 Quick Start Commands

```bash
# Start new feature
./start-feature.sh "feature-name"

# Create backup
./backup.sh

# Check branch safety
./check-safety.sh
```

## ⚠️ GOLDEN RULES

1. **NEVER** force push to main or develop
2. **ALWAYS** create a feature branch
3. **TEST** before committing
4. **REVIEW** before merging
5. **BACKUP** daily

## 📞 If You Need Help

1. Don't make random changes
2. Create a backup branch first
3. Ask for help in the team chat
4. Check this guide

Remember: It's better to ask for help than to lose work!