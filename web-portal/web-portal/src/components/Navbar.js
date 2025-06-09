import React, { useState, useEffect } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Box,
  IconButton,
  Menu,
  MenuItem,
} from '@mui/material';
import { AccountCircle, RestaurantMenu } from '@mui/icons-material';
import { Link, useNavigate } from 'react-router-dom';

const Navbar = () => {
  const [anchorEl, setAnchorEl] = useState(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userRole, setUserRole] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('token');
    const customerToken = localStorage.getItem('customerToken');
    const role = localStorage.getItem('userRole');
    setIsLoggedIn(!!(token || customerToken));
    setUserRole(role || 'customer');
  }, []);

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('customerToken');
    localStorage.removeItem('userRole');
    localStorage.removeItem('userId');
    localStorage.removeItem('customerUser');
    setIsLoggedIn(false);
    setUserRole(null);
    handleClose();
    navigate('/');
  };

  const handleDashboard = () => {
    if (userRole === 'owner') {
      navigate('/owner-dashboard');
    }
    handleClose();
  };

  return (
    <AppBar position="static" sx={{ backgroundColor: '#FF6B35' }}>
      <Toolbar>
        <RestaurantMenu sx={{ mr: 2 }} />
        <Typography 
          variant="h6" 
          component={Link}
          to="/"
          sx={{ 
            flexGrow: 1, 
            textDecoration: 'none', 
            color: 'inherit',
            fontWeight: 600
          }}
        >
          FoodTruck Finder
        </Typography>
        
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          {!isLoggedIn ? (
            <Button 
              color="inherit" 
              component={Link} 
              to="/register"
              variant="outlined"
              sx={{ 
                borderColor: 'white',
                fontSize: '0.875rem',
                '&:hover': {
                  borderColor: 'white',
                  backgroundColor: 'rgba(255, 255, 255, 0.1)'
                }
              }}
            >
              🚚 Food Truck Owners
            </Button>
          ) : (
            <>
              <IconButton
                size="large"
                aria-label="account of current user"
                aria-controls="menu-appbar"
                aria-haspopup="true"
                onClick={handleMenu}
                color="inherit"
              >
                <AccountCircle />
              </IconButton>
              <Menu
                id="menu-appbar"
                anchorEl={anchorEl}
                anchorOrigin={{
                  vertical: 'top',
                  horizontal: 'right',
                }}
                keepMounted
                transformOrigin={{
                  vertical: 'top',
                  horizontal: 'right',
                }}
                open={Boolean(anchorEl)}
                onClose={handleClose}
              >
                {userRole === 'owner' && (
                  <MenuItem onClick={handleDashboard}>Owner Dashboard</MenuItem>
                )}
                <MenuItem onClick={handleLogout}>Logout</MenuItem>
              </Menu>
            </>
          )}
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Navbar; 