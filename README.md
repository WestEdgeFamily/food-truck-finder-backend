# Food Truck Finder Backend API

A Node.js/Express backend API for the Food Truck Finder mobile application with complete favorites system.

## Features

- 🚚 **Food Truck Management**: CRUD operations for food trucks
- 👤 **User Authentication**: Login/register for customers and owners
- ❤️ **Favorites System**: Add/remove/view favorite food trucks
- 🔍 **Search & Filter**: Search trucks by name, cuisine, location
- 📍 **Location Services**: Nearby truck discovery
- 🏥 **Health Monitoring**: API health checks and status

## API Endpoints

### Core Routes
- `GET /` - API information and available endpoints
- `GET /api/health` - Health check with system status

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Food Trucks
- `GET /api/trucks` - Get all food trucks
- `GET /api/trucks/:id` - Get specific food truck
- `POST /api/trucks` - Create new food truck (owners)
- `PUT /api/trucks/:id/location` - Update truck location
- `GET /api/trucks/search?q=query` - Search food trucks
- `GET /api/trucks/nearby?lat=&lng=&radius=` - Find nearby trucks

### Favorites System
- `GET /api/users/:userId/favorites` - Get user's favorite trucks
- `POST /api/users/:userId/favorites/:truckId` - Add truck to favorites
- `DELETE /api/users/:userId/favorites/:truckId` - Remove from favorites
- `GET /api/users/:userId/favorites/check/:truckId` - Check if truck is favorited

## Data Models

### Food Truck
```json
{
  "_id": "string",
  "name": "string",
  "businessName": "string", 
  "description": "string",
  "ownerId": "string",
  "cuisineTypes": ["string"],
  "location": {
    "latitude": "number",
    "longitude": "number", 
    "address": "string"
  },
  "rating": "number",
  "reviewCount": "number",
  "isOpen": "boolean",
  "phone": "string",
  "email": "string",
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
  "phone": "string",
  "businessName": "string" // for owners only
}
```

## Local Development

### Prerequisites
- Node.js 18+ 
- npm or yarn

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd backend

# Install dependencies
npm install

# Start development server
npm run dev

# Or start production server
npm start
```

The server will start on `http://localhost:5000`

### Environment Variables
No environment variables required for basic functionality. The app uses in-memory storage.

## Deployment

### Render Deployment
1. Connect your GitHub repository to Render
2. Create a new Web Service
3. Use these settings:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Node Version**: 18+

### Manual Deployment
```bash
# Build and start
npm install --production
npm start
```

## Architecture

- **Framework**: Express.js
- **Storage**: In-memory (JavaScript objects)
- **CORS**: Enabled for all origins
- **Error Handling**: Centralized middleware
- **Logging**: Console-based with request tracking

## Sample Data

The API comes pre-loaded with:
- 5 sample food trucks (various cuisines)
- 2 sample users (customer and owner)
- Empty favorites system ready for use

## Testing

### Health Check
```bash
curl https://your-api-url.com/api/health
```

### Get Food Trucks
```bash
curl https://your-api-url.com/api/trucks
```

### Test Favorites
```bash
# Get favorites (should return empty array initially)
curl https://your-api-url.com/api/users/user_1749785616229/favorites

# Add to favorites
curl -X POST https://your-api-url.com/api/users/user_1749785616229/favorites/1

# Check favorites again
curl https://your-api-url.com/api/users/user_1749785616229/favorites
```

## Production Considerations

For production use, consider:
- Database integration (MongoDB, PostgreSQL)
- Authentication tokens (JWT)
- Rate limiting
- Input validation
- Logging service
- Environment-based configuration
- HTTPS enforcement
- API documentation (Swagger)

## Support

For issues or questions:
1. Check the health endpoint: `/api/health`
2. Review server logs
3. Verify all required dependencies are installed
4. Ensure Node.js version compatibility

## License

MIT License - see LICENSE file for details
