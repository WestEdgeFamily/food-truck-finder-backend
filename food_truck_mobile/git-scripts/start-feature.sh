#!/bin/bash
# Start a new feature branch safely

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
    echo "❌ Usage: ./start-feature.sh feature-name"
    echo "Example: ./start-feature.sh fix-social-media"
    exit 1
fi

echo "🚀 Starting new feature: $FEATURE_NAME"

# Ensure on develop and up to date
echo "📥 Updating develop branch..."
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b "feature/$FEATURE_NAME"

echo "✅ Created branch: feature/$FEATURE_NAME"
echo ""
echo "📝 Next steps:"
echo "1. Make your changes"
echo "2. Test thoroughly (flutter test)"
echo "3. Stage files: git add lib/specific-file.dart"
echo "4. Commit: git commit -m 'feat: description'"
echo "5. Push: git push origin feature/$FEATURE_NAME"
echo "6. Create Pull Request on GitHub"