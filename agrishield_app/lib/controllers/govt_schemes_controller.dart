import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class GovtSchemesController extends GetxController {
  var isLoading = true.obs;
  var schemes = <Map<String, dynamic>>[].obs;
  var filteredSchemes = <Map<String, dynamic>>[].obs;

  // Backend API URL — central config se aata hai (app_config.dart)
  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    fetchSchemes();
  }

  Future<void> fetchSchemes() async {
    isLoading(true);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/govt-schemes'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final List items = data['data'] ?? [];
          schemes.assignAll(List<Map<String, dynamic>>.from(items));
          filteredSchemes.assignAll(schemes);
        }
      }
    } catch (e) {
      print('[GovtSchemes] Error: $e');
    } finally {
      isLoading(false);
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredSchemes.assignAll(schemes);
    } else {
      filteredSchemes.assignAll(schemes.where((s) =>
          (s['title'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
          (s['description'] ?? '').toString().toLowerCase().contains(query.toLowerCase())).toList());
    }
  }
}
