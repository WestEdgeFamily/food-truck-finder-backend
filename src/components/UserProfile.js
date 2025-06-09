import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Avatar,
  Grid,
  Card,
  CardContent,
  CardMedia,
  Switch,
  TextField,
  Button,
  Chip,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Slider,
  FormGroup,
  FormControlLabel,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Badge,
  Divider,
  LinearProgress
} from '@mui/material';
import {
  Favorite,
  FavoriteBorder,
  Settings,
  Analytics,
  LocationOn,
  Star,
  Notifications,
  Edit,
  PhotoCamera,
  Restaurant,
  History,
  Person,
  Timeline,
  MapIcon,
  Palette,
  Language,
  Security,
  Delete,
  Share
} from '@mui/icons-material';

const UserProfile = () => {
  const [user, setUser] = useState(null);
  const [favorites, setFavorites] = useState([]);
  const [activeTab, setActiveTab] = useState(0);
  const [editMode, setEditMode] = useState(false);
  const [preferences, setPreferences] = useState({
    notifications: {},
    location: {},
    display: {}
  });
  const [activity, setActivity] = useState(null);
  const [recommendations, setRecommendations] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUserProfile();
    fetchFavorites();
    fetchActivity();
    fetchRecommendations();
  }, []);

  const fetchUserProfile = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) return;

      const response = await fetch('http://localhost:3001/api/users/profile', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const userData = await response.json();
        setUser(userData);
        setPreferences(userData.preferences || {
          notifications: {},
          location: {},
          display: {}
        });
      }
    } catch (error) {
      console.error('Error fetching profile:', error);
    }
  };

  const fetchFavorites = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) return;

      const response = await fetch('http://localhost:3001/api/users/favorites', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const data = await response.json();
        setFavorites(data.favorites || []);
      }
    } catch (error) {
      console.error('Error fetching favorites:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchActivity = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) return;

      const response = await fetch('http://localhost:3001/api/users/activity', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const data = await response.json();
        setActivity(data);
      }
    } catch (error) {
      console.error('Error fetching activity:', error);
    }
  };

  const fetchRecommendations = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      if (!token) return;

      const response = await fetch('http://localhost:3001/api/users/recommendations', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const data = await response.json();
        setRecommendations(data.recommendations || []);
      }
    } catch (error) {
      console.error('Error fetching recommendations:', error);
    }
  };

  const updateProfile = async () => {
    try {
      const token = localStorage.getItem('customerToken');
      
      const response = await fetch('http://localhost:3001/api/users/profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          name: user.name,
          phone: user.phone,
          profile: user.profile,
          preferences
        })
      });

      if (response.ok) {
        setEditMode(false);
        fetchUserProfile();
      }
    } catch (error) {
      console.error('Error updating profile:', error);
    }
  };

  const removeFavorite = async (truckId) => {
    try {
      const token = localStorage.getItem('customerToken');
      
      const response = await fetch(`http://localhost:3001/api/users/favorites/${truckId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (response.ok) {
        fetchFavorites();
      }
    } catch (error) {
      console.error('Error removing favorite:', error);
    }
  };

  const ProfileHeader = () => (
    <Paper sx={{ p: 3, mb: 3, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', color: 'white' }}>
      <Grid container spacing={2} alignItems="center">
        <Grid item>
          <Avatar
            src={user?.avatar}
            sx={{ width: 80, height: 80, border: '3px solid white' }}
          >
            {user?.name?.charAt(0)}
          </Avatar>
        </Grid>
        <Grid size="grow">
          <Typography variant="h4" gutterBottom>
            {user?.name || 'Customer'}
          </Typography>
          <Typography variant="subtitle1" sx={{ opacity: 0.9 }}>
            {user?.email}
          </Typography>
          <Box sx={{ mt: 1, display: 'flex', gap: 1 }}>
            <Chip 
              icon={<Favorite />} 
              label={`${favorites.length} Favorites`} 
              size="small"
              sx={{ backgroundColor: 'rgba(255,255,255,0.2)', color: 'white' }}
            />
            <Chip 
              icon={<Timeline />} 
              label={`${activity?.statistics?.totalVisits || 0} Visits`} 
              size="small"
              sx={{ backgroundColor: 'rgba(255,255,255,0.2)', color: 'white' }}
            />
          </Box>
        </Grid>
        <Grid size="auto">
          <Button
            variant="outlined"
            startIcon={<Edit />}
            onClick={() => setEditMode(true)}
            sx={{ borderColor: 'white', color: 'white' }}
          >
            Edit Profile
          </Button>
        </Grid>
      </Grid>
    </Paper>
  );

  const FavoritesTab = () => (
    <Box>
      {loading ? (
        <LinearProgress />
      ) : favorites.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Restaurant sx={{ fontSize: 60, color: 'grey.400', mb: 2 }} />
          <Typography variant="h6" color="textSecondary">
            No favorites yet
          </Typography>
          <Typography color="textSecondary">
            Start exploring and add food trucks to your favorites!
          </Typography>
        </Paper>
      ) : (
        <Grid container spacing={2}>
          {favorites.map((truck) => (
            <Grid size={{ xs: 12, md: 6 }} key={truck._id}>
              <Card sx={{ display: 'flex', position: 'relative' }}>
                {truck.images && truck.images[0] && (
                  <CardMedia
                    component="img"
                    sx={{ width: 160 }}
                    image={truck.images[0]}
                    alt={truck.name}
                  />
                )}
                <Box sx={{ display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <CardContent sx={{ flex: '1 0 auto' }}>
                    <Typography component="div" variant="h6">
                      {truck.name}
                    </Typography>
                    <Typography variant="subtitle1" color="text.secondary">
                      {truck.cuisineType}
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                      <Star sx={{ color: 'gold', mr: 0.5 }} />
                      <Typography variant="body2">
                        {truck.averageRating?.toFixed(1) || 'No ratings'}
                      </Typography>
                    </Box>
                    {truck.favoriteInfo?.notes && (
                      <Typography variant="body2" sx={{ mt: 1, fontStyle: 'italic' }}>
                        "{truck.favoriteInfo.notes}"
                      </Typography>
                    )}
                    <Typography variant="caption" color="text.secondary">
                      Added {new Date(truck.favoriteInfo?.addedDate).toLocaleDateString()}
                    </Typography>
                  </CardContent>
                </Box>
                <IconButton
                  sx={{ position: 'absolute', top: 8, right: 8 }}
                  onClick={() => removeFavorite(truck._id)}
                >
                  <Favorite color="error" />
                </IconButton>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
      
      {recommendations.length > 0 && (
        <Box sx={{ mt: 4 }}>
          <Typography variant="h6" gutterBottom>
            Recommended for You
          </Typography>
          <Grid container spacing={2}>
            {recommendations.slice(0, 4).map((truck) => (
              <Grid size={{ xs: 12, sm: 6, md: 3 }} key={truck._id}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" noWrap>
                      {truck.name}
                    </Typography>
                    <Typography color="textSecondary">
                      {truck.cuisineType}
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                      <Star sx={{ color: 'gold', mr: 0.5 }} />
                      <Typography variant="body2">
                        {truck.averageRating?.toFixed(1)}
                      </Typography>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}
    </Box>
  );

  const SettingsTab = () => (
    <Grid container spacing={3}>
      <Grid size={{ xs: 12, md: 6 }}>
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <Notifications sx={{ mr: 1 }} />
            Notifications
          </Typography>
          <FormGroup>
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.notifications?.pushEnabled || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    notifications: { ...preferences.notifications, pushEnabled: e.target.checked }
                  })}
                />
              }
              label="Push Notifications"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.notifications?.favoriteUpdates || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    notifications: { ...preferences.notifications, favoriteUpdates: e.target.checked }
                  })}
                />
              }
              label="Favorite Truck Updates"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.notifications?.nearbyTrucks || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    notifications: { ...preferences.notifications, nearbyTrucks: e.target.checked }
                  })}
                />
              }
              label="Nearby Trucks"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.notifications?.promotions || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    notifications: { ...preferences.notifications, promotions: e.target.checked }
                  })}
                />
              }
              label="Promotions & Deals"
            />
          </FormGroup>
        </Paper>
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <LocationOn sx={{ mr: 1 }} />
            Location Settings
          </Typography>
          <FormGroup>
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.location?.shareLocation || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    location: { ...preferences.location, shareLocation: e.target.checked }
                  })}
                />
              }
              label="Share Location"
            />
            <FormControlLabel
              control={
                <Switch
                  checked={preferences.location?.autoDetectLocation || false}
                  onChange={(e) => setPreferences({
                    ...preferences,
                    location: { ...preferences.location, autoDetectLocation: e.target.checked }
                  })}
                />
              }
              label="Auto-Detect Location"
            />
          </FormGroup>
          <Box sx={{ mt: 2 }}>
            <Typography gutterBottom>
              Default Search Radius: {preferences.location?.defaultRadius || 15} miles
            </Typography>
            <Slider
              value={preferences.location?.defaultRadius || 15}
              onChange={(e, value) => setPreferences({
                ...preferences,
                location: { ...preferences.location, defaultRadius: value }
              })}
              min={1}
              max={50}
              marks={[
                { value: 5, label: '5mi' },
                { value: 15, label: '15mi' },
                { value: 30, label: '30mi' },
                { value: 50, label: '50mi' }
              ]}
            />
          </Box>
        </Paper>
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <Palette sx={{ mr: 1 }} />
            Display Settings
          </Typography>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <FormControl fullWidth>
              <InputLabel>Theme</InputLabel>
              <Select
                value={preferences.display?.theme || 'auto'}
                onChange={(e) => setPreferences({
                  ...preferences,
                  display: { ...preferences.display, theme: e.target.value }
                })}
              >
                <MenuItem value="light">Light</MenuItem>
                <MenuItem value="dark">Dark</MenuItem>
                <MenuItem value="auto">Auto</MenuItem>
              </Select>
            </FormControl>
            <FormGroup>
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.display?.showDistance || false}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      display: { ...preferences.display, showDistance: e.target.checked }
                    })}
                  />
                }
                label="Show Distance"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.display?.showPrices || false}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      display: { ...preferences.display, showPrices: e.target.checked }
                    })}
                  />
                }
                label="Show Prices"
              />
            </FormGroup>
          </Box>
        </Paper>
      </Grid>

      <Grid size={12}>
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
          <Button onClick={fetchUserProfile}>
            Cancel
          </Button>
          <Button variant="contained" onClick={updateProfile}>
            Save Settings
          </Button>
        </Box>
      </Grid>
    </Grid>
  );

  const ActivityTab = () => (
    <Grid container spacing={3}>
      <Grid size={{ xs: 12, md: 4 }}>
        <Paper sx={{ p: 2, textAlign: 'center' }}>
          <Analytics sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
          <Typography variant="h4">
            {activity?.statistics?.totalVisits || 0}
          </Typography>
          <Typography color="textSecondary">
            Total App Visits
          </Typography>
        </Paper>
      </Grid>
      <Grid size={{ xs: 12, md: 4 }}>
        <Paper sx={{ p: 2, textAlign: 'center' }}>
          <Restaurant sx={{ fontSize: 48, color: 'secondary.main', mb: 1 }} />
          <Typography variant="h4">
            {activity?.statistics?.trucksVisited || 0}
          </Typography>
          <Typography color="textSecondary">
            Trucks Visited
          </Typography>
        </Paper>
      </Grid>
      <Grid size={{ xs: 12, md: 4 }}>
        <Paper sx={{ p: 2, textAlign: 'center' }}>
          <Star sx={{ fontSize: 48, color: 'warning.main', mb: 1 }} />
          <Typography variant="h4">
            {activity?.statistics?.averageRating?.toFixed(1) || '0.0'}
          </Typography>
          <Typography color="textSecondary">
            Average Rating Given
          </Typography>
        </Paper>
      </Grid>

      {activity?.statistics?.recentSearches?.length > 0 && (
        <Grid size={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Recent Searches
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
              {activity.statistics.recentSearches.map((search, index) => (
                <Chip key={index} label={search.query} size="small" />
              ))}
            </Box>
          </Paper>
        </Grid>
      )}
    </Grid>
  );

  if (!user) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <Typography>Please log in to view your profile</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ maxWidth: 1200, mx: 'auto', p: 2 }}>
      <ProfileHeader />
      
      <Paper sx={{ width: '100%' }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
          <Tab icon={<Favorite />} label="Favorites" />
          <Tab icon={<Settings />} label="Settings" />
          <Tab icon={<Analytics />} label="Activity" />
        </Tabs>
        
        <Box sx={{ p: 3 }}>
          {activeTab === 0 && <FavoritesTab />}
          {activeTab === 1 && <SettingsTab />}
          {activeTab === 2 && <ActivityTab />}
        </Box>
      </Paper>

      {/* Edit Profile Dialog */}
      <Dialog open={editMode} onClose={() => setEditMode(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Edit Profile</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Name"
            value={user.name || ''}
            onChange={(e) => setUser({ ...user, name: e.target.value })}
            margin="normal"
          />
          <TextField
            fullWidth
            label="Phone"
            value={user.phone || ''}
            onChange={(e) => setUser({ ...user, phone: e.target.value })}
            margin="normal"
          />
          <TextField
            fullWidth
            label="Bio"
            multiline
            rows={3}
            value={user.profile?.bio || ''}
            onChange={(e) => setUser({
              ...user,
              profile: { ...user.profile, bio: e.target.value }
            })}
            margin="normal"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditMode(false)}>Cancel</Button>
          <Button onClick={updateProfile} variant="contained">Save</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UserProfile; 