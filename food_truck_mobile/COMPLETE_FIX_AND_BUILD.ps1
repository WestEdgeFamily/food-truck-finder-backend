# Complete Fix and Build Script for Food Truck App
# This addresses all build issues including Kotlin cache, null safety, and cross-drive problems

Write-Host "Food Truck App Complete Fix Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Set error action preference
$ErrorActionPreference = "Continue"

# Function to kill processes
function Kill-ProcessesByName {
    param($ProcessName)
    Get-Process | Where-Object { $_.ProcessName -like "*$ProcessName*" } | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "Step 1: Stopping all Java/Kotlin processes..." -ForegroundColor Yellow
Kill-ProcessesByName "java"
Kill-ProcessesByName "kotlin"
Start-Sleep -Seconds 2

Write-Host "Step 2: Deep cleaning all build artifacts and caches..." -ForegroundColor Yellow

# Clean Flutter
flutter clean 2>$null

# Remove all build directories
$dirsToRemove = @(
    "build",
    ".dart_tool",
    ".gradle",
    "android\.gradle",
    "android\app\build",
    "android\build",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages"
)

foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        # Use robocopy to delete (handles long paths and locked files better)
        $null = robocopy /MIR "$env:TEMP\empty_dir_$(Get-Random)" $dir 2>$null
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Step 3: Clearing ALL Gradle and Kotlin caches..." -ForegroundColor Yellow

# Clear user-level Gradle cache
$gradleCaches = @(
    "$env:USERPROFILE\.gradle\caches",
    "$env:USERPROFILE\.gradle\daemon",
    "$env:USERPROFILE\.gradle\native",
    "$env:USERPROFILE\.gradle\wrapper"
)

foreach ($cache in $gradleCaches) {
    if (Test-Path $cache) {
        Get-ChildItem -Path $cache -Recurse -Force -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*kotlin*" -or $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Clear Kotlin daemon
$kotlinDirs = @(
    "$env:USERPROFILE\.kotlin",
    "$env:LOCALAPPDATA\kotlin"
)

foreach ($dir in $kotlinDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared: $dir" -ForegroundColor Gray
    }
}

# Clear temp files
$tempPatterns = @("*kotlin*", "*.lock", "*gradle*", "*flutter*")
foreach ($pattern in $tempPatterns) {
    Get-ChildItem -Path $env:TEMP -Filter $pattern -Recurse -ErrorAction SilentlyContinue | 
        Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Step 4: Setting up environment..." -ForegroundColor Yellow

# Set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Set Flutter to D: drive
$env:FLUTTER_ROOT = "D:\flutter"
$env:PATH = "$env:FLUTTER_ROOT\bin;$env:PATH"

Write-Host "  JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
Write-Host "  FLUTTER_ROOT: $env:FLUTTER_ROOT" -ForegroundColor Gray

Write-Host ""
Write-Host "Step 5: Fixing null safety errors in Dart code..." -ForegroundColor Yellow

# Create a temporary fix file for auth_provider.dart
$authProviderContent = @'
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        final userId = prefs.getString('user_id');
        final userEmail = prefs.getString('user_email');
        final userName = prefs.getString('user_name');
        final userRole = prefs.getString('user_role');
        final userBusinessName = prefs.getString('user_business_name');
        
        if (userId != null && userEmail != null && userName != null && userRole != null) {
          _user = User(
            id: userId,
            email: userEmail,
            name: userName,
            role: userRole,
            businessName: userBusinessName,
          );
          _isAuthenticated = true;
          
          debugPrint('✅ Loaded auth state: $_user');
        } else {
          // Try to load from cache if preferences are incomplete
          final cachedUser = await CacheService.getCachedUserData();
          if (cachedUser != null) {
            _user = User.fromJson(cachedUser);
            _isAuthenticated = true;
            debugPrint('✅ Loaded user from cache: $_user');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading auth state: $e');
    }
    notifyListeners();
  }

  Future<void> login(String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password, role);
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _isAuthenticated = true;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        final token = _token;
        final user = _user;
        if (token != null && user != null) {
          await prefs.setString('auth_token', token);
          await prefs.setString('user_id', user.id);
          await prefs.setString('user_email', user.email);
          await prefs.setString('user_name', user.name);
          await prefs.setString('user_role', user.role);
          if (user.businessName != null) {
            await prefs.setString('user_business_name', user.businessName!);
          }
        }
        
        // Cache user data for offline use
        await CacheService.cacheUserData(response['user']);
        
        // Handle new owner registration
        if (role == 'owner' && response['user']['foodTruckId'] != null) {
          debugPrint('🚚 New owner registered with auto-created food truck: ${response['user']['foodTruckId']}');
        }
        
        debugPrint('✅ Login successful: ${user!.email} (${user.role})');
        _error = null;
      } else {
        _error = response['message'] ?? 'Login failed';
        debugPrint('❌ Login failed: $_error');
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      debugPrint('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      debugPrint('🔍 AuthProvider received registration response: $response');
      debugPrint('🔍 Looking for success field: ${response['success']}');
      debugPrint('🔍 Registration response keys: ${response.keys.toList()}');
      
      // Check for different possible response formats
      if (response['success'] == true || response.containsKey('token')) {
        _token = response['token'];
        
        // Handle different user data formats
        Map<String, dynamic> userDataFromResponse;
        if (response['user'] != null) {
          userDataFromResponse = response['user'];
        } else {
          // If no 'user' field, use the response directly
          userDataFromResponse = response;
        }
        debugPrint('🔍 Registration user data to parse: $userDataFromResponse');
        
        _user = User.fromJson(userDataFromResponse);

        // Save to SharedPreferences - this auto-logs them in
        final prefs = await SharedPreferences.getInstance();
        final token = _token;
        final user = _user;
        if (token != null && user != null) {
          await prefs.setString('auth_token', token);
          await prefs.setString('user_role', user.role);
          await prefs.setString('user_id', user.id);
          await prefs.setString('user_name', user.name);
          await prefs.setString('user_email', user.email);
          if (user.businessName != null) {
            await prefs.setString('user_business_name', user.businessName!);
          }

          debugPrint('✅ Registration successful! User auto-logged in: ${user.name}');
        }
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Registration failed - no success flag or token found');
      }
    } catch (e) {
      debugPrint('💥 Registration error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Clear user cache
      await CacheService.clearUserCache();
      
      _token = null;
      _user = null;
      _isAuthenticated = false;
      _error = null;
      
      debugPrint('✅ Logged out successfully');
    } catch (e) {
      _error = 'Error during logout';
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force clear all authentication data - for debugging/testing
  Future<void> forceLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear specific auth keys
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_business_name');
      // Clear everything else too
      await prefs.clear();
      debugPrint('🧹 All authentication data cleared');
    } catch (e) {
      debugPrint('Force logout error: $e');
    }

    _user = null;
    _token = null;
    notifyListeners();
  }

  // Add method to check if we have stored credentials
  Future<bool> hasStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      return token != null && userId != null;
    } catch (e) {
      debugPrint('Error checking stored credentials: $e');
      return false;
    }
  }

  // Method to verify if the stored session is still valid
  Future<bool> validateStoredSession() async {
    try {
      if (!await hasStoredCredentials()) {
        return false;
      }
      
      // If we have credentials but no current user, try to restore
      if (_user == null) {
        await _loadAuthState();
      }
      
      return _user != null && _token != null;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return false;
    }
  }

  bool isOwner() => _user?.role == 'owner';
  bool isCustomer() => _user?.role == 'customer';

  // Check authentication status (used by SplashScreen)
  Future<void> checkAuthStatus() async {
    await _loadAuthState();
    await validateStoredSession();
  }

  // Update user email immediately after successful email change
  Future<void> updateUserEmail(String newEmail) async {
    final currentUser = _user;
    if (currentUser != null) {
      _user = User(
        id: currentUser.id,
        name: currentUser.name,
        email: newEmail, // Update the email
        role: currentUser.role,
        businessName: currentUser.businessName,
      );
      
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', newEmail);
      
      debugPrint('✅ User email updated in AuthProvider: $newEmail');
      notifyListeners(); // This will refresh all UI components
    }
  }

  Future<void> clearUserData() async {
    _user = null;
    _token = null;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_business_name');
    
    notifyListeners();
  }
}
'@

# Save the fixed auth_provider.dart
$authProviderContent | Out-File -FilePath "lib\providers\auth_provider.dart" -Encoding UTF8

Write-Host "  Fixed null safety issues in auth_provider.dart" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 7: Building AAB bundle..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Gray

# Build with special flags to avoid issues
$env:GRADLE_OPTS = "-Xmx4096m -XX:+HeapDumpOnOutOfMemoryError"
flutter build appbundle `
    --release `
    --no-tree-shake-icons `
    --dart-define=API_URL=https://food-truck-finder-api.onrender.com/api `
    --verbose

$buildSuccess = $LASTEXITCODE -eq 0

if ($buildSuccess -and (Test-Path "build\app\outputs\bundle\release\app-release.aab")) {
    Copy-Item -Path "build\app\outputs\bundle\release\app-release.aab" -Destination "..\food-truck-v2.2.1-build86-FINAL.aab" -Force
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "AAB saved as: food-truck-v2.2.1-build86-FINAL.aab" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
}

Read-Host "Press Enter to exit"