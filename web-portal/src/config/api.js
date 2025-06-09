const API_BASE_URL = process.env.REACT_APP_API_URL || 
  (process.env.NODE_ENV === 'production' 
    ? 'https://food-truck-backend.onrender.com' 
    : 'http://localhost:3001');

const WS_BASE_URL = process.env.REACT_APP_WEBSOCKET_URL || 
  (process.env.NODE_ENV === 'production'
    ? 'wss://food-truck-backend.onrender.com'
    : 'ws://localhost:3001');

export const API_CONFIG = {
  BASE_URL: API_BASE_URL,
  WEBSOCKET_URL: WS_BASE_URL,
  HEADERS: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  SOCKET_OPTIONS: {
    transports: ['websocket', 'polling'],
    withCredentials: true
  }
};

export default API_CONFIG; 