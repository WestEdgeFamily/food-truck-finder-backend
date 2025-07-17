import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class ErrorHandler {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  // Handle different types of errors
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid data format received from server.';
    } else if (error.toString().contains('401')) {
      return 'Authentication failed. Please login again.';
    } else if (error.toString().contains('403')) {
      return 'You don\'t have permission to perform this action.';
    } else if (error.toString().contains('404')) {
      return 'Resource not found.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('NetworkImage')) {
      return 'Failed to load image.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // Show error as SnackBar
  static void showError(BuildContext context, dynamic error, {String? prefix}) {
    final message = prefix != null 
        ? '$prefix: ${getErrorMessage(error)}' 
        : getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show error globally (when context is not available)
  static void showGlobalError(dynamic error, {String? prefix}) {
    final message = prefix != null 
        ? '$prefix: ${getErrorMessage(error)}' 
        : getErrorMessage(error);
    
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Retry mechanism with exponential backoff
  static Future<T> retryOnError<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        // Skip retry for certain errors
        if (error.toString().contains('401') || 
            error.toString().contains('403') ||
            error.toString().contains('404')) {
          rethrow;
        }
        
        debugPrint('Retry attempt $attempt after ${delay.inSeconds} seconds');
        await Future.delayed(delay);
        
        // Exponential backoff
        delay = Duration(seconds: delay.inSeconds * 2);
      }
    }
    
    throw Exception('Failed after $maxAttempts attempts');
  }

  // Handle API errors with automatic retry
  static Future<T> handleApiCall<T>({
    required Future<T> Function() apiCall,
    required BuildContext context,
    bool showError = true,
    int maxRetries = 3,
  }) async {
    try {
      return await retryOnError(
        operation: apiCall,
        maxAttempts: maxRetries,
      );
    } catch (error) {
      if (showError) {
        ErrorHandler.showError(context, error);
      }
      rethrow;
    }
  }
}

// Error widget for image loading failures
class ErrorImageWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const ErrorImageWidget({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.broken_image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          icon,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }
}

// Wrapper widget that handles errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _errorDetails = details;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorDetails!.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
    }
    
    return widget.child;
  }
} 