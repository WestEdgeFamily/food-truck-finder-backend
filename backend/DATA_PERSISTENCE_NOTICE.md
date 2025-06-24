# Data Persistence Notice

## Recent Changes (v1.1.0)

### 1. Phone Numbers Removed ✅
- **Registration**: No longer requires phone number input
- **User Data**: Phone numbers removed from user profiles
- **Food Trucks**: Phone numbers removed from truck data
- **Login/Responses**: Phone numbers removed from API responses

### 2. Data Persistence Issue ⚠️

**Problem**: The current backend uses file-based JSON storage which **DOES NOT PERSIST** on cloud platforms like Render, Heroku, or similar services.

**Why this happens**:
- Cloud platforms use **ephemeral filesystems**
- Files written during runtime are lost when the container restarts
- Each deployment or restart resets data to defaults

**Symptoms**:
- Users need to re-register after server restarts
- Food trucks disappear after updates
- Favorites are lost
- Any data changes don't survive restarts

### 3. Solutions

#### Immediate (Debugging)
- Use `/api/admin/data-status` to check current data
- Use `/api/admin/force-save` to attempt saving (will fail on Render)
- Check server logs for persistence warnings

#### Recommended (Production)
Replace file-based storage with a real database:

**Option 1: MongoDB Atlas (Free)**
```javascript
// Replace file operations with MongoDB
const mongoose = require('mongoose');
// Connect to MongoDB Atlas
// Create User, FoodTruck, Favorite schemas
```

**Option 2: PostgreSQL (Render/Heroku)**
```javascript
// Replace file operations with PostgreSQL
const { Pool } = require('pg');
// Create tables for users, trucks, favorites
```

**Option 3: SQLite (Local Development)**
```javascript
// Replace file operations with SQLite
const sqlite3 = require('sqlite3');
// Create local database file
```

### 4. Current Behavior

The server will:
- ✅ Work perfectly in development
- ✅ Handle all API requests correctly
- ❌ Lose data on Render/Heroku restarts
- ⚠️ Show warnings in logs about persistence failures

### 5. Monitoring

The server now includes better logging:
- `💾 Successfully saved data` - File write succeeded
- `❌ Error saving data` - File write failed (expected on Render)
- `⚠️ WARNING: Data will not persist` - Persistence warning

### 6. API Changes

All API responses now include a `persisted` field:
```json
{
  "success": true,
  "message": "User registered successfully",
  "persisted": false,
  "user": { ... }
}
```

This tells you whether the data was actually saved to disk or just kept in memory.

## Next Steps

1. **Test the current changes** - Phone numbers should be gone
2. **Choose a database solution** - MongoDB Atlas is recommended
3. **Migrate to database** - Replace file operations with database calls
4. **Deploy with database** - Ensure persistence works

The app will work perfectly for testing, but you'll need a database for production use on Render. 