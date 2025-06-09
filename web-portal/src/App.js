import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import CustomerHome from './components/CustomerHome';
import LoginPage from './components/LoginPage';
import RegisterPage from './components/RegisterPage';
import OwnerDashboard from './components/Dashboard';
import Navbar from './components/Navbar';

// Capacitor imports
import { StatusBar } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Capacitor } from '@capacitor/core';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#FF6B35', // Food truck orange
    },
    secondary: {
      main: '#1976d2',
    },
    background: {
      default: '#f5f5f5',
    },
  },
  typography: {
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 500,
    },
  },
});

function App() {
  useEffect(() => {
    // Initialize mobile features if running on native platform
    if (Capacitor.isNativePlatform()) {
      // Configure status bar
      StatusBar.setStyle({ style: 'DARK' });
      StatusBar.setBackgroundColor({ color: '#FF6B35' });
      
      // Hide splash screen
      SplashScreen.hide();
    }
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Navbar />
        <Routes>
          <Route path="/" element={<CustomerHome />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/owner-dashboard" element={<OwnerDashboard />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;
