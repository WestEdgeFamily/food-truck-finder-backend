# Food Truck Finder - Backend API

Production-ready Node.js/Express backend with MongoDB Atlas for the Food Truck Finder mobile app.

## Features

- **Authentication**: JWT-based authentication with refresh tokens
- **Password Security**: Bcrypt password hashing with strong requirements
- **Rate Limiting**: Protection against brute force attacks
- **Pagination**: Efficient data loading for large datasets
- **Caching Support**: Client-side caching headers
- **Error Handling**: Comprehensive error handling with retry mechanisms
- **CORS**: Configured for mobile app access
- **Data Persistence**: MongoDB Atlas for reliable data storage

## Prerequisites

- Node.js 16+ 
- MongoDB Atlas account (free tier works)
- npm or yarn

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the backend directory:
```env
# MongoDB Connection
MONGODB_URI=your_mongodb_atlas_connection_string

# Server Configuration
PORT=3001

# JWT Secrets (generate secure random strings)
JWT_SECRET=your-secure-jwt-secret
JWT_REFRESH_SECRET=your-secure-refresh-secret

# Environment
NODE_ENV=production
```

## Running the Server

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/password-requirements` - Get password requirements

### Food Trucks
- `GET /api/trucks` - Get all trucks (paginated)
- `GET /api/trucks/:id` - Get truck by ID
- `PUT /api/trucks/:id` - Update truck
- `GET /api/trucks/:id/menu` - Get truck menu
- `PUT /api/trucks/:id/menu` - Update truck menu
- `PUT /api/trucks/:id/location` - Update truck location
- `PUT /api/trucks/:id/cover-photo` - Update truck photo
- `GET /api/trucks/:id/schedule` - Get truck schedule
- `PUT /api/trucks/:id/schedule` - Update truck schedule
- `GET /api/trucks/:id/analytics` - Get truck analytics

### Favorites
- `GET /api/favorites/:userId` - Get user favorites
- `POST /api/favorites/:userId/:truckId` - Add favorite
- `DELETE /api/favorites/:userId/:truckId` - Remove favorite

### Search & Filter
- `GET /api/trucks/search?q=query` - Search trucks
- `GET /api/trucks/filter` - Advanced filtering
- `GET /api/trucks/nearby` - Get nearby trucks

### POS Integration
- `GET /api/trucks/:truckId/pos-settings` - Get POS settings
- `POST /api/pos/child-account` - Create child account
- `GET /api/pos/child-accounts/:ownerId` - Get child accounts

## Security Features

1. **Password Requirements**:
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number
   - At least one special character

2. **Rate Limiting**:
   - Auth endpoints: 5 requests per 15 minutes
   - API endpoints: 100 requests per 15 minutes

3. **JWT Security**:
   - Access tokens expire in 24 hours
   - Refresh tokens expire in 7 days
   - Tokens stored securely

## Database Models

### User
- Email, password (hashed), name, role
- Business name (for owners)
- Timestamps and auth tokens

### FoodTruck
- Basic info (name, description, cuisine)
- Location data
- Menu items
- Schedule
- POS settings
- Analytics data

### Favorite
- User-truck relationships
- Timestamps

## Deployment

### Render.com
1. Create new Web Service
2. Connect GitHub repository
3. Set environment variables
4. Deploy

### Heroku
1. Create new app
2. Add MongoDB Atlas add-on
3. Set config vars
4. Deploy via GitHub

### Docker
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

## Monitoring

- Health check: `GET /api/health`
- Logs: Check console output
- MongoDB Atlas: Monitor database performance

## Maintenance

### Database Backups
- Enable automated backups in MongoDB Atlas
- Schedule regular exports

### Updates
- Keep dependencies updated
- Monitor security advisories
- Test thoroughly before deploying

## Support

For issues or questions, please create an issue in the GitHub repository. 
