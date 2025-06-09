import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Box,
  TextField,
  CircularProgress,
  Chip,
  InputAdornment,
  IconButton,
  Rating,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  Divider,
  Alert,
  Slider,
  FormControl,
  FormLabel,
  Switch,
  FormControlLabel,
  Paper,
  Snackbar,
  Tooltip,
  Badge,
  Fab,
  Avatar
} from '@mui/material';
import {
  Search,
  LocationOn,
  AccessTime,
  Restaurant,
  MyLocation,
  Phone,
  Star,
  Menu as MenuIcon,
  Report as ReportIcon,
  History as HistoryIcon,
  Refresh,
  Notifications,
  LiveTv,
  Speed,
  Favorite,
  FavoriteBorder,
  Person,
  AccountCircle,
  Close
} from '@mui/icons-material';
import axios from 'axios';
import UserProfile from './UserProfile';
import CustomerAuth from './CustomerAuth';
import io from 'socket.io-client';
import { Geolocation } from '@capacitor/geolocation';
import { Capacitor } from '@capacitor/core';

const CustomerHome = () => {
  const [foodTrucks, setFoodTrucks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [userLocation, setUserLocation] = useState(null);
  const [selectedTruck, setSelectedTruck] = useState(null);
  const [menuDialogOpen, setMenuDialogOpen] = useState(false);
  const [error, setError] = useState(null);
  const [searchRadius, setSearchRadius] = useState(15); // miles
  const [useLocationFilter, setUseLocationFilter] = useState(true);
  const [reportDialogOpen, setReportDialogOpen] = useState(false);
  const [historyDialogOpen, setHistoryDialogOpen] = useState(false);
  const [reportingTruck, setReportingTruck] = useState(null);
  const [locationHistory, setLocationHistory] = useState([]);
  
  // Real-time features
  const [socket, setSocket] = useState(null);
  const [liveUpdates, setLiveUpdates] = useState([]);
  const [liveTrucks, setLiveTrucks] = useState(new Set());
  const [favorites, setFavorites] = useState(new Set());
  const [notifications, setNotifications] = useState([]);
  const [showNotifications, setShowNotifications] = useState(false);
  
  // Reporting state
  const [reportLocation, setReportLocation] = useState('');
  const [reportNotes, setReportNotes] = useState('');
  const [reportSuccess, setReportSuccess] = useState(false);
  const [reportError, setReportError] = useState('');

  const [userFavorites, setUserFavorites] = useState([]);
  const [customerToken, setCustomerToken] = useState(null);
  const [showProfile, setShowProfile] = useState(false);
  const [showAuth, setShowAuth] = useState(false);

  useEffect(() => {
    fetchFoodTrucks();
    getCurrentLocation();
    initializeWebSocket();
    loadFavorites();
    const token = localStorage.getItem('customerToken');
    if (token) {
      setCustomerToken(token);
      fetchUserFavorites();
    }

    // Cleanup WebSocket on unmount
    return () => {
      if (socket) {
        socket.disconnect();
      }
    };
  }, []);

  // Real-time WebSocket initialization
  const initializeWebSocket = () => {
    const newSocket = io('http://localhost:3001');
    
    newSocket.on('connect', () => {
      console.log('🔗 Connected to real-time server');
      newSocket.emit('join', { userType: 'customer', userId: 'customer_1' });
    });

    // Handle live location updates
    newSocket.on('truck_location_updated', (data) => {
      console.log('📍 Live location update:', data);
      
      // Update truck in state
      setFoodTrucks(prev => prev.map(truck => 
        truck._id === data.truckId 
          ? { ...truck, location: data.location }
          : truck
      ));

      // Add to live updates
      setLiveUpdates(prev => [{
        id: Date.now(),
        type: 'location',
        truckId: data.truckId,
        truckName: data.truckName,
        message: `${data.truckName} updated their location`,
        timestamp: new Date(),
        location: data.location
      }, ...prev.slice(0, 9)]); // Keep last 10 updates

      // Show notification for favorite trucks
      if (favorites.has(data.truckId)) {
        addNotification({
          type: 'favorite_update',
          title: `${data.truckName} moved!`,
          message: 'Your favorite truck updated their location',
          timestamp: new Date()
        });
      }
    });

    // Handle tracking status changes
    newSocket.on('truck_live_tracking_started', (data) => {
      console.log('🛰️ Truck started live tracking:', data);
      
      setLiveTrucks(prev => new Set([...prev, data.truckId]));
      
      addNotification({
        type: 'tracking_started',
        title: `${data.truckName} is now live!`,
        message: 'Real-time location tracking active',
        timestamp: new Date()
      });
    });

    newSocket.on('truck_tracking_stopped', (data) => {
      console.log('🛑 Truck stopped tracking:', data);
      
      setLiveTrucks(prev => {
        const newSet = new Set(prev);
        newSet.delete(data.truckId);
        return newSet;
      });
    });

    newSocket.on('disconnect', () => {
      console.log('❌ Disconnected from real-time server');
    });

    setSocket(newSocket);
  };

  // Notification system
  const addNotification = (notification) => {
    setNotifications(prev => [{
      id: Date.now(),
      ...notification
    }, ...prev.slice(0, 4)]); // Keep last 5 notifications
  };

  // Favorites system
  const loadFavorites = () => {
    const saved = localStorage.getItem('favoriteTrucks');
    if (saved) {
      setFavorites(new Set(JSON.parse(saved)));
    }
  };

  const fetchUserFavorites = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) return;

      const response = await fetch('http://localhost:3001/api/users/favorites', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const data = await response.json();
        const favoriteIds = data.favorites.map(fav => fav._id);
        setUserFavorites(favoriteIds);
      }
    } catch (error) {
      console.error('Error fetching favorites:', error);
    }
  };

  const toggleFavorite = async (truckId) => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) {
        alert('Please log in to save favorites');
        return;
      }

      const isFavorited = userFavorites.includes(truckId);
      
      if (isFavorited) {
        // Remove from favorites
        const response = await fetch(`http://localhost:3001/api/users/favorites/${truckId}`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
          setUserFavorites(prev => prev.filter(id => id !== truckId));
          // Emit notification via WebSocket
          if (socket) {
            socket.emit('favorite_removed', { truckId, timestamp: new Date() });
          }
        }
      } else {
        // Add to favorites
        const response = await fetch(`http://localhost:3001/api/users/favorites/${truckId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ notes: '' })
        });
        
        if (response.ok) {
          setUserFavorites(prev => [...prev, truckId]);
          // Emit notification via WebSocket
          if (socket) {
            socket.emit('favorite_added', { truckId, timestamp: new Date() });
          }
        }
      }
    } catch (error) {
      console.error('Error toggling favorite:', error);
    }
  };

  const fetchFoodTrucks = async () => {
    try {
      setLoading(true);
      const response = await axios.get('http://localhost:3001/api/foodtrucks');
      console.log('Fetched food trucks:', response.data);
      setFoodTrucks(response.data);
      setError(null);
    } catch (err) {
      console.error('Error fetching food trucks:', err);
      setError('Unable to load food trucks. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const getCurrentLocation = async () => {
    try {
      let position;
      if (Capacitor.isNativePlatform()) {
        // Use Capacitor geolocation on mobile
        const permissions = await Geolocation.checkPermissions();
        if (permissions.location !== 'granted') {
          const requestPermissions = await Geolocation.requestPermissions();
          if (requestPermissions.location !== 'granted') {
            throw new Error('Location permission denied');
          }
        }
        position = await Geolocation.getCurrentPosition();
      } else {
        // Use browser geolocation on web
        if (!navigator.geolocation) {
          throw new Error('Geolocation is not supported by this browser.');
        }
        position = await new Promise((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject);
        });
      }
      
      setUserLocation({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      });
    } catch (error) {
      console.warn('Error getting location:', error);
    }
  };

  const searchFoodTrucks = async () => {
    try {
      setLoading(true);
      const params = { query: searchQuery };
      
      // Include location filtering if enabled and user location is available
      if (useLocationFilter && userLocation) {
        params.lat = userLocation.latitude;
        params.lng = userLocation.longitude;
        params.radius = searchRadius * 1609.34; // Convert miles to meters
      }
      
      console.log('Searching with params:', params);
      const response = await axios.get('http://localhost:3001/api/foodtrucks/search', { params });
      console.log('Search response:', response.data);
      setFoodTrucks(response.data);
      setError(null);
    } catch (err) {
      console.error('Error searching food trucks:', err);
      setError('Search failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSearchKeyPress = (event) => {
    if (event.key === 'Enter') {
      if (searchQuery.trim()) {
        searchFoodTrucks();
      } else {
        fetchFoodTrucks();
      }
    }
  };

  const handleViewMenu = (truck) => {
    setSelectedTruck(truck);
    setMenuDialogOpen(true);
  };

  const handleReportLocation = (truck) => {
    setReportingTruck(truck);
    setReportLocation('');
    setReportNotes('');
    setReportDialogOpen(true);
  };

  const handleViewHistory = async (truck) => {
    try {
      const response = await axios.get(`http://localhost:3001/api/foodtrucks/${truck._id}/location-history?limit=20`);
      setLocationHistory(response.data);
      setSelectedTruck(truck);
      setHistoryDialogOpen(true);
    } catch (err) {
      console.error('Error fetching location history:', err);
      setReportError('Failed to load location history');
    }
  };

  const submitLocationReport = async () => {
    if (!reportLocation.trim()) {
      setReportError('Please enter a location');
      return;
    }

    try {
      const token = localStorage.getItem('token');
      if (!token) {
        setReportError('Please log in to report locations');
        return;
      }

      // For demo purposes, we'll use approximate coordinates
      // In production, you'd use a geocoding service
      const demoLat = 40.7128 + (Math.random() - 0.5) * 0.1;
      const demoLng = -74.0060 + (Math.random() - 0.5) * 0.1;

      await axios.post(`http://localhost:3001/api/foodtrucks/${reportingTruck._id}/report-location`, {
        latitude: demoLat,
        longitude: demoLng,
        address: reportLocation,
        city: 'Demo City',
        state: 'NY',
        notes: reportNotes
      }, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      setReportSuccess(true);
      setReportDialogOpen(false);
      setReportLocation('');
      setReportNotes('');
      
      // Refresh the truck data
      fetchFoodTrucks();
    } catch (err) {
      console.error('Error reporting location:', err);
      setReportError(err.response?.data?.message || 'Failed to report location');
    }
  };

  const getDistance = (truck) => {
    if (!userLocation || !truck.location || !truck.location.coordinates) return null;
    
    const [truckLng, truckLat] = truck.location.coordinates;
    const R = 3959; // Earth's radius in miles
    const dLat = (truckLat - userLocation.latitude) * Math.PI / 180;
    const dLng = (truckLng - userLocation.longitude) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(userLocation.latitude * Math.PI / 180) * Math.cos(truckLat * Math.PI / 180) * 
      Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c;
    
    return distance < 0.1 ? `${Math.round(distance * 5280)}ft` : `${distance.toFixed(1)}mi`;
  };

  const isOpenNow = (truck) => {
    const hours = truck.businessHours || truck.operatingHours;
    if (!hours || hours.length === 0) return false;
    
    const now = new Date();
    const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' });
    const currentTime = now.toTimeString().slice(0, 5);
    
    const todayHours = hours.find(h => h.day === currentDay);
    if (!todayHours) return false;
    
    return currentTime >= todayHours.open && currentTime <= todayHours.close && truck.isActive;
  };

  const getLocationConfidenceColor = (confidence) => {
    switch (confidence) {
      case 'high': return '#4CAF50';
      case 'medium': return '#ff9800';
      case 'low': return '#f44336';
      default: return '#757575';
    }
  };

  const formatLocationSource = (source) => {
    const sourceMap = {
      'owner': 'Owner Update',
      'customer': 'Customer Report',
      'instagram': 'Instagram',
      'facebook': 'Facebook',
      'twitter': 'Twitter',
      'gps': 'GPS Tracking',
      'admin': 'Admin Update',
      'manual': 'Manual Entry'
    };
    return sourceMap[source] || source;
  };

  // Handle successful authentication
  const handleAuthSuccess = (user, token) => {
    setCustomerToken(token);
    setShowAuth(false);
    fetchUserFavorites();
  };

  // Handle logout
  const handleLogout = () => {
    setCustomerToken(null);
    localStorage.removeItem('customerToken');
    setUserFavorites([]);
    setShowProfile(false);
  };

  if (loading && foodTrucks.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Hero Section */}
      <Box sx={{ textAlign: 'center', mb: 4, position: 'relative' }}>
        {/* Authentication Buttons */}
        <Box sx={{ position: 'absolute', top: 0, right: 0, display: 'flex', gap: 1 }}>
          {customerToken ? (
            <>
              <Button
                variant="outlined"
                startIcon={<Person />}
                onClick={() => setShowProfile(true)}
                sx={{ 
                  borderColor: '#FF6B35',
                  color: '#FF6B35',
                  '&:hover': {
                    borderColor: '#FF6B35',
                    backgroundColor: 'rgba(255,107,53,0.1)'
                  }
                }}
              >
                My Profile
              </Button>
              <Button
                variant="outlined"
                onClick={handleLogout}
                sx={{ 
                  borderColor: '#666',
                  color: '#666',
                  '&:hover': {
                    borderColor: '#999',
                    backgroundColor: 'rgba(0,0,0,0.1)'
                  }
                }}
              >
                Logout
              </Button>
            </>
          ) : (
            <Button
              variant="contained"
              startIcon={<AccountCircle />}
              onClick={() => setShowAuth(true)}
              sx={{ 
                backgroundColor: '#FF6B35',
                '&:hover': {
                  backgroundColor: '#e55a2e'
                }
              }}
            >
              Login / Register
            </Button>
          )}
        </Box>
        
        <Typography variant="h3" component="h1" gutterBottom sx={{ fontWeight: 600, color: '#FF6B35' }}>
          Find Amazing Food Trucks Near You
        </Typography>
        <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
          Discover local food trucks and enjoy delicious meals on the go
        </Typography>
        
        {/* Search Bar */}
        <Box sx={{ maxWidth: 600, mx: 'auto', mb: 2 }}>
          <TextField
            fullWidth
            placeholder="Search for food trucks, cuisine types, or dishes..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyPress={handleSearchKeyPress}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search />
                </InputAdornment>
              ),
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={getCurrentLocation} title="Use my location">
                    <MyLocation />
                  </IconButton>
                </InputAdornment>
              ),
            }}
            sx={{ backgroundColor: 'white', borderRadius: 2 }}
          />
        </Box>
        
        <Button
          variant="contained"
          onClick={() => searchQuery.trim() ? searchFoodTrucks() : fetchFoodTrucks()}
          sx={{ px: 4, py: 1.5, mb: 3 }}
        >
          {searchQuery.trim() ? 'Search' : 'Show All Food Trucks'}
        </Button>
        
        {/* Search Options */}
        <Paper elevation={1} sx={{ p: 3, maxWidth: 600, mx: 'auto', mb: 2 }}>
          <FormControlLabel
            control={
              <Switch
                checked={useLocationFilter}
                onChange={(e) => setUseLocationFilter(e.target.checked)}
                color="primary"
              />
            }
            label="Filter by distance from my location"
            sx={{ mb: 2, display: 'block' }}
          />
          
          {useLocationFilter && (
            <FormControl fullWidth>
                             <FormLabel component="legend" sx={{ mb: 1, color: 'text.primary' }}>
                 Search Radius: {searchRadius} miles
                 {!userLocation && (
                   <Typography variant="caption" color="warning.main" display="block">
                     Enable location access to use distance filtering
                   </Typography>
                 )}
               </FormLabel>
               <Slider
                 value={searchRadius}
                 onChange={(e, newValue) => setSearchRadius(newValue)}
                 min={1}
                 max={60}
                 step={1}
                 marks={[
                   { value: 3, label: '3mi' },
                   { value: 15, label: '15mi' },
                   { value: 30, label: '30mi' },
                   { value: 60, label: '60mi' }
                 ]}
                 valueLabelDisplay="auto"
                 disabled={!userLocation}
                 sx={{ mt: 2 }}
               />
            </FormControl>
          )}
        </Paper>
      </Box>

      {/* Real-time Updates Section */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Badge badgeContent={liveUpdates.length} color="success">
            <Fab 
              size="small" 
              color="primary" 
              sx={{ 
                background: 'linear-gradient(45deg, #FE6B8B 30%, #FF8E53 90%)',
                animation: liveUpdates.length > 0 ? 'pulse 2s infinite' : 'none',
                '@keyframes pulse': {
                  '0%': { transform: 'scale(1)', opacity: 1 },
                  '50%': { transform: 'scale(1.05)', opacity: 0.8 },
                  '100%': { transform: 'scale(1)', opacity: 1 }
                }
              }}
            >
              <LiveTv />
            </Fab>
          </Badge>
          <Typography variant="h6">Live Updates</Typography>
        </Box>
        
        <Badge badgeContent={notifications.length} color="error">
          <IconButton 
            onClick={() => setShowNotifications(true)}
            sx={{ color: notifications.length > 0 ? 'primary.main' : 'grey.500' }}
          >
            <Notifications />
          </IconButton>
        </Badge>
      </Box>

      {/* Live Updates Banner */}
      {liveUpdates.length > 0 && (
        <Alert 
          severity="success" 
          sx={{ 
            mb: 2, 
            background: 'linear-gradient(45deg, #4CAF50 30%, #8BC34A 90%)',
            color: 'white',
            '& .MuiAlert-icon': { color: 'white' }
          }}
          action={
            <Button color="inherit" size="small" onClick={() => setLiveUpdates([])}>
              Clear
            </Button>
          }
        >
          <Typography variant="subtitle2">
            🔴 LIVE: {liveUpdates[0]?.message} • {liveUpdates.length} recent updates
          </Typography>
        </Alert>
      )}

      {/* Live Tracking Status */}
      {liveTrucks.size > 0 && (
        <Paper 
          elevation={3} 
          sx={{ 
            p: 2, 
            mb: 2, 
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white'
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <LiveTv sx={{ animation: 'pulse 2s infinite' }} />
            <Typography variant="h6">
              {liveTrucks.size} truck{liveTrucks.size !== 1 ? 's' : ''} broadcasting live GPS
            </Typography>
          </Box>
        </Paper>
      )}

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Food Trucks Grid */}
      <Grid container spacing={3}>
        {foodTrucks.map((truck) => (
          <Grid size={{ xs: 12, sm: 6, md: 4 }} key={truck._id}>
            <Card 
              sx={{ 
                height: '100%', 
                display: 'flex', 
                flexDirection: 'column',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 3,
                },
                transition: 'all 0.3s ease-in-out',
              }}
            >
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                  <Box sx={{ flexGrow: 1 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography variant="h5" component="h2" sx={{ fontWeight: 600 }}>
                        {truck.name || truck.businessName}
                      </Typography>
                      {liveTrucks.has(truck._id) && (
                        <Chip 
                          icon={<LiveTv />}
                          label="LIVE" 
                          size="small" 
                          sx={{ 
                            background: 'linear-gradient(45deg, #FF4081 30%, #FF6EC7 90%)',
                            color: 'white',
                            animation: 'pulse 2s infinite'
                          }} 
                        />
                      )}
                      <IconButton 
                        size="small" 
                        onClick={() => toggleFavorite(truck._id)}
                        sx={{ color: userFavorites.includes(truck._id) ? 'red' : 'grey.400' }}
                      >
                        {userFavorites.includes(truck._id) ? <Favorite /> : <FavoriteBorder />}
                      </IconButton>
                    </Box>
                  </Box>
                  <Chip
                    label={isOpenNow(truck) ? 'OPEN' : 'CLOSED'}
                    color={isOpenNow(truck) ? 'success' : 'error'}
                    size="small"
                    sx={{ ml: 1 }}
                  />
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {truck.description || 'Delicious food on wheels!'}
                </Typography>

                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Restaurant sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                  <Typography variant="body2">
                    {truck.cuisineType || 'Various'}
                  </Typography>
                </Box>

                {/* Location Information */}
                <Box sx={{ mb: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                    <LocationOn sx={{ mr: 1, fontSize: 16, color: 'text.secondary' }} />
                    <Typography variant="body2">
                      {truck.location?.city ? `${truck.location.city}, ${truck.location.state}` : 'Location not set'}
                      {getDistance(truck) && (
                        <span style={{ marginLeft: 8, fontWeight: 600, color: '#FF6B35' }}>
                          ({getDistance(truck)} away)
                        </span>
                      )}
                    </Typography>
                  </Box>
                  
                  {truck.location?.source && (
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, ml: 3 }}>
                      <Typography 
                        variant="caption" 
                        sx={{ 
                          color: getLocationConfidenceColor(truck.location.confidence),
                          fontWeight: 'bold'
                        }}
                      >
                        {formatLocationSource(truck.location.source)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        • Updated {truck.location.lastUpdated ? 
                          new Date(truck.location.lastUpdated).toLocaleDateString() : 
                          'Unknown'
                        }
                      </Typography>
                    </Box>
                  )}
                </Box>

                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Star sx={{ mr: 1, fontSize: 16, color: '#FFD700' }} />
                  <Rating value={truck.averageRating || 0} readOnly size="small" />
                  <Typography variant="body2" sx={{ ml: 1 }}>
                    ({truck.totalReviews || 0} reviews)
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 2 }}>
                  {truck.foodTypes?.slice(0, 3).map((type, index) => (
                    <Chip key={index} label={type} size="small" variant="outlined" />
                  ))}
                </Box>

                <Box sx={{ display: 'flex', gap: 1, mt: 'auto', flexWrap: 'wrap' }}>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<MenuIcon />}
                    onClick={() => handleViewMenu(truck)}
                    disabled={!truck.menu || truck.menu.length === 0}
                  >
                    Menu
                  </Button>
                  <Tooltip title="View location history">
                    <IconButton 
                      size="small" 
                      onClick={() => handleViewHistory(truck)}
                      sx={{ border: '1px solid', borderColor: 'divider' }}
                    >
                      <HistoryIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Report truck location">
                    <IconButton 
                      size="small" 
                      onClick={() => handleReportLocation(truck)}
                      color="secondary"
                      sx={{ border: '1px solid', borderColor: 'divider' }}
                    >
                      <ReportIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                  {truck.phoneNumber && (
                    <Button
                      variant="outlined"
                      size="small"
                      startIcon={<Phone />}
                      href={`tel:${truck.phoneNumber}`}
                      color="success"
                      sx={{ ml: 'auto' }}
                    >
                      Call
                    </Button>
                  )}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {foodTrucks.length === 0 && !loading && (
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Typography variant="h6" color="text.secondary">
            No food trucks found. Try adjusting your search or check back later!
          </Typography>
        </Box>
      )}

      {/* Menu Dialog */}
      <Dialog 
        open={menuDialogOpen} 
        onClose={() => setMenuDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h6">
              {selectedTruck?.name || selectedTruck?.businessName} - Menu
            </Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          {selectedTruck?.menu && selectedTruck.menu.length > 0 ? (
            <List>
              {selectedTruck.menu.map((item, index) => (
                <React.Fragment key={index}>
                  <ListItem sx={{ px: 0 }}>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                            {item.name}
                          </Typography>
                          <Typography variant="h6" color="primary" sx={{ fontWeight: 600 }}>
                            ${item.price?.toFixed(2)}
                          </Typography>
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" color="text.secondary">
                            {item.description}
                          </Typography>
                          <Chip 
                            label={item.category} 
                            size="small" 
                            sx={{ mt: 1 }} 
                            variant="outlined"
                          />
                        </Box>
                      }
                    />
                  </ListItem>
                  {index < selectedTruck.menu.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">
              No menu items available at the moment.
            </Typography>
          )}
        </DialogContent>
      </Dialog>

      {/* Location Report Dialog */}
      <Dialog 
        open={reportDialogOpen} 
        onClose={() => setReportDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Report Location for {reportingTruck?.name}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Spotted this food truck? Help other customers find it by reporting its current location.
          </Typography>
          
          <TextField
            fullWidth
            label="Location"
            placeholder="e.g., 123 Main St, Downtown, Central Park"
            value={reportLocation}
            onChange={(e) => setReportLocation(e.target.value)}
            sx={{ mb: 2 }}
            required
          />
          
          <TextField
            fullWidth
            label="Notes (optional)"
            placeholder="e.g., Near the fountain, serving until 3pm"
            value={reportNotes}
            onChange={(e) => setReportNotes(e.target.value)}
            multiline
            rows={2}
          />

          {reportError && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {reportError}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setReportDialogOpen(false)}>Cancel</Button>
          <Button onClick={submitLocationReport} variant="contained">
            Report Location
          </Button>
        </DialogActions>
      </Dialog>

      {/* Location History Dialog */}
      <Dialog 
        open={historyDialogOpen} 
        onClose={() => setHistoryDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Location History - {selectedTruck?.name}
        </DialogTitle>
        <DialogContent>
          {locationHistory.history && locationHistory.history.length > 0 ? (
            <List>
              {locationHistory.history.map((item, index) => (
                <ListItem key={index} sx={{ borderBottom: '1px solid #eee' }}>
                  <ListItemText
                    primary={
                      <Box>
                        <Typography variant="subtitle1">
                          {item.address || 'Unknown address'}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {item.city}, {item.state}
                        </Typography>
                      </Box>
                    }
                    secondary={
                      <Box sx={{ mt: 1 }}>
                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                          <Chip 
                            label={formatLocationSource(item.source)}
                            size="small"
                            sx={{ 
                              backgroundColor: getLocationConfidenceColor(item.confidence),
                              color: 'white'
                            }}
                          />
                          <Typography variant="caption">
                            {new Date(item.timestamp).toLocaleString()}
                          </Typography>
                        </Box>
                        {item.notes && (
                          <Typography variant="body2" sx={{ mt: 0.5, fontStyle: 'italic' }}>
                            {item.notes}
                          </Typography>
                        )}
                      </Box>
                    }
                  />
                </ListItem>
              ))}
            </List>
          ) : (
            <Typography>No location history available</Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHistoryDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Notifications Dialog */}
      <Dialog 
        open={showNotifications} 
        onClose={() => setShowNotifications(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Notifications />
            Recent Notifications
          </Box>
        </DialogTitle>
        <DialogContent>
          {notifications.length > 0 ? (
            <List>
              {notifications.map((notification) => (
                <ListItem key={notification.id} sx={{ borderBottom: '1px solid #eee' }}>
                  <ListItemText
                    primary={notification.title}
                    secondary={
                      <Box>
                        <Typography variant="body2">{notification.message}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {new Date(notification.timestamp).toLocaleString()}
                        </Typography>
                      </Box>
                    }
                  />
                </ListItem>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary" sx={{ textAlign: 'center', py: 4 }}>
              No notifications yet
            </Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNotifications([])}>Clear All</Button>
          <Button onClick={() => setShowNotifications(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Success Snackbar */}
      <Snackbar
        open={reportSuccess}
        autoHideDuration={4000}
        onClose={() => setReportSuccess(false)}
      >
        <Alert severity="success" onClose={() => setReportSuccess(false)}>
          Location reported successfully! Thank you for helping other customers find this truck.
        </Alert>
      </Snackbar>

      {/* User Profile Dialog */}
      <Dialog 
        open={showProfile} 
        onClose={() => setShowProfile(false)}
        maxWidth="lg"
        fullWidth
        fullScreen
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h5">My Profile</Typography>
          <IconButton onClick={() => setShowProfile(false)}>
            <Close />
          </IconButton>
        </DialogTitle>
        <DialogContent sx={{ p: 0 }}>
          <UserProfile />
        </DialogContent>
      </Dialog>

      {/* Authentication Dialog */}
      <CustomerAuth 
        open={showAuth}
        onClose={() => setShowAuth(false)}
        onAuthSuccess={handleAuthSuccess}
      />

      {/* Real-time Connection Status */}
      <Fab
        color="primary"
        size="small"
        sx={{
          position: 'fixed',
          bottom: 16,
          right: 16,
          background: socket?.connected ? 'linear-gradient(45deg, #4CAF50 30%, #8BC34A 90%)' : '#f44336',
          '&:hover': {
            background: socket?.connected ? 'linear-gradient(45deg, #45a049 30%, #7CB342 90%)' : '#d32f2f'
          }
        }}
        title={socket?.connected ? 'Connected to live updates' : 'Disconnected from live updates'}
      >
        {socket?.connected ? <LiveTv /> : <Refresh />}
      </Fab>
    </Container>
  );
};

export default CustomerHome; 