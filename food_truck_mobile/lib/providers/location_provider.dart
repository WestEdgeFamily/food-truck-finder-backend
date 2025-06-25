import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _permissionGranted = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get permissionGranted => _permissionGranted;

  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      _permissionGranted = permission.isGranted;
      
      if (!_permissionGranted) {
        _error = 'Location permission denied';
      }
      
      notifyListeners();
      return _permissionGranted;
    } catch (e) {
      _error = 'Error requesting location permission: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Request permission if not granted
      if (!_permissionGranted) {
        final permissionGranted = await requestLocationPermission();
        if (!permissionGranted) {
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _error = null;
    } catch (e) {
      _error = 'Error getting location: $e';
      debugPrint('Location error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double? getDistanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  String formatDistance(double distanceInMeters) {
    // Convert meters to miles (1 meter = 0.000621371 miles)
    final distanceInMiles = distanceInMeters * 0.000621371;
    
    if (distanceInMiles < 0.1) {
      // Show in feet for very short distances (1 mile = 5280 feet)
      final distanceInFeet = distanceInMeters * 3.28084;
      return '${distanceInFeet.round()}ft';
    } else {
      return '${distanceInMiles.toStringAsFixed(1)}mi';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 