import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Box,
  Typography,
  Tab,
  Tabs,
  Alert,
  FormGroup,
  FormControlLabel,
  Switch,
  Slider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip
} from '@mui/material';
import { Person, Email, Lock, Phone } from '@mui/icons-material';

// Login Form Component
const LoginForm = React.memo(({ loginData, setLoginData }) => (
  <Box sx={{ p: 2 }}>
    <TextField
      fullWidth
      label="Email"
      type="email"
      value={loginData.email}
      onChange={(e) => setLoginData({ ...loginData, email: e.target.value })}
      margin="normal"
      InputProps={{
        startAdornment: <Email sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
    <TextField
      fullWidth
      label="Password"
      type="password"
      value={loginData.password}
      onChange={(e) => setLoginData({ ...loginData, password: e.target.value })}
      margin="normal"
      InputProps={{
        startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
  </Box>
));

// Registration Form Component
const RegisterForm = React.memo(({ registerData, setRegisterData }) => (
  <Box sx={{ p: 2 }}>
    <TextField
      fullWidth
      label="Full Name"
      value={registerData.name}
      onChange={(e) => setRegisterData({ ...registerData, name: e.target.value })}
      margin="normal"
      required
      InputProps={{
        startAdornment: <Person sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
    <TextField
      fullWidth
      label="Email"
      type="email"
      value={registerData.email}
      onChange={(e) => setRegisterData({ ...registerData, email: e.target.value })}
      margin="normal"
      required
      InputProps={{
        startAdornment: <Email sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
    <TextField
      fullWidth
      label="Phone (optional)"
      value={registerData.phone}
      onChange={(e) => setRegisterData({ ...registerData, phone: e.target.value })}
      margin="normal"
      InputProps={{
        startAdornment: <Phone sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
    <TextField
      fullWidth
      label="Password"
      type="password"
      value={registerData.password}
      onChange={(e) => setRegisterData({ ...registerData, password: e.target.value })}
      margin="normal"
      required
      helperText="At least 6 characters"
      InputProps={{
        startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />
    <TextField
      fullWidth
      label="Confirm Password"
      type="password"
      value={registerData.confirmPassword}
      onChange={(e) => setRegisterData({ ...registerData, confirmPassword: e.target.value })}
      margin="normal"
      required
      InputProps={{
        startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary' }} />
      }}
    />

    {/* Preferences */}
    <Typography variant="h6" sx={{ mt: 3, mb: 2 }}>
      Preferences (you can change these later)
    </Typography>
    
    <Typography variant="subtitle2" gutterBottom>
      Notifications
    </Typography>
    <FormGroup row sx={{ mb: 2 }}>
      <FormControlLabel
        control={
          <Switch
            checked={registerData.preferences.notifications.favoriteUpdates}
            onChange={(e) => setRegisterData({
              ...registerData,
              preferences: {
                ...registerData.preferences,
                notifications: {
                  ...registerData.preferences.notifications,
                  favoriteUpdates: e.target.checked
                }
              }
            })}
          />
        }
        label="Favorite truck updates"
      />
      <FormControlLabel
        control={
          <Switch
            checked={registerData.preferences.notifications.nearbyTrucks}
            onChange={(e) => setRegisterData({
              ...registerData,
              preferences: {
                ...registerData.preferences,
                notifications: {
                  ...registerData.preferences.notifications,
                  nearbyTrucks: e.target.checked
                }
              }
            })}
          />
        }
        label="Nearby trucks"
      />
    </FormGroup>

    <Typography variant="subtitle2" gutterBottom>
      Default search radius: {registerData.preferences.location.defaultRadius} miles
    </Typography>
    <Slider
      value={registerData.preferences.location.defaultRadius}
      onChange={(e, value) => setRegisterData({
        ...registerData,
        preferences: {
          ...registerData.preferences,
          location: {
            ...registerData.preferences.location,
            defaultRadius: value
          }
        }
      })}
      min={1}
      max={50}
      marks={[
        { value: 5, label: '5mi' },
        { value: 15, label: '15mi' },
        { value: 30, label: '30mi' },
        { value: 50, label: '50mi' }
      ]}
      sx={{ mb: 2 }}
    />
  </Box>
));

const CustomerAuth = ({ open, onClose, onAuthSuccess }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Login state
  const [loginData, setLoginData] = useState({
    email: '',
    password: ''
  });

  // Registration state
  const [registerData, setRegisterData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: '',
    preferences: {
      notifications: {
        pushEnabled: true,
        favoriteUpdates: true,
        nearbyTrucks: true,
        promotions: false
      },
      location: {
        shareLocation: true,
        defaultRadius: 15,
        autoDetectLocation: true
      },
      display: {
        theme: 'auto',
        showDistance: true,
        showPrices: true
      }
    }
  });

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
    setError('');
    setSuccess('');
  };

  const handleLogin = async () => {
    try {
      setLoading(true);
      setError('');

      if (!loginData.email || !loginData.password) {
        setError('Please fill in all fields');
        return;
      }

      const response = await fetch('http://localhost:3001/api/auth/login-customer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(loginData)
      });

      const data = await response.json();

      if (response.ok) {
        // Store token and user data
        localStorage.setItem('customerToken', data.token);
        localStorage.setItem('customerUser', JSON.stringify(data.user));
        
        setSuccess('Login successful!');
        setTimeout(() => {
          onAuthSuccess(data.user, data.token);
          onClose();
        }, 1000);
      } else {
        setError(data.message || 'Login failed');
      }
    } catch (error) {
      console.error('Login error:', error);
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async () => {
    try {
      setLoading(true);
      setError('');

      // Validation
      if (!registerData.name || !registerData.email || !registerData.password) {
        setError('Please fill in all required fields');
        return;
      }

      if (registerData.password !== registerData.confirmPassword) {
        setError('Passwords do not match');
        return;
      }

      if (registerData.password.length < 6) {
        setError('Password must be at least 6 characters');
        return;
      }

      const response = await fetch('http://localhost:3001/api/auth/register-customer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: registerData.name,
          email: registerData.email,
          password: registerData.password,
          phone: registerData.phone,
          preferences: registerData.preferences
        })
      });

      const data = await response.json();

      if (response.ok) {
        // Store token and user data
        localStorage.setItem('customerToken', data.token);
        localStorage.setItem('customerUser', JSON.stringify(data.user));
        
        setSuccess('Registration successful! Welcome to Food Truck Finder!');
        setTimeout(() => {
          onAuthSuccess(data.user, data.token);
          onClose();
        }, 1500);
      } else {
        setError(data.message || 'Registration failed');
      }
    } catch (error) {
      console.error('Registration error:', error);
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };



  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Box sx={{ textAlign: 'center' }}>
          <Typography variant="h4" component="h1" sx={{ fontWeight: 'bold', color: '#FF6B35', mb: 1 }}>
            🚚 Food Truck Finder
          </Typography>
          <Typography variant="subtitle1" color="text.secondary">
            Join our community of food truck lovers!
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Tabs value={activeTab} onChange={handleTabChange} centered>
          <Tab label="Login" />
          <Tab label="Register" />
        </Tabs>

        {error && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mt: 2 }}>
            {success}
          </Alert>
        )}

        {activeTab === 0 ? (
          <LoginForm loginData={loginData} setLoginData={setLoginData} />
        ) : (
          <RegisterForm registerData={registerData} setRegisterData={setRegisterData} />
        )}
      </DialogContent>

      <DialogActions sx={{ p: 3 }}>
        <Button onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={activeTab === 0 ? handleLogin : handleRegister}
          disabled={loading}
          sx={{ 
            px: 4,
            background: 'linear-gradient(45deg, #FF6B35 30%, #F7931E 90%)',
            '&:hover': {
              background: 'linear-gradient(45deg, #E55A2B 30%, #E8821A 90%)'
            }
          }}
        >
          {loading ? 'Please wait...' : (activeTab === 0 ? 'Login' : 'Create Account')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CustomerAuth; 