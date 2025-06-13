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
