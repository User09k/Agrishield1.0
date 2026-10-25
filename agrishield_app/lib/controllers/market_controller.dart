import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/market_model.dart';
import '../config/app_config.dart';

class MarketController extends GetxController {
  var isLoading = true.obs;
  var allPrices = <MarketModel>[].obs;
  var priceList = <MarketModel>[].obs;
  
  final box = GetStorage();

  // Backend API URL — central config se aata hai (app_config.dart)
  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    loadOfflineData();
    fetchPrices();
  }

  void loadOfflineData() {
    var storedData = box.read('mandi_cache');
    if (storedData != null) {
      var list = (storedData as List).map((e) => MarketModel.fromJson(e)).toList();
      allPrices.assignAll(list);
      priceList.assignAll(list);
    }
  }

  Future<void> fetchPrices() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('$baseUrl/mandi-prices'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var data = json.decode(response.body) as List;
        var fetchedList = data.map((item) => MarketModel.fromJson(item)).toList();
        
        allPrices.assignAll(fetchedList);
        priceList.assignAll(fetchedList);
        box.write('mandi_cache', fetchedList.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      print("Connection Error: $e");
    } finally {
      isLoading(false);
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      priceList.assignAll(allPrices);
    } else {
      priceList.assignAll(allPrices.where((item) =>
          item.cropName.toLowerCase().contains(query.toLowerCase()) ||
          item.marketName.toLowerCase().contains(query.toLowerCase())).toList());
    }
  }
}