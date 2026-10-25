import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'language_controller.dart';

class RoiController extends GetxController {
  var isLoading = false.obs;
  var hasData = false.obs;

  // Slider values
  var investmentAmount = 50000.0.obs;
  var landSize = 5.0.obs;
  var cropName = 'General'.obs;

  // ROI Results
  var roiBreakdown = <Map<String, dynamic>>[].obs;
  var totalExpectedReturn = 0.obs;
  var totalRoiPercent = 0.obs;
  var paybackMonths = 0.obs;
  var riskLevel = ''.obs;
  var tips = <String>[].obs;

  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    // Load crop name from last scan if available
    _loadCropName();
  }

  Future<void> _loadCropName() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/last-scan'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          cropName.value = data['data']['crop_name']?.toString() ?? 'General';
        }
      }
    } catch (_) {}
    // Auto-calculate on init
    await calculateRoi();
  }

  /// Calculate ROI via backend
  Future<void> calculateRoi() async {
    isLoading(true);
    try {
      final lang = LanguageController.currentLang;
      final response = await http
          .post(
            Uri.parse('$baseUrl/roi-calculate'),
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
            body: json.encode({
              'investment_amount': investmentAmount.value.toInt(),
              'land_size': landSize.value,
              'crop_name': cropName.value,
              'language': lang,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final d = data['data'];

          if (d['roi_breakdown'] is List) {
            roiBreakdown.value = List<Map<String, dynamic>>.from(
              (d['roi_breakdown'] as List)
                  .map((a) => Map<String, dynamic>.from(a)),
            );
          }

          totalExpectedReturn.value = _parseInt(d['total_expected_return']);
          totalRoiPercent.value = _parseInt(d['total_roi_percent']);
          paybackMonths.value = _parseInt(d['payback_period_months']);
          riskLevel.value = d['risk_level']?.toString() ?? 'Medium';

          if (d['tips'] is List) {
            tips.value = List<String>.from(
                (d['tips'] as List).map((s) => s.toString()));
          }

          hasData(true);
        }
      }
    } catch (e) {
      print('[ROI] Calculate error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Update investment and recalculate
  void updateInvestment(double value) {
    investmentAmount.value = value;
  }

  /// Update land size and recalculate
  void updateLandSize(double value) {
    landSize.value = value;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
