import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_model.dart';
import '../config/app_config.dart';

class WeatherController extends GetxController {
  var isLoading = false.obs;
  var weatherResult = Rxn<WeatherModel>();
  var lastRefresh = ''.obs;

  // Backend API URL — central config se aata hai (app_config.dart)
  String get baseUrl => AppConfig.baseUrl;

  Timer? _autoRefreshTimer;

  @override
  void onInit() {
    super.onInit();
    fetchWeather();
    // Auto-refresh every 30 seconds for live data
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchWeather(silent: true);
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchWeather({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$baseUrl/weather-advisory?lat=22.7196&lon=75.8577&t=$timeStamp'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        weatherResult.value = WeatherModel.fromJson(json.decode(response.body));
        lastRefresh.value = DateTime.now().toString().substring(11, 19);
      } else {
        print("Server returned error: ${response.statusCode}");
      }
    } catch (e) {
      print("Connection error in WeatherController: $e");
    } finally {
      if (!silent) isLoading.value = false;
    }
  }
}