import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/language_provider.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({required this.weather});

  String getWeatherDescription(int code, LanguageProvider lang) {
    // Berdasarkan kode cuaca dari API Open-Meteo
    switch (code) {
      case 0:
        return lang.translate('sunny');
      case 1:
      case 2:
      case 3:
        return lang.translate('cloudy');
      case 45:
      case 48:
        return lang.translate('foggy');
      case 51:
      case 53:
      case 55:
        return lang.translate('drizzle');
      case 56:
      case 57:
        return lang.translate('freezing_drizzle');
      case 61:
      case 63:
      case 65:
        return lang.translate('rain');
      case 66:
      case 67:
        return lang.translate('freezing_rain');
      case 71:
      case 73:
      case 75:
        return lang.translate('snow');
      case 77:
        return lang.translate('snow_grains');
      case 80:
      case 81:
      case 82:
        return lang.translate('heavy_rain');
      case 85:
      case 86:
        return lang.translate('snow_showers');
      case 95:
      case 96:
      case 99:
        return lang.translate('thunderstorm');
      default:
        return lang.translate('unknown');
    }
  }

  IconData getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 80:
      case 81:
      case 82:
        return Icons.thunderstorm_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.flash_on_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color getWeatherColor(int code) {
    switch (code) {
      case 0:
        return Color(0xFFF59E0B); // Sunny yellow
      case 1:
      case 2:
      case 3:
        return Color(0xFF6B7280); // Cloudy gray
      case 45:
      case 48:
        return Color(0xFF9CA3AF); // Foggy light gray
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Color(0xFF3B82F6); // Drizzle blue
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Color(0xFF1D4ED8); // Rain blue
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Color(0xFF60A5FA); // Snow light blue
      case 95:
      case 96:
      case 99:
        return Color(0xFF7C3AED); // Thunder purple
      default:
        return Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final weatherColor = getWeatherColor(weather.weatherCode);
    final weatherIcon = getWeatherIcon(weather.weatherCode);
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust sizes based on screen height
    final isCompact = screenHeight < 700;
    final iconSize = isCompact ? 40.0 : 48.0;
    final tempFontSize = isCompact ? 60.0 : 72.0;
    final cardPadding = isCompact ? 24.0 : 32.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            weatherColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: weatherColor.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // Weather Icon dan Description
            Container(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    weatherColor.withOpacity(0.1),
                    weatherColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(weatherIcon, size: iconSize, color: weatherColor),
            ),

            SizedBox(height: isCompact ? 16 : 20),

            Text(
              getWeatherDescription(weather.weatherCode, lang),
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: isCompact ? 24 : 32),

            // Main Temperature - More compact
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${weather.temperature.toInt()}",
                  style: TextStyle(
                    fontSize: tempFontSize,
                    fontWeight: FontWeight.w200,
                    color: Theme.of(context).textTheme.displayLarge?.color ?? Color(0xFF1E293B),
                    height: 0.9,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: isCompact ? 6 : 8),
                  child: Text(
                    "°C",
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 24,
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isCompact ? 24 : 32),

            // Wind Speed Info - More compact
            Container(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.air_rounded,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('wind_speed'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${weather.windSpeed} km/h",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: isCompact ? 16 : 24),

            // Additional Info Card - More compact
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    weatherColor.withOpacity(0.1),
                    weatherColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: weatherColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: weatherColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    lang.translate('latest_data'),
                    style: TextStyle(
                      fontSize: 11,
                      color: weatherColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
