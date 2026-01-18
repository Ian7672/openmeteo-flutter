import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller untuk status koneksi
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  Timer? _timer;

  // Mulai monitoring koneksi internet
  void startMonitoring() {
    // Interval yang berbeda untuk mobile dan web
    final interval = kIsWeb ? Duration(seconds: 5) : Duration(seconds: 8);
    
    _timer = Timer.periodic(interval, (timer) {
      checkConnection();
    });
    // Check immediately
    checkConnection();
  }

  // Hentikan monitoring
  void stopMonitoring() {
    _timer?.cancel();
    _connectionController.close();
  }

  // Check koneksi internet dengan method yang kompatibel web
  Future<void> checkConnection() async {
    bool previousStatus = _isConnected;
    
    try {
      if (kIsWeb) {
        // Untuk web platform, gunakan HTTP request
        _isConnected = await _checkConnectionWeb();
      } else {
        // Untuk mobile platform, gunakan DNS lookup
        _isConnected = await _checkConnectionMobile();
      }
    } catch (e) {
      print('Connection check error: $e');
      _isConnected = false;
    }

    // Jika status berubah, broadcast ke listeners
    if (previousStatus != _isConnected) {
      _connectionController.add(_isConnected);
      print('Connection status changed: $_isConnected');
    }
  }

  // Check koneksi untuk platform web
  Future<bool> _checkConnectionWeb() async {
    try {
      // Gunakan endpoint yang ringan dan cepat
      final response = await http.head(
        Uri.parse('https://www.google.com/favicon.ico'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(Duration(seconds: 8));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Web connection check failed: $e');
      
      // Fallback ke endpoint lain
      try {
        final response = await http.head(
          Uri.parse('https://httpbin.org/status/200'),
        ).timeout(Duration(seconds: 5));
        
        return response.statusCode == 200;
      } catch (e2) {
        print('Fallback connection check failed: $e2');
        return false;
      }
    }
  }

  // Check koneksi untuk platform mobile
  Future<bool> _checkConnectionMobile() async {
    try {
      // Coba beberapa metode untuk mobile
      
      // Method 1: DNS lookup (paling cepat)
      try {
        final result = await InternetAddress.lookup('8.8.8.8')
            .timeout(Duration(seconds: 3));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        print('DNS lookup 8.8.8.8 failed: $e');
      }

      // Method 2: DNS lookup Google
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 5));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        print('DNS lookup google.com failed: $e');
      }

      // Method 3: HTTP fallback
      try {
        final client = HttpClient();
        client.connectionTimeout = Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse('https://www.google.com'));
        final response = await request.close().timeout(Duration(seconds: 3));
        client.close();
        
        return response.statusCode == 200;
      } catch (e) {
        print('HTTP fallback failed: $e');
      }

      return false;
    } catch (e) {
      print('Mobile connection check error: $e');
      return false;
    }
  }

  // Check koneksi dengan HTTP request sebagai backup
  Future<bool> checkConnectionWithHTTP() async {
    try {
      if (kIsWeb) {
        return await _checkConnectionWeb();
      } else {
        // Untuk mobile, tetap gunakan HTTP client
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('https://www.google.com'))
            .timeout(Duration(seconds: 8));
        final response = await request.close().timeout(Duration(seconds: 5));
        client.close();
        
        return response.statusCode == 200;
      }
    } catch (e) {
      print('HTTP connection check failed: $e');
      return false;
    }
  }

  // Force check untuk refresh manual
  Future<bool> forceCheck() async {
    await checkConnection();
    return _isConnected;
  }

  // Test koneksi ke API weather secara spesifik
  Future<bool> testWeatherAPI() async {
    try {
      final response = await http.head(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current_weather=true'),
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Weather API test failed: $e');
      return false;
    }
  }

  // Check koneksi dengan multiple endpoints untuk reliabilitas
  Future<bool> comprehensiveConnectionCheck() async {
    final List<String> testUrls = [
      'https://www.google.com/favicon.ico',
      'https://httpbin.org/status/200',
      'https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current_weather=true',
    ];

    int successCount = 0;
    
    for (String url in testUrls) {
      try {
        final response = await http.head(Uri.parse(url))
            .timeout(Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          successCount++;
        }
      } catch (e) {
        print('Failed to connect to $url: $e');
      }
    }

    // Jika minimal 1 dari 3 berhasil, anggap ada koneksi
    return successCount > 0;
  }
}