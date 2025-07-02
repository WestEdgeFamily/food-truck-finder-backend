# Food Truck Finder Backend

Node.js backend server for the Food Truck Finder mobile application.

## Features

- User authentication (customers and owners)
- Food truck management
- Real-time location tracking
- Menu management
- Favorites system
- Advanced filtering and search

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up MongoDB Atlas connection in `server.js`

3. Start the server:
   ```bash
   npm start
   ```

## API Endpoints

- `GET /api/health` - Health check
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/trucks` - Get all food trucks
- `GET /api/trucks/filter` - Advanced filtering
- `POST /api/users/:userId/favorites/:truckId` - Add to favorites

## Environment Variables

- `PORT` - Server port (default: 5000)
- `MONGODB_URI` - MongoDB connection string

## Tech Stack

- Node.js & Express
- MongoDB Atlas
- Mongoose ODM
- CORS enabled for cross-origin requests 