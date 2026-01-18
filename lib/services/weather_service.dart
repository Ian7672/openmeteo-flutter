import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/connectivity_service.dart';

class WeatherService {
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<Weather?> fetchWeather(double lat, double lon) async {
    // Check internet connection first - lebih permisif untuk mobile
    if (!kIsWeb) {
      // Untuk mobile, lakukan quick check dulu
      try {
        final quickCheck = await InternetAddress.lookup('8.8.8.8')
            .timeout(Duration(seconds: 2));
        if (quickCheck.isEmpty) {
          throw Exception("Tidak ada koneksi internet");
        }
      } catch (e) {
        // Jika quick check gagal, coba comprehensive check
        bool hasInternet = await _connectivityService.comprehensiveConnectionCheck();
        if (!hasInternet) {
          throw Exception("Tidak ada koneksi internet");
        }
      }
    } else {
      // Untuk web, gunakan method biasa
      bool hasInternet = await _connectivityService.forceCheck();
      if (!hasInternet) {
        throw Exception("Tidak ada koneksi internet");
      }
    }

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );
    print('API URL: $url'); // Debug URL

    try {
      // Timeout yang berbeda untuk mobile dan web
      final timeoutDuration = kIsWeb ? Duration(seconds: 15) : Duration(seconds: 20);
      
      final response = await http.get(url).timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException("Request timeout", timeoutDuration);
        },
      );

      print('Status: ${response.statusCode}');
      print('Body length: ${response.body.length}'); // Don't print full body

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Weather.fromJson(jsonData);
        } catch (e) {
          print('JSON parsing error: $e');
          throw FormatException("Invalid response format");
        }
      } else if (response.statusCode == 429) {
        throw HttpException("Too many requests. Please try again later.");
      } else if (response.statusCode >= 500) {
        throw HttpException("Server error. Please try again later.");
      } else {
        throw HttpException("HTTP ${response.statusCode}: ${response.reasonPhrase}");
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception("Masalah koneksi jaringan");
    } on TimeoutException catch (e) {
      print('Timeout exception: $e');
      throw Exception("Koneksi lambat, mohon coba lagi");
    } on HttpException catch (e) {
      print('HTTP exception: $e');
      if (e.message.contains("Server error")) {
        throw Exception("Server cuaca sedang bermasalah");
      } else {
        throw Exception("Masalah server: ${e.message}");
      }
    } on FormatException catch (e) {
      print('Format exception: $e');
      throw Exception("Data cuaca tidak valid");
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception("Gagal mengambil data cuaca");
    }
  }

  // Method untuk test koneksi ke API weather
  Future<bool> testConnection() async {
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
}

// Custom exceptions untuk error handling yang lebih baik
class WeatherServiceException implements Exception {
  final String message;
  final String? details;
  
  WeatherServiceException(this.message, {this.details});
  
  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}

class NoInternetException extends WeatherServiceException {
  NoInternetException() : super("Tidak ada koneksi internet");
}

class ServerException extends WeatherServiceException {
  ServerException(String message) : super("Server error", details: message);
}

class TimeoutException extends WeatherServiceException {
  final Duration? duration;
  
  TimeoutException(String message, this.duration) : super("Timeout", details: message);
}