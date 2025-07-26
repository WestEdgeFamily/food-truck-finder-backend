import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../utils/global_error_handler.dart';
import 'cache_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  late Dio _dio;
  final Connectivity _connectivity = Connectivity();
  final CacheService _cacheService = CacheService();
  
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final _onlineStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get onlineStatus => _onlineStatusController.stream;
  bool get isOnline => _isOnline;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_createInterceptor());
    
    // Monitor connectivity
    _monitorConnectivity();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
  }

  InterceptorsWrapper _createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await _getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        debugPrint('🔍 ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) async {
        debugPrint('✅ ${response.statusCode} ${response.requestOptions.uri}');
        
        // Cache successful GET requests
        if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
          await _cacheService.cacheResponse(
            response.requestOptions.uri.toString(),
            response.data,
          );
        }
        
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('❌ ${error.type} ${error.requestOptions.uri}');
        
        // If offline and it's a GET request, try to return cached data
        if (!_isOnline && error.requestOptions.method == 'GET') {
          final cachedData = await _cacheService.getCachedResponse(
            error.requestOptions.uri.toString(),
          );
          
          if (cachedData != null) {
            debugPrint('📦 Returning cached data for ${error.requestOptions.uri}');
            handler.resolve(Response(
              requestOptions: error.requestOptions,
              data: cachedData,
              statusCode: 200,
              statusMessage: 'From Cache (Offline)',
            ));
            return;
          }
        }
        
        handler.next(error);
      },
    );
  }

  void _monitorConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        debugPrint(_isOnline ? '🌐 Back online!' : '📵 Gone offline!');
        _onlineStatusController.add(_isOnline);
      }
    });
    
    // Check initial connectivity
    _connectivity.checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
      _onlineStatusController.add(_isOnline);
    });
  }

  Future<String?> _getAuthToken() async {
    // This should be implemented to get token from secure storage
    // For now, return null
    return null;
  }

  // HTTP Methods with error handling and offline support
  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useCache = true,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e, stackTrace) {
      GlobalErrorHandler.handleError(e, stackTrace: stackTrace, context: context);
      
      // If offline and cache is enabled, try to return cached data
      if (!_isOnline && useCache) {
        final cachedData = await _cacheService.getCachedResponse(
          '$path${_queryParamsToString(queryParameters)}',
        );
        if (cachedData != null) {
          return cachedData as T?;
        }
      }
      
      return null;
    }
  }

  Future<T?> post<T>(
    String path, {
    dynamic data,
    BuildContext? context,
  }) async {
    if (!_isOnline) {
      if (context != null) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          'Cannot perform this action while offline',
        );
      }
      return null;
    }

    try {
      final response = await _dio.post<T>(
        path,
        data: data,
      );
      return response.data;
    } catch (e, stackTrace) {
      GlobalErrorHandler.handleError(e, stackTrace: stackTrace, context: context);
      return null;
    }
  }

  Future<T?> put<T>(
    String path, {
    dynamic data,
    BuildContext? context,
  }) async {
    if (!_isOnline) {
      if (context != null) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          'Cannot perform this action while offline',
        );
      }
      return null;
    }

    try {
      final response = await _dio.put<T>(
        path,
        data: data,
      );
      return response.data;
    } catch (e, stackTrace) {
      GlobalErrorHandler.handleError(e, stackTrace: stackTrace, context: context);
      return null;
    }
  }

  Future<T?> delete<T>(
    String path, {
    BuildContext? context,
  }) async {
    if (!_isOnline) {
      if (context != null) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          'Cannot perform this action while offline',
        );
      }
      return null;
    }

    try {
      final response = await _dio.delete<T>(path);
      return response.data;
    } catch (e, stackTrace) {
      GlobalErrorHandler.handleError(e, stackTrace: stackTrace, context: context);
      return null;
    }
  }

  Future<Response?> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    Function(int, int)? onSendProgress,
    BuildContext? context,
  }) async {
    if (!_isOnline) {
      if (context != null) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          'Cannot upload files while offline',
        );
      }
      return null;
    }

    try {
      final formData = FormData();
      
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(filePath),
      ));
      
      if (additionalData != null) {
        formData.fields.addAll(
          additionalData.entries.map((e) => MapEntry(e.key, e.value.toString())),
        );
      }
      
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      
      return response;
    } catch (e, stackTrace) {
      GlobalErrorHandler.handleError(e, stackTrace: stackTrace, context: context);
      return null;
    }
  }

  String _queryParamsToString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '?$queryString';
  }
}

// Singleton getter
final networkService = NetworkService();