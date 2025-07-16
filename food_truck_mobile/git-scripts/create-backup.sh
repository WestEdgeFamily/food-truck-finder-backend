#!/bin/bash
# Create a backup of the entire project

# Configuration
BACKUP_BASE_DIR="/mnt/e/FoodTruckBackups"  # Change to your external drive path
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/$DATE"

echo "🔄 Creating backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get current directory name
PROJECT_DIR=$(pwd)

# Copy entire project (excluding build files)
rsync -av --progress \
    --exclude='build/' \
    --exclude='.dart_tool/' \
    --exclude='*.aab' \
    --exclude='*.apk' \
    --exclude='.gradle/' \
    --exclude='node_modules/' \
    "$PROJECT_DIR/" "$BACKUP_DIR/"

# Create a git bundle (includes all git history)
echo "📦 Creating git bundle..."
git bundle create "$BACKUP_DIR/food-truck-app.bundle" --all

# Create zip archive
echo "🗜️ Creating zip archive..."
cd "$BACKUP_BASE_DIR"
zip -r "$DATE.zip" "$DATE"

# Create backup info file
echo "📝 Creating backup info..."
cat > "$BACKUP_DIR/backup-info.txt" << EOF
Food Truck App Backup
Date: $(date)
Git Branch: $(git branch --show-current)
Last Commit: $(git log -1 --oneline)
Flutter Version: $(flutter --version | head -1)
EOF

echo "✅ Backup created successfully!"
echo "📁 Location: $BACKUP_DIR"
echo "🗜️ Archive: $BACKUP_BASE_DIR/$DATE.zip"
echo ""
echo "💡 To restore from bundle:"
echo "git clone $BACKUP_DIR/food-truck-app.bundle restored-project"