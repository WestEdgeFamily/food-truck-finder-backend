const express = require('express');
const {
  createFoodTruck,
  getFoodTrucks,
  getFoodTruck,
  getMyTruck,
  updateFoodTruck,
  deleteFoodTruck,
  updateLocation,
  updateHours,
  updateFoodTypes,
  addRating,
  addMenuItem,
  deleteMenuItem,
  getFilters,
  searchFoodTrucks,
  // New social media tracking features
  reportLocation,
  updateSocialMedia,
  checkIn,
  adminUpdateLocation,
  getLocationHistory
} = require('../controllers/foodTruckController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', getFoodTrucks);
router.get('/search', searchFoodTrucks);
router.get('/filters', getFilters);
router.get('/:id', getFoodTruck);
router.get('/:id/location-history', getLocationHistory);

// Protected routes (authentication required)
router.use(protect);

// Owner routes
router.get('/my-truck', authorize('owner'), getMyTruck);
router.post('/', authorize('owner'), createFoodTruck);
router.put('/:id', authorize('owner'), updateFoodTruck);
router.delete('/:id', authorize('owner'), deleteFoodTruck);

// Location management routes
router.put('/:id/location', authorize('owner'), updateLocation);
router.put('/:id/hours', authorize('owner'), updateHours);
router.put('/:id/foodtypes', authorize('owner'), updateFoodTypes);

// Social media tracking routes
router.put('/my-truck/social-media', authorize('owner'), updateSocialMedia);
router.post('/my-truck/checkin', authorize('owner'), checkIn);

// Customer interaction routes
router.post('/:id/report-location', reportLocation); // Any authenticated user can report
router.post('/:id/rating', addRating);

// Menu management routes
router.post('/:id/menu', authorize('owner'), addMenuItem);
router.delete('/:id/menu/:itemId', authorize('owner'), deleteMenuItem);

// Admin routes (for manual social media tracking)
router.put('/:id/admin-location', adminUpdateLocation); // TODO: Add admin authorization

// TODO: GPS tracking routes (commented out for future implementation)
/*
router.put('/my-truck/enable-gps', authorize('owner'), enableGpsTracking);
router.post('/gps-update', gpsLocationUpdate); // Called by GPS service
*/

module.exports = router; 