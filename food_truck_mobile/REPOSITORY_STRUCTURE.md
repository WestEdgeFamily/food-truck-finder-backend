# Food Truck Finder - Repository Structure & Strategy

## 📁 Current Repository Setup

Your repository: https://github.com/WestEdgeFamily/food-truck-finder-backend

### Branch Structure:
- **`main`** - Backend deployment files ONLY (for Render/hosting)
- **`master`** - Complete project (backend + mobile app + everything)
- **`develop`** - Development branch (based on master)
- **`feature/*`** - Feature branches

## 🎯 Recommended Approach

Since you need `main` for backend deployment only, here's the best strategy:

### Option 1: Keep Current Repo (Recommended)
```
food-truck-finder-backend/
├── main (backend only for deployment)
├── master (full project)
│   ├── backend/
│   ├── food_truck_mobile/
│   └── other files
└── develop (working branch)
```

### Workflow:
1. Work on `develop` or feature branches
2. Merge to `master` when tested
3. Cherry-pick only backend changes to `main` for deployment

## 🚀 Safe Development Workflow

### 1. Set Up Your Local Repository
```bash
# Clone if you haven't already
git clone https://github.com/WestEdgeFamily/food-truck-finder-backend.git
cd food-truck-finder-backend

# Make sure you're on master (has everything)
git checkout master
git pull origin master

# Create develop from master if it doesn't exist
git checkout -b develop
git push -u origin develop
```

### 2. Daily Development
```bash
# Always start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/fix-api-errors

# Make your changes...
# Test thoroughly...

# Commit changes
git add specific-files
git commit -m "fix: resolve 404 errors in API endpoints"

# Push feature branch
git push origin feature/fix-api-errors
```

### 3. Merging Process
```bash
# 1. Merge feature to develop (via PR)
# 2. Test on develop
# 3. Merge develop to master (via PR)
# 4. Deploy backend changes to main

# To update main with backend only:
git checkout main
git pull origin main

# Cherry-pick backend changes OR
# Copy only backend files from master
cp -r ../master/backend/* ./backend/
git add backend/
git commit -m "deploy: update backend for v2.2.1"
git push origin main
```

## 📂 Recommended File Structure

```
food-truck-finder-backend/ (repository root)
├── .github/
│   └── workflows/
│       ├── backend-deploy.yml (only runs on main)
│       └── app-build.yml (runs on master)
├── backend/
│   ├── server.js
│   ├── package.json
│   └── ... (all backend files)
├── food_truck_mobile/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   └── ... (all mobile app files)
├── docs/
│   ├── GIT_BRANCHING_STRATEGY.md
│   └── DEPLOYMENT_GUIDE.md
├── .gitignore
└── README.md
```

## 🔧 GitHub Actions for Safety

Create `.github/workflows/protect-main.yml`:
```yaml
name: Protect Main Branch

on:
  pull_request:
    branches: [ main ]

jobs:
  check-backend-only:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check for non-backend files
        run: |
          # List all files that aren't in backend/
          NON_BACKEND=$(find . -type f -not -path "./backend/*" -not -path "./.git/*" -not -path "./.github/*" -not -name "README.md" -not -name ".gitignore")
          
          if [ ! -z "$NON_BACKEND" ]; then
            echo "❌ ERROR: Non-backend files found in main branch PR:"
            echo "$NON_BACKEND"
            exit 1
          fi
          
          echo "✅ Only backend files detected"
```

## 🛡️ Branch Protection Rules

### For `main` branch:
- ✅ Require pull request reviews
- ✅ Require status checks (backend-only check)
- ✅ No direct pushes
- ✅ Include administrators

### For `master` branch:
- ✅ Require pull request reviews
- ✅ Require status checks (tests)
- ✅ Dismiss stale reviews

### For `develop` branch:
- ✅ Require pull request reviews
- ✅ Delete branch after merge

## 📝 Scripts for Easy Management

### `sync-backend-to-main.sh`
```bash
#!/bin/bash
# Sync only backend files from master to main

echo "Syncing backend files to main branch..."

# Ensure we're on main
git checkout main
git pull origin main

# Create temp directory
TEMP_DIR=$(mktemp -d)

# Checkout master backend files
git checkout master -- backend/
git checkout master -- package.json
git checkout master -- package-lock.json

# Commit if there are changes
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "deploy: sync backend from master - $(date +%Y-%m-%d)"
    echo "✅ Backend files synced. Review and push when ready."
else
    echo "✅ No changes to sync"
fi
```

### `start-feature.sh`
```bash
#!/bin/bash
# Start a new feature safely

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: ./start-feature.sh feature-name"
    exit 1
fi

# Ensure on develop and up to date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b "feature/$FEATURE_NAME"

echo "✅ Created feature/$FEATURE_NAME"
echo "📝 Make your changes, then:"
echo "   git add <files>"
echo "   git commit -m 'feat: your message'"
echo "   git push origin feature/$FEATURE_NAME"
```

## 🚨 Important Commands

```bash
# See which branch you're on
git branch

# See all branches (including remote)
git branch -a

# Switch branches safely
git checkout branch-name

# Update your branch with latest
git pull origin branch-name

# See what changed
git status
git diff

# See commit history
git log --oneline --graph --all
```

## 💡 Best Practices for Your Setup

1. **NEVER** commit mobile app files to `main`
2. **ALWAYS** work on feature branches
3. **TEST** on `develop` before merging to `master`
4. **DEPLOY** by syncing backend files to `main`
5. **BACKUP** regularly to external drive

## 🔄 Deployment Flow

```
feature/fix-api → develop → master → main (backend only)
                    ↓         ↓         ↓
                  Test     Test     Deploy
```

This keeps your deployment clean while maintaining the full project history!