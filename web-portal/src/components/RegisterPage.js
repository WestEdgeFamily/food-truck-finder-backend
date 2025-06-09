import React, { useState } from 'react';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Alert,
  Link,
  CircularProgress,
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material';
import { RestaurantMenu, Person, Business } from '@mui/icons-material';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { API_CONFIG } from '../config/api';

const RegisterPage = () => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    businessName: '',
    phoneNumber: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      setLoading(false);
      return;
    }

    if (formData.password.length < 6) {
      setError('Password must be at least 6 characters long');
      setLoading(false);
      return;
    }

    try {
      const response = await axios.post(`${API_CONFIG.BASE_URL}/api/auth/register`, {
        email: formData.email,
        password: formData.password,
        businessName: formData.businessName,
        phoneNumber: formData.phoneNumber,
      });

      const { token, role, _id } = response.data;
      
      // Store user data in localStorage
      localStorage.setItem('token', token);
      localStorage.setItem('userRole', role);
      localStorage.setItem('userId', _id);

      // Redirect to owner dashboard
      navigate('/owner-dashboard');
    } catch (err) {
      setError(err.response?.data?.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container component="main" maxWidth="sm">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            width: '100%',
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
            <RestaurantMenu sx={{ mr: 1, fontSize: 40, color: '#FF6B35' }} />
            <Typography component="h1" variant="h4" sx={{ fontWeight: 600, color: '#FF6B35' }}>
              FoodTruck Finder
            </Typography>
          </Box>
          
          <Typography component="h2" variant="h5" sx={{ mb: 3 }}>
            Register Your Food Truck Business
          </Typography>

          {error && (
            <Alert severity="error" sx={{ width: '100%', mb: 3 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ width: '100%' }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoComplete="email"
              autoFocus
              value={formData.email}
              onChange={handleInputChange}
              disabled={loading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              id="businessName"
              label="Business Name"
              name="businessName"
              autoComplete="organization"
              value={formData.businessName}
              onChange={handleInputChange}
              disabled={loading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              id="phoneNumber"
              label="Phone Number"
              name="phoneNumber"
              autoComplete="tel"
              value={formData.phoneNumber}
              onChange={handleInputChange}
              disabled={loading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              autoComplete="new-password"
              value={formData.password}
              onChange={handleInputChange}
              disabled={loading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              name="confirmPassword"
              label="Confirm Password"
              type="password"
              id="confirmPassword"
              value={formData.confirmPassword}
              onChange={handleInputChange}
              disabled={loading}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2, py: 1.5 }}
              disabled={loading}
            >
              {loading ? <CircularProgress size={24} /> : 'Create Account'}
            </Button>
            
            <Box sx={{ textAlign: 'center' }}>
              <Link component={RouterLink} to="/login" variant="body2">
                Already have a food truck business account? Sign In
              </Link>
            </Box>
          </Box>

          <Box sx={{ mt: 3, p: 2, backgroundColor: '#f5f5f5', borderRadius: 1, width: '100%' }}>
            <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center' }}>
              Food truck owners can manage their business information, menus, and location.
              <br />
              <strong>Customers:</strong> Use the "Login / Register" button on the main page to create a customer account.
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default RegisterPage; 