import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'language_controller.dart';

class RecoveryController extends GetxController {
  var isLoading = false.obs;
  var hasData = false.obs;
  var damagePercent = 0.obs;
  var healthScore = 0.obs;
  var cropName = ''.obs;
  var disease = ''.obs;

  // Recovery Plan Data
  var damageLevel = ''.obs;
  var pivotTitle = ''.obs;
  var pivotDescription = ''.obs;
  var alternatives = <Map<String, dynamic>>[].obs;
  var lossWithoutPivot = 0.obs;
  var projectedProfit = 0.obs;
  var recoveryDays = 0.obs;
  var immediateSteps = <String>[].obs;
  var govtSchemes = <String>[].obs;

  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    _loadLastScanAndCheck();
  }

  /// Load last scan data and check if recovery is needed
  Future<void> _loadLastScanAndCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/last-scan'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final scan = data['data'];
          healthScore.value = (scan['health_score'] ?? 0) is int
              ? scan['health_score']
              : int.tryParse(scan['health_score'].toString()) ?? 0;
          damagePercent.value = (100 - healthScore.value).clamp(0, 100);
          cropName.value = scan['crop_name']?.toString() ?? 'Unknown';
          disease.value = scan['disease']?.toString() ?? 'No disease';

          // Auto-fetch recovery advice if damage > 50%
          if (damagePercent.value > 50) {
            await fetchRecoveryAdvice();
          }
        }
      }
    } catch (e) {
      print('[Recovery] Load scan error: $e');
    }
  }

  /// Fetch AI-powered recovery advice
  Future<void> fetchRecoveryAdvice() async {
    isLoading(true);
    try {
      final lang = LanguageController.currentLang;
      final response = await http
          .post(
            Uri.parse('$baseUrl/recovery-advice'),
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
            body: json.encode({
              'health_score': healthScore.value,
              'damage_percent': damagePercent.value,
              'crop_name': cropName.value,
              'disease': disease.value,
              'language': lang,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final d = data['data'];
          damageLevel.value = d['damage_level']?.toString() ?? 'Severe';
          pivotTitle.value = d['pivot_title']?.toString() ?? '';
          pivotDescription.value = d['pivot_description']?.toString() ?? '';
          lossWithoutPivot.value = _parseInt(d['loss_without_pivot']);
          projectedProfit.value = _parseInt(d['projected_profit_with_pivot']);
          recoveryDays.value = _parseInt(d['recovery_timeline_days']);

          if (d['alternative_options'] is List) {
            alternatives.value = List<Map<String, dynamic>>.from(
              (d['alternative_options'] as List)
                  .map((a) => Map<String, dynamic>.from(a)),
            );
          }

          if (d['immediate_steps'] is List) {
            immediateSteps.value =
                List<String>.from((d['immediate_steps'] as List).map((s) => s.toString()));
          }

          if (d['government_schemes'] is List) {
            govtSchemes.value =
                List<String>.from((d['government_schemes'] as List).map((s) => s.toString()));
          }

          hasData(true);
        }
      }
    } catch (e) {
      print('[Recovery] Advice error: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Force refresh with custom damage data
  Future<void> refreshWithData(int health, String crop, String dis) async {
    healthScore.value = health;
    damagePercent.value = (100 - health).clamp(0, 100);
    cropName.value = crop;
    disease.value = dis;
    await fetchRecoveryAdvice();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
