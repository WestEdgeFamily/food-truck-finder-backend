#!/bin/bash
# Safety check before committing

echo "🔍 Running safety checks..."

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "⚠️  WARNING: You're on $CURRENT_BRANCH branch!"
    echo "❌ Never commit directly to main/master!"
    echo "💡 Use: git checkout -b feature/your-feature"
    exit 1
fi

# Check for sensitive files
echo ""
echo "🔐 Checking for sensitive files..."

SENSITIVE_FILES=$(git status --porcelain | grep -E "(\.env|key\.properties|\.keystore|\.jks|google-services\.json)")

if [ ! -z "$SENSITIVE_FILES" ]; then
    echo "⚠️  WARNING: Sensitive files detected:"
    echo "$SENSITIVE_FILES"
    echo "❌ These files should NOT be committed!"
    echo "💡 Add them to .gitignore"
fi

# Check for large files
echo ""
echo "📏 Checking for large files..."

LARGE_FILES=$(find . -type f -size +10M -not -path "./.git/*" -not -path "./build/*" -not -path "./.gradle/*" 2>/dev/null)

if [ ! -z "$LARGE_FILES" ]; then
    echo "⚠️  Large files detected (>10MB):"
    echo "$LARGE_FILES"
    echo "💡 Consider if these should be committed"
fi

# Show what will be committed
echo ""
echo "📋 Files staged for commit:"
git diff --cached --name-only

echo ""
echo "📊 Summary of changes:"
git diff --cached --stat

# Check if tests pass
echo ""
echo "🧪 Running Flutter analyze..."
flutter analyze

echo ""
echo "✅ Safety check complete!"
echo "💡 If everything looks good, proceed with:"
echo "   git commit -m 'your message'"
echo "   git push origin $CURRENT_BRANCH"