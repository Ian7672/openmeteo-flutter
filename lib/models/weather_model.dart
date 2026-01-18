class Weather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;

  Weather({required this.temperature, required this.windSpeed, required this.weatherCode});

factory Weather.fromJson(Map<String, dynamic> json) {
  final current = json['current_weather'];
  if (current == null) throw Exception("Data 'current_weather' kosong");

  return Weather(
    temperature: current['temperature'] ?? 0.0,
    windSpeed: current['windspeed'] ?? 0.0,
    weatherCode: current['weathercode'] ?? 0,
  );
}

}
