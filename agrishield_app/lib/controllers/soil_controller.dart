import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/soil_model.dart';
import '../services/firestore_service.dart';
import '../config/app_config.dart';
import 'language_controller.dart';

class SoilController extends GetxController {
  var isLoading = false.obs;
  var lastSoilDocId = Rxn<String>(); // Track Firestore doc ID for linking
  var loadingMsg = ''.obs;
  var soilResult = Rxn<SoilModel>();
  var plantRecommendations = <PlantRecommendation>[].obs;
  var cropRecommendations = <CropRecommendation>[].obs;
  var selectedImage = Rxn<File>();
  var analysisType = Rxn<String>(); // 'plant' or 'crop'
  var fieldImages = <File>[].obs;
  var showFieldCapture = false.obs;
  var showSeasonSelection = false.obs;
  var selectedSeason = Rxn<String>(); // 'winter', 'summer', 'rainy'
  var expandedPlantIdx = (-1).obs;
  var expandedCropIdx = (-1).obs;

  final ImagePicker _picker = ImagePicker();

  // Backend API URL — central config se aata hai (app_config.dart)
  String get baseUrl => AppConfig.baseUrl;

  // ==========================================
  // STEP 1: Capture soil photo
  // ==========================================
  Future<void> scanFromCamera() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      selectedImage.value = File(image.path);
      await _analyzeSoilImage(image.path);
    }
  }

  Future<void> scanFromGallery() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      selectedImage.value = File(image.path);
      await _analyzeSoilImage(image.path);
    }
  }

  Future<void> _analyzeSoilImage(String imagePath) async {
    isLoading(true);
    loadingMsg.value = 'Analyzing soil image...';
    try {
      final lang = LanguageController.currentLang;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-soil'),
      );
      request.headers['Accept-Language'] = lang;
      request.headers['X-App-Language'] = lang;
      request.fields['language'] = lang;
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      final streamed = await request.send().timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw Exception('Timeout — try again'),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'Success') {
          soilResult.value = SoilModel.fromJson(json['data']);

          // 🔥 Save to Firestore (non-blocking — don't let Firestore errors block UI)
          FirestoreService.saveSoilAnalysis(
            soilResult.value!.toJson(),
          ).then((docId) {
            lastSoilDocId.value = docId;
          }).catchError((e) {
            print("[SoilController] Firestore save error (non-blocking): $e");
          });
        } else {
          _err('Analysis Failed', json['error'] ?? 'Could not analyze');
        }
      } else {
        _err('Server Error', 'Status: ${response.statusCode}');
      }
    } catch (e) {
      _err('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  // ==========================================
  // STEP 2A: Plant Recommendations
  // ==========================================
  Future<void> getPlantRecommendations() async {
    if (soilResult.value == null) return;
    isLoading(true);
    analysisType.value = 'plant';
    loadingMsg.value = 'Finding best plants for your soil...';

    try {
      final lang = LanguageController.currentLang;
      final payload = {
        ...soilResult.value!.toJson(),
        'language': lang,
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/soil-plant-recommendations'),
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 180),
              onTimeout: () => throw Exception('Timeout'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'Success') {
          final List<dynamic> data = json['data'];
          plantRecommendations.value =
              data.map((e) => PlantRecommendation.fromJson(e)).toList();

          // 🔥 Save to Firestore
          FirestoreService.saveRecommendations(
            type: 'plant',
            items: plantRecommendations.map((e) => e.toJson()).toList(),
            soilDocId: lastSoilDocId.value,
            soilType: soilResult.value?.soilType,
          );
        } else {
          _err('Error', json['error'] ?? 'Failed');
        }
      } else {
        _err('Server Error', 'Status: ${response.statusCode}');
      }
    } catch (e) {
      _err('Error', 'Plant recommendations failed: $e');
    } finally {
      isLoading(false);
    }
  }

  // ==========================================
  // STEP 2B: Crop Analysis (Multi-photo)
  // ==========================================
  void startCropFlow() {
    analysisType.value = 'crop';
    showSeasonSelection.value = true;
    showFieldCapture.value = false;
    fieldImages.clear();
  }

  void selectSeason(String season) {
    selectedSeason.value = season;
    showSeasonSelection.value = false;
    showFieldCapture.value = true;
  }

  Future<void> addFieldFromCamera() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) fieldImages.add(File(image.path));
  }

  Future<void> addFieldFromGallery() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) fieldImages.add(File(image.path));
  }

  void removeFieldImage(int index) => fieldImages.removeAt(index);

  Future<void> analyzeCropWithFieldPhotos() async {
    if (soilResult.value == null) return;
    if (fieldImages.length < 3) {
      _err('Photos Required', 'At least 3 field photos are needed');
      return;
    }

    isLoading(true);
    showFieldCapture.value = false;
    loadingMsg.value = 'Analyzing crops with ${fieldImages.length} photos...';

    try {
      final lang = LanguageController.currentLang;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/soil-crop-recommendations'),
      );
      request.headers['Accept-Language'] = lang;
      request.headers['X-App-Language'] = lang;
      request.fields['language'] = lang;
      request.fields['soil_data'] = jsonEncode(soilResult.value!.toJson());
      if (selectedSeason.value != null) {
        request.fields['season'] = selectedSeason.value!;
      }

      for (int i = 0; i < fieldImages.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'field_images', fieldImages[i].path),
        );
      }

      final streamed = await request.send().timeout(
            const Duration(seconds: 180),
            onTimeout: () => throw Exception('Timeout'),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'Success') {
          final List<dynamic> data = json['data'];
          cropRecommendations.value =
              data.map((e) => CropRecommendation.fromJson(e)).toList();

          // 🔥 Save to Firestore
          FirestoreService.saveRecommendations(
            type: 'crop',
            items: cropRecommendations.map((e) => e.toJson()).toList(),
            soilDocId: lastSoilDocId.value,
            soilType: soilResult.value?.soilType,
            season: selectedSeason.value,
          );
        } else {
          _err('Error', json['error'] ?? 'Failed');
        }
      } else {
        _err('Server Error', 'Status: ${response.statusCode}');
      }
    } catch (e) {
      _err('Error', 'Crop recommendations failed: $e');
    } finally {
      isLoading(false);
    }
  }

  // ==========================================
  // UI Helpers
  // ==========================================
  void showImagePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choose Soil Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Take a clear soil photo or pick from gallery', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _pickerBtn(Icons.camera_alt, '📸 Camera', const Color(0xFF2E7D32), () { Get.back(); scanFromCamera(); })),
              const SizedBox(width: 16),
              Expanded(child: _pickerBtn(Icons.photo_library, '🖼️ Gallery', const Color(0xFF1565C0), () { Get.back(); scanFromGallery(); })),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void showFieldImagePicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Add Field Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _pickerBtn(Icons.camera_alt, '📸 Camera', const Color(0xFFE65100), () { Get.back(); addFieldFromCamera(); })),
              const SizedBox(width: 16),
              Expanded(child: _pickerBtn(Icons.photo_library, '🖼️ Gallery', const Color(0xFF1565C0), () { Get.back(); addFieldFromGallery(); })),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pickerBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void resetAnalysis() {
    soilResult.value = null;
    plantRecommendations.clear();
    cropRecommendations.clear();
    selectedImage.value = null;
    analysisType.value = null;
    fieldImages.clear();
    showFieldCapture.value = false;
    showSeasonSelection.value = false;
    selectedSeason.value = null;
    expandedPlantIdx.value = -1;
    expandedCropIdx.value = -1;
  }

  void backToSoilResult() {
    analysisType.value = null;
    plantRecommendations.clear();
    cropRecommendations.clear();
    fieldImages.clear();
    showFieldCapture.value = false;
    showSeasonSelection.value = false;
    selectedSeason.value = null;
    expandedPlantIdx.value = -1;
    expandedCropIdx.value = -1;
  }

  void _err(String title, String msg) {
    Get.snackbar(title, msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4));
  }
}
