import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/connectivity_service.dart';
import '../utils/location_helper.dart';
import '../widgets/weather_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/no_internet_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Weather? weather;
  String? _locationName;
  Map<String, String>? locationDetails;
  bool isLoading = true;
  bool isRetrying = false;
  String? errorMessage;
  bool hasInternet = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Connectivity service
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupConnectivityListener();
    _connectivityService.startMonitoring();
    loadWeather();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _connectivityService.connectionStream.listen((bool isConnected) {
      setState(() {
        hasInternet = isConnected;
      });

      if (isConnected && weather == null) {
        // Jika koneksi kembali dan belum ada data, coba load lagi
        loadWeather();
      }
    });
  }

  void loadWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      hasInternet = true;
      _locationName = null;
    });

    try {
      print("Mulai mendapatkan lokasi..."); // Debug log

      // Untuk mobile, beri lebih banyak waktu
      final position = await LocationHelper.getCurrentLocation().timeout(
        Duration(seconds: kIsWeb ? 15 : 30),
      );

      print(
        "Lokasi didapat: ${position.latitude}, ${position.longitude}",
      ); // Debug log

      // Jalankan weather request dengan timeout yang lebih panjang untuk mobile
      print("Mengambil data cuaca...");
      final weatherData = await WeatherService()
          .fetchWeather(position.latitude, position.longitude)
          .timeout(Duration(seconds: kIsWeb ? 20 : 35));

      print(
        "Data cuaca berhasil didapat: ${weatherData?.temperature}°C",
      ); // Debug log

      // Location name bisa dilakukan paralel dan tidak critical
      String? locationResult;
      Map<String, String>? details;

      try {
        final locationResults = await Future.wait([
          LocationHelper.getLocationName(position.latitude, position.longitude),
          LocationHelper.getDetailedLocationInfo(
            position.latitude,
            position.longitude,
          ),
        ]).timeout(Duration(seconds: 10));

        locationResult = locationResults[0] as String;
        details = locationResults[1] as Map<String, String>;
      } catch (e) {
        print("Location name/details failed (non-critical): $e");
        locationResult = _getEstimatedLocation(
          position.latitude,
          position.longitude,
        );
        details = {
          'coordinates':
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          'estimatedLocation': locationResult,
        };
      }

      print("Nama lokasi: $locationResult"); // Debug log

      if (weatherData != null) {
        setState(() {
          weather = weatherData;
          _locationName = locationResult;
          locationDetails = details;
          isLoading = false;
        });

        // Trigger animations
        _fadeController.forward();
        _slideController.forward();
      } else {
        throw Exception("Data cuaca kosong");
      }
    } catch (e) {
      print("Error dalam loadWeather: $e"); // Debug log

      String errorMsg = e.toString().toLowerCase();
      String userFriendlyError;
      final lang = Provider.of<LanguageProvider>(context, listen: false);

      // Kategorisasi error untuk mobile
      if (errorMsg.contains("timeout") || errorMsg.contains("time limit")) {
        userFriendlyError = lang.translate('retry');
      } else if (errorMsg.contains("location_permission_denied_forever")) {
        userFriendlyError = lang.translate('location_denied_forever');
      } else if (errorMsg.contains("location_permission_denied")) {
        userFriendlyError = lang.translate('location_denied');
      } else if (errorMsg.contains("location_services_disabled")) {
        userFriendlyError = lang.translate('location_disabled');
      } else if (errorMsg.contains("location") && errorMsg.contains("denied")) {
        userFriendlyError = lang.translate('location_denied');
      } else if (errorMsg.contains("location") &&
          errorMsg.contains("disabled")) {
        userFriendlyError = lang.translate('location_disabled');
      } else if (errorMsg.contains("internet") ||
          errorMsg.contains("koneksi") ||
          errorMsg.contains("connection")) {
        setState(() {
          isLoading = false;
          hasInternet = false;
          errorMessage = null;
        });
        return;
      } else if (errorMsg.contains("socket") || errorMsg.contains("network")) {
        userFriendlyError = lang.translate('no_internet');
      } else {
        userFriendlyError = lang.translate('error_occurred');
      }

      if (!kIsWeb &&
          (errorMsg.contains("windows") || errorMsg.contains("win32"))) {
        userFriendlyError =
            "${lang.translate('location_denied')} ${lang.translate('windows_hint')}";
      }

      setState(() {
        isLoading = false;
        hasInternet = true;
        errorMessage = userFriendlyError;
        _locationName = null;
      });
    }
  }

  // Helper method untuk estimasi lokasi (sama seperti di LocationHelper)
  String _getEstimatedLocation(double lat, double lon) {
    // Yogyakarta dan DIY
    if (lat >= -8.2 && lat <= -7.5 && lon >= 110.0 && lon <= 110.8) {
      return "Yogyakarta, DIY, Indonesia";
    }
    // Jakarta dan sekitarnya
    else if (lat >= -6.5 && lat <= -5.8 && lon >= 106.5 && lon <= 107.2) {
      return "Jakarta, DKI Jakarta, Indonesia";
    }
    // Default Indonesia
    else if (lat >= -11.0 && lat <= 6.0 && lon >= 95.0 && lon <= 141.0) {
      return "Indonesia";
    } else {
      return "Koordinat: ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}";
    }
  }

  // Method untuk retry dengan loading state
  void retryConnection() async {
    setState(() {
      isRetrying = true;
    });

    // Delay untuk UX yang lebih baik
    await Future.delayed(Duration(seconds: 1));

    bool hasConnection = await _connectivityService.forceCheck();

    setState(() {
      isRetrying = false;
      hasInternet = hasConnection;
    });

    if (hasConnection) {
      loadWeather();
    }
  }

  // Method untuk refresh data dengan optimasi mobile
  void refreshWeather() async {
    _fadeController.reset();
    _slideController.reset();

    // Quick connectivity check untuk mobile
    if (!kIsWeb) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Quick check dulu
      try {
        final quickResult = await InternetAddress.lookup(
          '8.8.8.8',
        ).timeout(Duration(seconds: 2));
        if (quickResult.isEmpty) {
          setState(() {
            isLoading = false;
            hasInternet = false;
          });
          return;
        }
      } catch (e) {
        print("Quick connectivity check failed: $e");
        // Lanjut ke loadWeather, biar dia yang handle
      }
    }

    loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final String displayLocationName =
        _locationName ?? lang.translate('loading_location');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar dengan gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF667EEA),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  lang.translate('app_title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.help_outline_rounded, color: Colors.white),
              onPressed: () => _showHelpDialog(context, lang),
              tooltip: lang.translate('help'),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                tooltip: lang.translate('settings'),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: refreshWeather,
                tooltip: lang.translate('retry'),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height - 200,
                    child: LoadingIndicator(),
                  )
                : !hasInternet
                ? NoInternetWidget(
                    onRetry: retryConnection,
                    isRetrying: isRetrying,
                  )
                : errorMessage != null
                ? _buildErrorState(lang)
                : weather == null
                ? _buildNoDataState(lang)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: RefreshIndicator(
                        onRefresh: () async => refreshWeather(),
                        color: Color(0xFF667EEA),
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildLocationCard(displayLocationName, lang),
                                SizedBox(height: 24),
                                WeatherCard(weather: weather!),
                                SizedBox(height: 32),
                                _buildRefreshHint(lang),
                                SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String displayLocationName, LanguageProvider lang) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667EEA).withOpacity(0.1),
                  Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: Color(0xFF667EEA),
              size: isCompact ? 28 : 32,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            displayLocationName,
            style: TextStyle(
              fontSize: isCompact ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (locationDetails != null &&
              locationDetails!['coordinates'] != null)
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${locationDetails!['coordinates']}${kIsWeb ? ' (Web)' : ''}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (locationDetails != null)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 12 : 16),
              child: _buildLocationDetails(lang),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(LanguageProvider lang) {
    if (locationDetails == null) return SizedBox.shrink();

    List<Widget> details = [];

    // Tampilkan alamat jika ada
    if (locationDetails!['street']?.isNotEmpty == true) {
      details.add(
        _buildDetailChip(
          icon: Icons.map_rounded,
          text: locationDetails!['street']!,
          color: Color(0xFF10B981),
        ),
      );
    }

    // Tampilkan kode pos jika ada
    if (locationDetails!['postalCode']?.isNotEmpty == true) {
      details.add(
        _buildDetailChip(
          icon: Icons.local_post_office_rounded,
          text:
              "${lang.translate('language') == 'Bahasa' ? 'Kode Pos' : 'Postal Code'}: ${locationDetails!['postalCode']}",
          color: Color(0xFF3B82F6),
        ),
      );
    }

    // Jika tidak ada detail dari geocoding, tampilkan estimasi
    if (details.isEmpty &&
        locationDetails!['estimatedLocation']?.isNotEmpty == true) {
      details.add(
        _buildDetailChip(
          icon: Icons.explore_rounded,
          text:
              "${lang.translate('language') == 'Bahasa' ? 'Estimasi' : 'Estimated'}: ${locationDetails!['estimatedLocation']}",
          color: Color(0xFFF59E0B),
          isEstimated: true,
        ),
      );
    }

    if (details.isEmpty) return SizedBox.shrink();

    return Column(
      children: details
          .map(
            (detail) =>
                Padding(padding: EdgeInsets.only(top: 8), child: detail),
          )
          .toList(),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
    bool isEstimated = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageProvider lang) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 24),
          Text(
            lang.translate('error_occurred'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineLarge?.color ?? Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          if (errorMessage?.toLowerCase().contains("izin") == true ||
              errorMessage?.toLowerCase().contains("lokasi") == true ||
              errorMessage?.toLowerCase().contains("gps") == true)
            Column(
              children: [
                _buildModernButton(
                  onPressed: () => Geolocator.openLocationSettings(),
                  text: lang.translate('open_settings'),
                  icon: Icons.settings_rounded,
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: refreshWeather,
                  child: Text(lang.translate('retry')),
                ),
              ],
            )
          else
            _buildModernButton(
              onPressed: refreshWeather,
              text: lang.translate('retry'),
              icon: Icons.refresh_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(LanguageProvider lang) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 24),
          Text(
            lang.translate('weather_data_empty'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineLarge?.color ?? Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Text(
            lang.translate('weather_data_empty'), // Or more specific if needed
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          _buildModernButton(
            onPressed: refreshWeather,
            text: lang.translate('retry'),
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshHint(LanguageProvider lang) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF667EEA).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_down_rounded, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B)),
          SizedBox(width: 8),
          Text(
            lang.translate('refresh_hint'),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF667EEA)),
            SizedBox(width: 10),
            Text(lang.translate('help_title')),
          ],
        ),
        content: Text(
          lang.translate('help_content'),
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('close')),
          ),
        ],
      ),
    );
  }
}
