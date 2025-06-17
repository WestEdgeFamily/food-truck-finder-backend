# POS Integration Guide

## Overview
The Food Truck Finder app now supports Point of Sale (POS) system integration, allowing food truck owners to automatically update their location and status from their POS terminals.

## Features
- **Parent/Child Account System**: Main owner account can create multiple child accounts for different POS terminals
- **Automatic Location Updates**: POS systems can update truck location via API
- **Status Management**: POS can update open/closed status
- **API Key Management**: Secure API keys for each terminal
- **Permission Control**: Granular permissions for each child account

## How It Works

### 1. Owner Registration
When a food truck owner registers, the system automatically:
- Creates a user account with role "owner"
- Auto-generates a food truck record linked to the owner
- Sets up POS integration settings with a parent API key

### 2. POS Terminal Setup
Owners can create child accounts for their POS terminals through the mobile app:
- Navigate to Profile → POS Integration
- Add new POS terminal with a descriptive name
- Get unique API key for that terminal
- Configure permissions (location updates, status updates)

### 3. POS Integration
POS systems can integrate using the provided API endpoints and keys.

## API Endpoints

### Create Child POS Account
```
POST /api/pos/child-account
Content-Type: application/json

{
  "parentOwnerId": "user_123456789",
  "childAccountName": "Main Register",
  "permissions": ["location_update", "status_update"]
}
```

### Update Location from POS
```
POST /api/pos/location-update
Content-Type: application/json

{
  "apiKey": "child_user_123456789_987654321",
  "latitude": 40.7589,
  "longitude": -111.8883,
  "address": "123 Main Street, Salt Lake City, UT",
  "isOpen": true
}
```

### Get POS Settings
```
GET /api/pos/settings/{ownerId}
```

### Get Child Accounts
```
GET /api/pos/child-accounts/{ownerId}
```

### Deactivate Child Account
```
PUT /api/pos/child-account/{childId}/deactivate
Content-Type: application/json

{
  "ownerId": "user_123456789"
}
```

## Mobile App Features

### For Owners
1. **POS Management Screen**: Access via Profile → POS Integration
2. **Parent Account Info**: View main account API key
3. **Child Account Management**: 
   - Create new POS terminals
   - View API keys with copy functionality
   - Deactivate terminals
   - See integration instructions

### Auto-Features
- **Auto-Truck Creation**: New owner registrations automatically create a food truck
- **Default Settings**: POS integration enabled by default
- **Secure API Keys**: Unique keys generated for each account

## Security
- Each POS terminal gets a unique API key
- Permissions are granular (location_update, status_update)
- Child accounts can be deactivated without affecting the parent
- API keys are long and cryptographically secure

## Integration Examples

### Square POS Integration
```javascript
// Example webhook handler for Square POS
app.post('/square-webhook', (req, res) => {
  const { location, isOpen } = req.body;
  
  // Update food truck location
  fetch('https://your-api.com/api/pos/location-update', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      apiKey: 'your_child_api_key',
      latitude: location.lat,
      longitude: location.lng,
      address: location.address,
      isOpen: isOpen
    })
  });
});
```

### Toast POS Integration
```python
# Example Python integration for Toast POS
import requests

def update_truck_location(lat, lng, address, is_open):
    payload = {
        'apiKey': 'your_child_api_key',
        'latitude': lat,
        'longitude': lng,
        'address': address,
        'isOpen': is_open
    }
    
    response = requests.post(
        'https://your-api.com/api/pos/location-update',
        json=payload
    )
    
    return response.json()
```

## Benefits
1. **Real-time Updates**: Customers see accurate location and status
2. **Reduced Manual Work**: No need to manually update location in app
3. **Multiple Terminals**: Support for multiple POS terminals per truck
4. **Scalable**: Easy to add/remove terminals as business grows
5. **Secure**: Each terminal has its own API key and permissions

## Support
For POS integration support, contact the development team or refer to the API documentation in the mobile app's POS Integration screen. 