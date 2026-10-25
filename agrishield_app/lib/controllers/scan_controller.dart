import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/scan_model.dart';
import '../services/firestore_service.dart';
import '../config/app_config.dart';
import '../insurance/insurance_service.dart';
import '../controllers/weather_controller.dart';
import 'blockchain_controller.dart';
import 'language_controller.dart';

class ScanController extends GetxController {
  var isLoading = false.obs;
  var result = Rxn<ScanModel>();
  var selectedImage = Rxn<File>();

  // Insurance eligibility
  var insuranceEligible = false.obs;
  var eligibilityReason = ''.obs;
  var eligibilityReasonEn = ''.obs;
  var eligibilityData = Rxn<Map<String, dynamic>>();

  // Scan history for multiple views
  var scanHistory = <ScanModel>[].obs;
  var currentScanIndex = 0.obs;

  final ImagePicker _picker = ImagePicker();
  final InsuranceService _insuranceService = InsuranceService();

  // Backend API URL — central config se aata hai (app_config.dart)
  String get baseUrl => AppConfig.baseUrl;

  /// Pick image from Camera
  Future<void> scanFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      selectedImage.value = File(image.path);
      await _analyzeImage(image.path);
    }
  }

  /// Pick image from Gallery
  Future<void> scanFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      selectedImage.value = File(image.path);
      await _analyzeImage(image.path);
    }
  }

  /// Send image to backend for AI analysis
  Future<void> _analyzeImage(String imagePath) async {
    isLoading(true);
    try {
      final lang = LanguageController.currentLang;
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      request.headers['Accept-Language'] = lang;
      request.headers['X-App-Language'] = lang;
      request.fields['language'] = lang;
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      var response = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Analysis timeout - please try again');
        },
      );

      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['status'] == 'Success') {
        var d = jsonResponse['data'];
        result.value = ScanModel.fromJson(d);

        // Add to scan history
        scanHistory.insert(0, result.value!);
        currentScanIndex.value = 0;

        // 🔥 Save to Firestore
        FirestoreService.saveCropScan(result.value!.toJson());

        // ✅ Check insurance eligibility
        _checkEligibility();
      } else {
        Get.snackbar(
          "Analysis Failed",
          jsonResponse['error']?.toString() ?? "Unknown error occurred",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Connection Error",
        "Cannot reach AgriShield server. Make sure backend is running.",
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Error: $e");
    } finally {
      isLoading(false);
    }
  }

  /// Check insurance eligibility using crop analysis + weather cross-check
  void _checkEligibility() {
    if (result.value == null) return;

    // Get weather data if available
    String weatherCondition = 'unknown';
    String diseaseRisk = 'unknown';
    try {
      final weatherCtrl = Get.find<WeatherController>();
      if (weatherCtrl.weatherResult.value != null) {
        weatherCondition = weatherCtrl.weatherResult.value!.condition;
        diseaseRisk = weatherCtrl.weatherResult.value!.cropImpact.diseaseRisk;
      }
    } catch (_) {
      // WeatherController not initialized yet — check without weather
    }

    final eligibility = _insuranceService.checkInsuranceEligibility(
      healthScore: result.value!.healthScore,
      disease: result.value!.disease,
      weatherCondition: weatherCondition,
      diseaseRisk: diseaseRisk,
    );

    insuranceEligible.value = eligibility['eligible'] ?? false;
    eligibilityReason.value = eligibility['reason'] ?? '';
    eligibilityReasonEn.value = eligibility['reason_en'] ?? '';
    eligibilityData.value = eligibility;
  }

  /// View a previous scan from history
  void viewScan(int index) {
    if (index >= 0 && index < scanHistory.length) {
      currentScanIndex.value = index;
      result.value = scanHistory[index];
      _checkEligibility();
    }
  }

  /// File Government Relief Claim (Sarkari Rahat)
  void fileGovtClaim() {
    if (result.value == null) return;
    if (!insuranceEligible.value) {
      Get.snackbar(
        '❌ Insurance Not Eligible',
        eligibilityReason.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 4),
      );
      return;
    }
    final bc = Get.put(BlockchainController());
    bc.processClaim(
      scanResult: result.value!,
      claimType: 'government',
    );
  }

  /// File Private Insurance Claim
  void filePrivateClaim() {
    if (result.value == null) return;
    if (!insuranceEligible.value) {
      Get.snackbar(
        '❌ Insurance Not Eligible',
        eligibilityReason.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 4),
      );
      return;
    }
    final bc = Get.put(BlockchainController());
    bc.processClaim(
      scanResult: result.value!,
      claimType: 'private',
    );
  }

  /// Show image source picker dialog
  void showImagePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              (Get.isRegistered<LanguageController>() && Get.find<LanguageController>().isHindi)
                  ? "फसल स्कैन करें"
                  : "Analyze Your Crop",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              (Get.isRegistered<LanguageController>() && Get.find<LanguageController>().isHindi)
                  ? "रोग पहचान हेतु कैमरा या गैलरी से फोटो चुनें"
                  : "Choose how to capture your crop image",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt,
                  label: (Get.isRegistered<LanguageController>() && Get.find<LanguageController>().isHindi)
                      ? "कैमरा"
                      : "Camera",
                  color: Colors.green,
                  onTap: () {
                    Get.back();
                    scanFromCamera();
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library,
                  label: (Get.isRegistered<LanguageController>() && Get.find<LanguageController>().isHindi)
                      ? "गैलरी"
                      : "Gallery",
                  color: Colors.blue,
                  onTap: () {
                    Get.back();
                    scanFromGallery();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}