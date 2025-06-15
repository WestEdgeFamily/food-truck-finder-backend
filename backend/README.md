# Food Truck Backend API

A simple Express.js backend for the Food Truck Finder mobile app.

## Features

- ✅ User authentication (login/register)
- ✅ Food truck listings with 5 pre-loaded trucks
- ✅ Search and filtering
- ✅ Location-based queries
- ✅ CORS enabled for cross-origin requests

## Quick Start

```bash
npm install
npm start
```

The server will run on port 5000 (or PORT environment variable).

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/trucks` - Get all food trucks
- `GET /api/trucks/:id` - Get specific truck
- `GET /api/trucks/search?q=query` - Search trucks
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

## Test Accounts

- **Customer**: `john@customer.com` / `password123`
- **Owner**: `mike@tacos.com` / `password123`

## Deploy to Render

1. Push this code to GitHub
2. Connect to Render.com
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Deploy!

## Environment Variables

- `PORT` - Server port (automatically set by Render)
- `NODE_ENV` - Environment mode

## Features

- REST API for food truck data
- User authentication (customers & owners)
- Location tracking for food trucks
- Search and filtering capabilities
- CORS enabled for mobile app integration

## Endpoints

- `GET /api/health` - Health check
- `GET /api/trucks` - List all food trucks
- `GET /api/trucks/:id` - Get specific truck
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `PUT /api/trucks/:id/location` - Update truck location

## Environment Variables

- `PORT` - Server port (default: 5000)
- `NODE_ENV` - Environment (development/production)

## Quick Start

```bash
npm install
npm start
```

## Deployment

This backend is ready for deployment on:
- Render
- Heroku  
- Railway
- Vercel
- Any Node.js hosting platform

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

## Setup

1. Clone the repository
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Create a `.env` file in the root directory with the following variables:
   ```
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/food-truck-app
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRE=30d
   NODE_ENV=development
   ```
5. Start MongoDB service
6. Seed the database with sample data:
   ```bash
   npm run seed
   ```
7. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication
- GET /api/auth/me - Get current user

### Users
- GET /api/users - Get all users (admin only)
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- DELETE /api/users/:id - Delete user

### Trucks
- GET /api/trucks - Get all trucks
- GET /api/trucks/:id - Get truck by ID
- POST /api/trucks - Create new truck
- PUT /api/trucks/:id - Update truck
- DELETE /api/trucks/:id - Delete truck
- GET /api/trucks/owner/trucks - Get owner's trucks
- PUT /api/trucks/:id/location - Update truck location
- PUT /api/trucks/:id/schedule - Update truck schedule

### Reviews
- GET /api/reviews/truck/:truckId - Get reviews for a truck
- GET /api/reviews/user - Get user's reviews
- POST /api/reviews - Create review
- PUT /api/reviews/:id - Update review
- DELETE /api/reviews/:id - Delete review
- POST /api/reviews/:id/like - Like/Unlike review

### Recommendations
- GET /api/recommendations - Get personalized recommendations
- GET /api/recommendations/nearby - Get nearby trucks
- GET /api/recommendations/trending - Get trending trucks
- GET /api/recommendations/new - Get new trucks

## Development

- Run tests:
  ```bash
  npm test
  ```
- Run in development mode with hot reload:
  ```bash
  npm run dev
  ```

## Production

- Build and start the server:
  ```bash
  npm start
  ```

## Error Handling

The API uses standard HTTP status codes and returns error messages in the following format:
```json
{
  "message": "Error message here"
}
```

## Authentication

Most endpoints require authentication using JWT tokens. Include the token in the Authorization header:
```
Authorization: Bearer <your_token>
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request 