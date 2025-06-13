# Food Truck Backend API

A simple Express.js backend for the Food Truck Finder mobile app.

## Features

- ✅ User authentication (login/register)
- ✅ Food truck listings with 5 pre-loaded trucks
- ✅ Search and filtering
- ✅ Location-based queries
- ✅ CORS enabled for cross-origin requests
- ✅ No database required (uses in-memory data)

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
- `GET /api/trucks/nearby?lat=&lng=` - Get nearby trucks
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `PUT /api/trucks/:id/location` - Update truck location

## Pre-loaded Data

### Test Accounts
- **Customer**: `john@customer.com` / `password123`
- **Owner**: `mike@tacos.com` / `password123`

### Food Trucks (5 trucks included)
1. Gourmet Tacos - Mexican street tacos (★4.5)
2. Burger Express - Artisanal burgers (★4.2)
3. Pizza Mobile - Wood-fired pizza (★4.7)
4. Korean BBQ Truck - Korean fusion (★4.6)
5. Sweet Dreams Desserts - Gourmet desserts (★4.8)

## Deploy to Render

1. Push this code to GitHub
2. Connect to Render.com
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Deploy!

## Environment Variables

- `PORT` - Server port (automatically set by Render)

## No Setup Required

This backend works immediately with no database or additional configuration needed. All data is stored in memory and resets when the server restarts.

Perfect for development, testing, and demos!
