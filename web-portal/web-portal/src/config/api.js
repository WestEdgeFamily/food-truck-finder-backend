const API_BASE_URL = process.env.REACT_APP_API_URL || 
  (process.env.NODE_ENV === 'production' 
    ? 'https://food-truck-backend.onrender.com' 
    : 'http://localhost:3001');

export const API_CONFIG = {
  BASE_URL: API_BASE_URL,
  WEBSOCKET_URL: API_BASE_URL
};

export default API_CONFIG; 