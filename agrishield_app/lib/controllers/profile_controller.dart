import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import 'language_controller.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Profile fields
  var farmerName = 'Farmer'.obs;
  var farmerPhone = ''.obs;
  var farmerEmail = ''.obs;
  var farmerLocation = 'Madhya Pradesh, India'.obs;
  var farmSize = '5 Acre'.obs;
  var enrollmentId = ''.obs;

  // Alert stats
  var totalAlerts = 0.obs;
  var criticalAlerts = 0.obs;
  var totalScans = 0.obs;
  var isLoading = false.obs;

  // Recent alerts
  var recentAlerts = <Map<String, dynamic>>[].obs;

  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    fetchAlertStats();
  }

  /// Load profile from Firestore (primary) + GetStorage (fallback)
  Future<void> loadProfile() async {
    // First load from local storage (instant)
    farmerName.value = _storage.read('farmer_name') ?? 'Farmer';
    farmerPhone.value = _storage.read('farmer_phone') ?? '';
    farmerEmail.value = _storage.read('farmer_email') ?? '';
    farmerLocation.value =
        _storage.read('farmer_location') ?? 'Madhya Pradesh, India';
    farmSize.value = _storage.read('farm_size') ?? '5 Acre';
    enrollmentId.value = _storage.read('enrollment_id') ?? '';

    // Then try to load from Firestore (latest data)
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          farmerName.value = data['name'] ?? farmerName.value;
          farmerPhone.value = data['phone'] ?? farmerPhone.value;
          farmerEmail.value = data['email'] ?? farmerEmail.value;
          farmerLocation.value = data['location'] ?? farmerLocation.value;
          farmSize.value = data['farm_size'] ?? farmSize.value;
          enrollmentId.value = data['enrollment_id'] ?? enrollmentId.value;

          // Sync to local storage
          _storage.write('farmer_name', farmerName.value);
          _storage.write('farmer_phone', farmerPhone.value);
          _storage.write('farmer_email', farmerEmail.value);
          _storage.write('farmer_location', farmerLocation.value);
          _storage.write('farm_size', farmSize.value);
          _storage.write('enrollment_id', enrollmentId.value);
        }
      }
    } catch (e) {
      debugPrint('[Profile] Firestore load error: $e');
    }
  }

  void saveProfile({
    String? name,
    String? phone,
    String? email,
    String? location,
    String? size,
  }) {
    if (name != null) {
      farmerName.value = name;
      _storage.write('farmer_name', name);
    }
    if (phone != null) {
      farmerPhone.value = phone;
      _storage.write('farmer_phone', phone);
    }
    if (email != null) {
      farmerEmail.value = email;
      _storage.write('farmer_email', email);
    }
    if (location != null) {
      farmerLocation.value = location;
      _storage.write('farmer_location', location);
    }
    if (size != null) {
      farmSize.value = size;
      _storage.write('farm_size', size);
    }

    // Sync to Firestore if authenticated
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _db.collection('users').doc(uid).set({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (location != null) 'location': location,
          if (size != null) 'farm_size': size,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint('[Profile] Firestore sync warning: $e');
        });
      }
    } catch (e) {
      debugPrint('[Profile] Firestore update error: $e');
    }

    final isHi = LanguageController.currentLang == 'hi';
    Get.snackbar(
      isHi ? '✅ सुरक्षित' : '✅ Saved',
      isHi ? 'प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई' : 'Profile updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1B5E20),
      duration: const Duration(seconds: 2),
    );
  }

  // ── Communication — Call AI Assistant via Twilio ────────────
  static const String twilioPhoneNumber = '+13639990565';

  Future<void> callAIAssistant() async {
    final url = Uri.parse('tel:$twilioPhoneNumber');
    final isHi = LanguageController.currentLang == 'hi';
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Get.snackbar(
        isHi ? 'त्रुटि' : 'Error',
        isHi ? 'कॉल नहीं की जा सकी' : 'Could not make the call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Fetch alert stats from backend ─────────────────────────
  Future<void> fetchAlertStats() async {
    isLoading(true);
    try {
      final lang = LanguageController.currentLang;
      final response = await http
          .get(
            Uri.parse('$baseUrl/alert-history?limit=50'),
            headers: {
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final List alerts = data['data'] ?? [];
          totalAlerts.value = alerts.length;
          criticalAlerts.value =
              alerts.where((a) => a['alert_level'] == 'CRITICAL').length;
          recentAlerts.value = List<Map<String, dynamic>>.from(
              alerts.take(5).map((a) => Map<String, dynamic>.from(a)));
        }
      }
    } catch (e) {
      debugPrint('[Profile] Alert fetch error: $e');
    } finally {
      isLoading(false);
    }
  }

  // ── Send test alert ────────────────────────────────────────
  Future<void> sendTestAlert() async {
    final isHi = LanguageController.currentLang == 'hi';
    try {
      Get.snackbar(
        isHi ? '🔔 भेजा जा रहा है...' : '🔔 Sending...',
        isHi ? 'टेस्ट अलर्ट भेजा जा रहा है...' : 'Sending test alert...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      final lang = LanguageController.currentLang;
      final response = await http.post(
        Uri.parse('$baseUrl/send-alert'),
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': lang,
          'X-App-Language': lang,
        },
        body: json.encode({
          'message': isHi
              ? '🧪 टेस्ट अलर्ट: AgriShield AI प्रणाली सक्रिय है! सभी प्रणालियां ठीक काम कर रही हैं।'
              : '🧪 Test Alert: AgriShield AI system is working! All systems OK.',
          'level': 'INFO',
          'language': lang,
        }),
      );
      if (response.statusCode == 200) {
        Get.snackbar(
          isHi ? '✅ भेजा गया!' : '✅ Sent!',
          isHi ? 'टेस्ट अलर्ट सफलतापूर्वक भेजा गया!' : 'Test alert sent successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: const Color(0xFF1B5E20),
        );
        fetchAlertStats();
      }
    } catch (e) {
      Get.snackbar(
        isHi ? '❌ त्रुटि' : '❌ Error',
        isHi ? 'अलर्ट नहीं भेजा जा सका: $e' : 'Could not send alert: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
