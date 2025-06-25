# Food Truck Finder Backend API

A Node.js/Express backend API for the Food Truck Finder mobile application with **MongoDB Atlas integration** and complete **persistent favorites system**.

## 🚀 Features

* 🚚 **Food Truck Management**: CRUD operations for food trucks with real-time data
* 👤 **User Authentication**: Login/register for customers and owners
* ❤️ **Persistent Favorites System**: Add/remove/view favorite food trucks (MongoDB Atlas)
* 🔍 **Search & Filter**: Search trucks by name, cuisine, location
* 📍 **Location Services**: Nearby truck discovery with GPS
* 🏥 **Health Monitoring**: API health checks and database status
* 💾 **Data Persistence**: All data stored in MongoDB Atlas (no more in-memory storage!)

## 🗄️ Database

**MongoDB Atlas** - Cloud-hosted MongoDB with persistent storage:
- ✅ User accounts and authentication
- ✅ Food truck data with menus and schedules  
- ✅ Favorites system with user relationships
- ✅ Data persists between deployments
- ✅ Automatic backups and scaling

## 📡 API Endpoints

### Core Routes
* `GET /` - API information and available endpoints
* `GET /api/health` - Health check with database status

### Authentication
* `POST /api/auth/login` - User login
* `POST /api/auth/register` - User registration

### Food Trucks
* `GET /api/trucks` - Get all food trucks
* `GET /api/trucks/:id` - Get specific food truck
* `POST /api/trucks` - Create new food truck (owners)
* `PUT /api/trucks/:id/location` - Update truck location
* `GET /api/trucks/search?q=query` - Search food trucks
* `GET /api/trucks/nearby?lat=&lng=&radius=` - Find nearby trucks

### Favorites System (NEW!)
* `GET /api/users/:userId/favorites` - Get user's favorite trucks
* `POST /api/users/:userId/favorites/:truckId` - Add truck to favorites
* `DELETE /api/users/:userId/favorites/:truckId` - Remove from favorites
* `GET /api/users/:userId/favorites/check/:truckId` - Check if truck is favorited

## 🏗️ Data Models

### Food Truck
```json
{
  "id": "string",
  "name": "string",
  "businessName": "string", 
  "description": "string",
  "ownerId": "string",
  "cuisine": "string",
  "location": {
    "latitude": "number",
    "longitude": "number", 
    "address": "string"
  },
  "rating": "number",
  "reviewCount": "number",
  "isOpen": "boolean",
  "email": "string",
  "website": "string",
  "menu": [
    {
      "name": "string",
      "description": "string",
      "price": "number",
      "isAvailable": "boolean"
    }
  ],
  "schedule": {
    "monday": {"open": "11:00", "close": "21:00", "isOpen": true},
    "tuesday": {"open": "11:00", "close": "21:00", "isOpen": true}
    // ... other days
  },
  "createdAt": "string",
  "lastUpdated": "string"
}
```

### User
```json
{
  "_id": "string",
  "name": "string",
  "email": "string",
  "role": "customer|owner",
  "businessName": "string" // for owners only
}
```

### Favorite
```json
{
  "userId": "string",
  "truckId": "string",
  "createdAt": "string"
}
```

## 🚀 Deployment

### Render Deployment (Current)

The API is deployed on **Render** with automatic deployments from this GitHub repository:

**Live API URL**: `https://food-truck-finder-api.onrender.com`

**Environment Variables Required**:
- `MONGODB_URI` - MongoDB Atlas connection string

### Local Development

```bash
# Clone the repository
git clone https://github.com/WestEdgeFamily/food-truck-finder-backend.git
cd food-truck-finder-backend

# Install dependencies
npm install

# Set environment variable (optional - will use local MongoDB if not set)
export MONGODB_URI="your-mongodb-atlas-connection-string"

# Start development server
npm run dev

# Or start production server
npm start
```

The server will start on `http://localhost:5000`

## 🧪 Testing

### Health Check
```bash
curl https://food-truck-finder-api.onrender.com/api/health
```

### Get Food Trucks
```bash
curl https://food-truck-finder-api.onrender.com/api/trucks
```

### Test Favorites System
```bash
# Register a customer
curl -X POST https://food-truck-finder-api.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123","role":"customer"}'

# Add to favorites (use returned user ID)
curl -X POST https://food-truck-finder-api.onrender.com/api/users/USER_ID/favorites/1

# Check favorites
curl https://food-truck-finder-api.onrender.com/api/users/USER_ID/favorites
```

## 📊 Database Status

The API includes 5 pre-loaded Utah food trucks:
- **Cupbop Korean BBQ** - Korean cuisine with authentic BBQ bowls
- **The Pie Pizzeria** - Utah's legendary thick crust pizza
- **Red Iguana Mobile** - Award-winning Mexican with mole sauces  
- **Crown Burgers Mobile** - Utah's iconic pastrami burgers
- **Sill-Ice Cream Truck** - Artisanal ice cream with local ingredients

All trucks include:
- ✅ Complete menu items with prices
- ✅ Operating schedules for each day
- ✅ Contact information (email/website)
- ✅ GPS coordinates and addresses
- ✅ Real-time open/closed status

## 🔧 Architecture

* **Framework**: Express.js with MongoDB Atlas
* **Database**: MongoDB Atlas (Cloud-hosted, persistent)
* **Authentication**: Simple email/password (ready for JWT upgrade)
* **CORS**: Enabled for all origins (development-friendly)
* **Error Handling**: Centralized middleware with detailed logging
* **Logging**: Console-based with request tracking

## 🆕 What's New in v2.0.0

* ✅ **MongoDB Atlas Integration** - Replaced in-memory storage
* ✅ **Persistent Favorites** - Data survives deployments
* ✅ **Enhanced Food Trucks** - Complete menu and schedule data
* ✅ **Real-time Status** - Dynamic open/closed based on schedule
* ✅ **Better Error Handling** - Comprehensive error responses
* ✅ **Health Monitoring** - Database connection status
* ✅ **Utah Food Trucks** - Pre-loaded with local favorites

## 🔮 Production Considerations

For production scaling, consider:
- ✅ **Database**: MongoDB Atlas (already implemented)
- 🔄 **Authentication**: JWT tokens (planned upgrade)
- 🔄 **Rate Limiting**: API throttling (planned)
- 🔄 **Input Validation**: Request sanitization (planned)
- ✅ **Logging**: Structured logging (basic implementation)
- ✅ **Environment Config**: Environment-based settings (implemented)
- ✅ **HTTPS**: SSL enforcement (handled by Render)

## 📞 Support

For issues or questions:
1. Check the health endpoint: `/api/health`
2. Review server logs in Render dashboard
3. Verify MongoDB Atlas connection
4. Ensure all required dependencies are installed

## 📄 License

MIT License - see LICENSE file for details

---

**Last Updated**: January 2025  
**Version**: 2.0.0  
**Status**: ✅ Production Ready with MongoDB Atlas 