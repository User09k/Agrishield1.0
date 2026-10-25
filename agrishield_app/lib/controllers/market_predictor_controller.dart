import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'language_controller.dart';

class MarketPredictorController extends GetxController {
  var isLoading = false.obs;
  var predictions = <Map<String, dynamic>>[].obs;

  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    fetchPredictions();
  }

  Future<void> fetchPredictions() async {
    isLoading(true);
    try {
      final lang = LanguageController.currentLang;
      final response = await http
          .get(
            Uri.parse('$baseUrl/market-predictions?lang=$lang'),
            headers: {
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success' && data['data'] is List) {
          predictions.value = List<Map<String, dynamic>>.from(
            (data['data'] as List)
                .map((a) => Map<String, dynamic>.from(a)),
          );
        }
      }
    } catch (e) {
      print('[MarketPredictor] Error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Sort by demand score
  void sortByDemand() {
    predictions.sort((a, b) =>
        (b['demand_score'] ?? 0).compareTo(a['demand_score'] ?? 0));
    predictions.refresh();
  }

  /// Sort by price growth
  void sortByGrowth() {
    predictions.sort((a, b) =>
        (b['price_growth_percent'] ?? 0)
            .compareTo(a['price_growth_percent'] ?? 0));
    predictions.refresh();
  }
}
