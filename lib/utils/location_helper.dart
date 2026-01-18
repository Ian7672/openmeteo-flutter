import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationHelper {
  static Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kIsWeb) {
          print(
            "Location services not available on web, using default location",
          );
          return _getDefaultPosition();
        } else {
          throw Exception("LOCATION_SERVICES_DISABLED");
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (kIsWeb) {
          print(
            "Location permission denied permanently on web, using default location",
          );
          return _getDefaultPosition();
        } else {
          throw Exception("LOCATION_PERMISSION_DENIED_FOREVER");
        }
      }

      if (permission == LocationPermission.denied) {
        if (kIsWeb) {
          print("Location permission denied on web, using default location");
          return _getDefaultPosition();
        } else {
          throw Exception("LOCATION_PERMISSION_DENIED");
        }
      }

      // Settings berbeda untuk mobile dan web
      final LocationSettings locationSettings = kIsWeb
          ? LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 100,
            )
          : LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
        timeLimit: Duration(
          seconds: kIsWeb ? 15 : 20,
        ), // Timeout lebih lama untuk mobile
      );
    } catch (e) {
      print("Error getting location: $e");
      if (kIsWeb ||
          e.toString().contains("LOCATION_SERVICES_DISABLED") ||
          e.toString().contains("LOCATION_PERMISSION_DENIED") ||
          e.toString().contains("LOCATION_PERMISSION_DENIED_FOREVER")) {
        // Jangan retry jika permission ditolak atau service mati, atau di web
        if (kIsWeb) {
          print("Using default location for web");
          return _getDefaultPosition();
        }
        rethrow;
      } else {
        // Untuk mobile, coba sekali lagi dengan accuracy yang lebih rendah untuk error teknis
        try {
          print("Retrying with lower accuracy...");
          return await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 50,
            ),
            timeLimit: Duration(seconds: 25),
          );
        } catch (e2) {
          print("Second attempt failed: $e2");
          rethrow;
        }
      }
    }
  }

  static Position _getDefaultPosition() {
    return Position(
      longitude: 106.8456,
      latitude: -6.2088,
      timestamp: DateTime.now(),
      accuracy: 100.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  static Future<String> getLocationName(double lat, double lon) async {
    try {
      print("Mencoba reverse geocoding untuk: $lat, $lon"); // Debug log

      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: "id_ID", // Set locale ke Indonesia
      );

      print("Jumlah placemark ditemukan: ${placemarks.length}"); // Debug log

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Debug: Print semua data placemark
        print("Placemark data: ${place.toString()}");
        print("locality: ${place.locality}");
        print("subLocality: ${place.subLocality}");
        print("subAdministrativeArea: ${place.subAdministrativeArea}");
        print("administrativeArea: ${place.administrativeArea}");
        print("country: ${place.country}");

        // Prioritas nama lokasi dengan fallback yang lebih baik
        String city =
            place.locality ??
            place.subLocality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            "";

        String province = place.administrativeArea ?? "";
        String country = place.country ?? "Indonesia";

        // Format nama lokasi yang lebih informatif
        if (city.isNotEmpty) {
          // Format: "Jakarta, DKI Jakarta, Indonesia"
          if (province.isNotEmpty && province != city) {
            return "$city, $province, $country";
          } else {
            return "$city, $country";
          }
        } else if (province.isNotEmpty) {
          // Jika hanya provinsi yang tersedia
          return "$province, $country";
        } else {
          // Fallback dengan perkiraan lokasi berdasarkan wilayah Indonesia
          String estimatedLocation = _getEstimatedLocation(lat, lon);
          return "$estimatedLocation (Perkiraan)";
        }
      }

      // Fallback jika tidak ada placemark
      String estimatedLocation = _getEstimatedLocation(lat, lon);
      return "$estimatedLocation (Perkiraan dari koordinat: ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";
    } catch (e) {
      print("Error getting location name: $e");
      // Fallback dengan perkiraan lokasi dan koordinat
      String estimatedLocation = _getEstimatedLocation(lat, lon);
      return "$estimatedLocation (Perkiraan dari koordinat: ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";
    }
  }

  // Method untuk memperkirakan lokasi berdasarkan koordinat
  static String _getEstimatedLocation(double lat, double lon) {
    // Wilayah Indonesia berdasarkan koordinat (perkiraan kasar)

    // Jakarta dan sekitarnya
    if (lat >= -6.5 && lat <= -5.8 && lon >= 106.5 && lon <= 107.2) {
      return "Jakarta, DKI Jakarta, Indonesia";
    }
    // Surabaya dan Jawa Timur
    else if (lat >= -8.0 && lat <= -7.0 && lon >= 112.0 && lon <= 113.0) {
      return "Surabaya, Jawa Timur, Indonesia";
    }
    // Bandung dan Jawa Barat
    else if (lat >= -7.2 && lat <= -6.7 && lon >= 107.3 && lon <= 108.0) {
      return "Bandung, Jawa Barat, Indonesia";
    }
    // Yogyakarta dan DIY
    else if (lat >= -8.2 && lat <= -7.5 && lon >= 110.0 && lon <= 110.8) {
      return "Yogyakarta, DIY, Indonesia";
    }
    // Semarang dan Jawa Tengah
    else if (lat >= -7.5 && lat <= -6.5 && lon >= 109.5 && lon <= 111.0) {
      return "Semarang, Jawa Tengah, Indonesia";
    }
    // Medan dan Sumatera Utara
    else if (lat >= 3.0 && lat <= 4.0 && lon >= 98.0 && lon <= 99.0) {
      return "Medan, Sumatera Utara, Indonesia";
    }
    // Makassar dan Sulawesi Selatan
    else if (lat >= -5.5 && lat <= -4.8 && lon >= 119.0 && lon <= 120.0) {
      return "Makassar, Sulawesi Selatan, Indonesia";
    }
    // Denpasar dan Bali
    else if (lat >= -8.8 && lat <= -8.3 && lon >= 115.0 && lon <= 115.5) {
      return "Denpasar, Bali, Indonesia";
    }
    // Palembang dan Sumatera Selatan
    else if (lat >= -3.2 && lat <= -2.5 && lon >= 104.0 && lon <= 105.0) {
      return "Palembang, Sumatera Selatan, Indonesia";
    }
    // Batam dan Kepulauan Riau
    else if (lat >= 0.8 && lat <= 1.5 && lon >= 103.8 && lon <= 104.5) {
      return "Batam, Kepulauan Riau, Indonesia";
    }
    // Wilayah Jawa (umum)
    else if (lat >= -8.5 && lat <= -5.5 && lon >= 105.0 && lon <= 115.0) {
      return "Jawa, Indonesia";
    }
    // Wilayah Sumatera (umum)
    else if (lat >= -6.0 && lat <= 6.0 && lon >= 95.0 && lon <= 106.0) {
      return "Sumatera, Indonesia";
    }
    // Wilayah Kalimantan (umum)
    else if (lat >= -4.5 && lat <= 4.5 && lon >= 108.0 && lon <= 119.0) {
      return "Kalimantan, Indonesia";
    }
    // Wilayah Sulawesi (umum)
    else if (lat >= -6.0 && lat <= 2.0 && lon >= 118.0 && lon <= 125.0) {
      return "Sulawesi, Indonesia";
    }
    // Wilayah Papua (umum)
    else if (lat >= -9.0 && lat <= -2.0 && lon >= 130.0 && lon <= 141.0) {
      return "Papua, Indonesia";
    }
    // Wilayah Maluku
    else if (lat >= -8.5 && lat <= -2.0 && lon >= 125.0 && lon <= 135.0) {
      return "Maluku, Indonesia";
    }
    // Nusa Tenggara
    else if (lat >= -10.5 && lat <= -8.0 && lon >= 115.0 && lon <= 125.0) {
      return "Nusa Tenggara, Indonesia";
    }
    // Default untuk koordinat dalam wilayah Indonesia
    else if (lat >= -11.0 && lat <= 6.0 && lon >= 95.0 && lon <= 141.0) {
      return "Indonesia";
    }
    // Jika di luar Indonesia
    else {
      return "Lokasi di luar Indonesia";
    }
  }

  // Method tambahan untuk mendapatkan lokasi sederhana
  static Future<String> getSimpleLocationName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Ambil nama yang paling spesifik
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          return place.subLocality!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          return place.subAdministrativeArea!;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea!;
        }
      }

      // Fallback dengan estimasi lokasi
      return _getEstimatedLocation(
        lat,
        lon,
      ).split(',')[0]; // Ambil nama kota saja
    } catch (e) {
      return _getEstimatedLocation(
        lat,
        lon,
      ).split(',')[0]; // Ambil nama kota saja
    }
  }

  // Method untuk mendapatkan informasi lokasi lengkap dengan detail
  static Future<Map<String, String>> getDetailedLocationInfo(
    double lat,
    double lon,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        return {
          'street': place.street ?? '',
          'subLocality': place.subLocality ?? '',
          'locality': place.locality ?? '',
          'subAdministrativeArea': place.subAdministrativeArea ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? 'Indonesia',
          'postalCode': place.postalCode ?? '',
          'coordinates': '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
          'estimatedLocation': _getEstimatedLocation(lat, lon),
        };
      }

      return {
        'street': '',
        'subLocality': '',
        'locality': '',
        'subAdministrativeArea': '',
        'administrativeArea': '',
        'country': 'Indonesia',
        'postalCode': '',
        'coordinates': '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
        'estimatedLocation': _getEstimatedLocation(lat, lon),
      };
    } catch (e) {
      print("Error getting detailed location info: $e");
      return {
        'street': '',
        'subLocality': '',
        'locality': '',
        'subAdministrativeArea': '',
        'administrativeArea': '',
        'country': 'Indonesia',
        'postalCode': '',
        'coordinates': '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
        'estimatedLocation': _getEstimatedLocation(lat, lon),
      };
    }
  }
}
