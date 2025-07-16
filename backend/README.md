# Food Truck Finder Backend API

A comprehensive Express.js backend for the Food Truck Finder application with MongoDB Atlas integration.

## Features

- **User Authentication**: JWT-based authentication with refresh tokens
- **Role-based Access**: Customer and Owner roles with different permissions
- **Food Truck Management**: CRUD operations for food trucks
- **Location Tracking**: Real-time location updates with geolocation
- **Menu Management**: Dynamic menu items with pricing
- **Review System**: Customer reviews and ratings
- **Favorites System**: Users can favorite food trucks
- **POS Integration**: Point of sale system integration
- **Image Upload**: Cloudinary integration for image storage
- **Security**: Rate limiting, input validation, and sanitization
- **Email Service**: Welcome emails and password reset functionality

## Prerequisites

- Node.js >= 16.0.0
- MongoDB Atlas account
- Cloudinary account (for image uploads)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

4. Update the `.env` file with your actual configuration values

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `MONGODB_URI` | MongoDB Atlas connection string | Yes |
| `JWT_SECRET` | JWT signing secret | Yes |
| `JWT_REFRESH_SECRET` | JWT refresh token secret | Yes |
| `PORT` | Server port (default: 3001) | No |
| `NODE_ENV` | Environment (development/production) | No |
| `CORS_ORIGIN` | Allowed CORS origins | No |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | Yes |
| `CLOUDINARY_API_KEY` | Cloudinary API key | Yes |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | Yes |
| `SMTP_HOST` | SMTP server host | No |
| `SMTP_PORT` | SMTP server port | No |
| `SMTP_USER` | SMTP username | No |
| `SMTP_PASS` | SMTP password | No |

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - User logout
- `GET /api/auth/password-requirements` - Get password requirements

### Food Trucks
- `GET /api/trucks` - Get all food trucks (paginated)
- `GET /api/trucks/:id` - Get specific food truck
- `PUT /api/trucks/:id/location` - Update truck location
- `PUT /api/trucks/:id/cover-photo` - Update truck cover photo
- `GET /api/trucks/:id/menu` - Get truck menu
- `GET /api/trucks/:id/schedule` - Get truck schedule
- `PUT /api/trucks/:id/schedule` - Update truck schedule
- `GET /api/trucks/:id/analytics` - Get truck analytics

### Users
- `PUT /api/users/:userId/email` - Change user email
- `PUT /api/users/:userId/password` - Change user password

### Favorites
- `GET /api/users/:userId/favorites` - Get user's favorite trucks
- `POST /api/users/:userId/favorites/:truckId` - Add truck to favorites
- `DELETE /api/users/:userId/favorites/:truckId` - Remove truck from favorites
- `GET /api/users/:userId/favorites/check/:truckId` - Check if truck is favorited

### POS Integration
- `GET /api/pos/settings/:ownerId` - Get POS settings
- `POST /api/pos/child-account` - Create child POS account
- `GET /api/pos/child-accounts/:ownerId` - Get child accounts
- `PUT /api/pos/child-account/:childId/deactivate` - Deactivate child account
- `POST /api/pos/location-update` - Update location via POS

### Health Check
- `GET /api/health` - API health check

## Security Features

- **Rate Limiting**: Different limits for auth and API endpoints
- **Input Validation**: Comprehensive validation using express-validator
- **Sanitization**: XSS protection and input sanitization
- **Authentication**: JWT tokens with refresh token support
- **CORS**: Configurable CORS origins
- **Helmet**: Security headers middleware
- **Password Hashing**: bcrypt for password security

## Development

Run in development mode:
```bash
npm run dev
```

Run in production mode:
```bash
npm start
```

## Deployment

This backend is configured for deployment on Render.com with automatic GitHub integration.

1. Connect your GitHub repository to Render
2. Set environment variables in Render dashboard
3. Deploy to the main branch

## Database Structure

The application uses MongoDB with the following collections:
- `users` - User accounts and authentication
- `foodtrucks` - Food truck information and menus
- `favorites` - User favorites
- `reviews` - Customer reviews
- `socialaccounts` - Social media accounts

## Logging

The application uses Winston for logging:
- Console logging for development
- File logging for production
- Error and combined logs
- HTTP request logging with Morgan

## Error Handling

Comprehensive error handling with:
- Global error handler middleware
- Async error handling
- Validation error handling
- Database error handling
- JWT error handling

## Support

For issues and questions, please check the API documentation or contact the development team.
