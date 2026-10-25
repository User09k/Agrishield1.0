import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../insurance/insurance_service.dart';
import '../insurance/policy_service.dart';
import '../models/scan_model.dart';
import '../models/policy_model.dart';
import '../config/app_config.dart';
import '../views/digital_certificate_view.dart';
import '../views/buy_policy_view.dart';

/// Blockchain Controller — orchestrates the claim process:
/// Step 1: Image Capture
/// Step 2: GPS Location
/// Step 3: AI Diagnostics
/// Step 4: Blockchain Notarization (IPFS)
/// Step 5: Hash Generation + Save to Firebase
/// Step 6: Verification Trigger / Smart Contract
class BlockchainController extends GetxController {
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _insuranceService = InsuranceService();
  final _policyService = PolicyService();

  var isProcessing = false.obs;
  var currentStep = 0.obs;
  var lastHash = ''.obs;
  var lastStatus = ''.obs;
  var selectedImage = Rxn<File>();

  // Claims + Policies
  var claims = <Map<String, dynamic>>[].obs;
  var activePolicies = <PolicyModel>[].obs;
  var isLoadingClaims = false.obs;

  final ImagePicker _picker = ImagePicker();
  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    fetchClaims();
    fetchPolicies();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PHOTO PICKER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void showClaimPhotoPicker(String claimType) {
    // For private claims: check if has active policy first
    if (claimType == 'private') {
      _checkPolicyAndProceed(claimType);
      return;
    }
    _showPhotoPicker(claimType);
  }

  /// Check active policy before private claim
  Future<void> _checkPolicyAndProceed(String claimType) async {
    final farmerId = _auth.currentUser?.uid ?? '';
    if (farmerId.isEmpty) {
      Get.snackbar('❌ Error', 'User not logged in', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Fetch active policies
    final policies = await _policyService.getActivePolicies(farmerId);
    if (policies.isEmpty) {
      // No active policy — redirect to BuyPolicyView
      Get.snackbar(
        '🏦 Policy Required',
        'Pehle insurance policy kharidein, phir claim file kar sakte hain.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange[50],
        colorText: Colors.orange[900],
      );
      Get.to(() => const BuyPolicyView());
      return;
    }

    _showPhotoPicker(claimType);
  }

  void _showPhotoPicker(String claimType) {
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
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Text(
              claimType == 'government' ? "🏛️ Sarkari Rahat Claim" : "🏦 Private Insurance Claim",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text("Upload fasal ka photo for blockchain proof",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerBtn(icon: Icons.camera_alt, label: "Camera", color: Colors.green,
                    onTap: () { Get.back(); _pickAndProcess(ImageSource.camera, claimType); }),
                _buildPickerBtn(icon: Icons.photo_library, label: "Gallery", color: Colors.blue,
                    onTap: () { Get.back(); _pickAndProcess(ImageSource.gallery, claimType); }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBtn({required IconData icon, required String label, required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 70, height: 70,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 32)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FULL PIPELINE: Pick Image → AI → IPFS → Firebase → Verify
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _pickAndProcess(ImageSource source, String claimType) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    selectedImage.value = File(image.path);
    isProcessing(true);
    currentStep.value = 1;

    try {
      // ═══════ STEP 1: Image captured ═══════
      currentStep.value = 1;

      // ═══════ STEP 2: GPS ═══════
      currentStep.value = 2;
      Position? position;
      String locationStr = 'Location unavailable';
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          Get.snackbar('📍 Location Required', 'GPS permission needed', snackPosition: SnackPosition.BOTTOM);
          isProcessing(false); currentStep.value = 0; return;
        }
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 15));
        locationStr = '${position.latitude}, ${position.longitude}';
      } catch (e) {
        Get.snackbar('📍 GPS Error', 'Enable GPS and try again.', snackPosition: SnackPosition.BOTTOM);
        isProcessing(false); currentStep.value = 0; return;
      }

      // ═══════ STEP 3: AI Analysis ═══════
      currentStep.value = 3;
      ScanModel? scanResult;
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
        var response = await request.send().timeout(const Duration(seconds: 90));
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        if (jsonResponse['status'] == 'Success') {
          scanResult = ScanModel.fromJson(jsonResponse['data']);
        } else {
          Get.snackbar('❌ AI Failed', jsonResponse['error']?.toString() ?? 'Error', snackPosition: SnackPosition.BOTTOM);
          isProcessing(false); currentStep.value = 0; return;
        }
      } catch (e) {
        Get.snackbar('❌ Connection Error', 'Cannot reach server.', snackPosition: SnackPosition.BOTTOM);
        isProcessing(false); currentStep.value = 0; return;
      }

      // ═══════ STEP 4: Blockchain (IPFS) ═══════
      currentStep.value = 4;
      final enrollmentId = _storage.read('enrollment_id') ?? '';
      final farmerId = _auth.currentUser?.uid ?? '';
      final timestamp = DateTime.now().toIso8601String();
      final damagePercent = (100 - scanResult.healthScore).clamp(0, 100);

      final aiReport = {
        'crop_name': scanResult.cropName,
        'disease': scanResult.disease,
        'disease_cause': scanResult.diseaseCause,
        'health_score': scanResult.healthScore,
        'health_status': scanResult.healthStatus,
        'damage_percent': damagePercent,
        'treatment': scanResult.treatment,
        'confidence': scanResult.confidence,
      };

      final ipfsHash = await _insuranceService.uploadToBlockchain(
        aiReport: aiReport, enrollmentId: enrollmentId,
        latitude: position.latitude, longitude: position.longitude, timestamp: timestamp,
      );

      if (ipfsHash == null) {
        Get.snackbar('❌ Blockchain Error', 'IPFS upload failed.', snackPosition: SnackPosition.BOTTOM);
        isProcessing(false); currentStep.value = 0; return;
      }

      // ═══════ STEP 5: Save to Firebase ═══════
      currentStep.value = 5;
      lastHash.value = ipfsHash;

      // Find matching policy for private claims
      String? policyId;
      if (claimType == 'private') {
        final policy = await _policyService.getActivePolicyForCrop(farmerId, scanResult.cropName);
        policyId = policy?.policyId;
      }

      final claimDocId = await _insuranceService.saveClaimToFirestore(
        farmerId: farmerId, enrollmentId: enrollmentId,
        cropName: scanResult.cropName, disease: scanResult.disease,
        damagePercent: damagePercent.toString(), blockchainHash: ipfsHash,
        location: locationStr, claimType: claimType, aiReport: aiReport, policyId: policyId,
      );

      // ═══════ STEP 6: Auto-Trigger ═══════
      currentStep.value = 6;

      if (claimDocId != null) {
        if (claimType == 'government') {
          await _insuranceService.submitToGovt(claimDocId);
          lastStatus.value = 'Submitted_to_Govt';
          Get.snackbar('🏛️ Govt Submission!',
              'Claim sent for verification.\nHash: ${ipfsHash.substring(0, 12)}...',
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        } else if (claimType == 'private') {
          // Smart Contract — 3-point verification
          final scResult = await _insuranceService.executeSmartContract(
            claimDocId: claimDocId,
            damagePercent: damagePercent.toDouble(),
            claimEnrollmentId: enrollmentId,
            claimLocation: locationStr,
            policyId: policyId,
          );

          if (scResult['approved'] == true) {
            lastStatus.value = 'Smart_Contract_Approved';
            Get.snackbar('✅ Smart Contract Approved!',
                'All 3 checks passed! Payout auto-approved.\nDamage: $damagePercent%',
                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
          } else {
            lastStatus.value = 'Verification_Failed';
            Get.snackbar('❌ Verification Failed',
                scResult['reason'] ?? 'Smart Contract verification failed',
                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
          }
        } else {
          lastStatus.value = 'Pending Verification';
          Get.snackbar('🔗 Claim Submitted!',
              'Hash: ${ipfsHash.substring(0, 12)}...',
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        }

        // Navigate to Digital Certificate
        Get.to(() => DigitalCertificateView(
              enrollmentId: enrollmentId, ipfsHash: ipfsHash,
              cropName: scanResult!.cropName, disease: scanResult.disease,
              damagePercent: damagePercent.toString(), claimType: claimType,
              status: lastStatus.value, timestamp: timestamp, location: locationStr,
            ));
      } else {
        Get.snackbar('❌ Save Failed', 'Could not save claim to Firebase. Check your internet.',
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
      }

      await fetchClaims();
    } catch (e) {
      Get.snackbar('❌ Error', 'Something went wrong: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing(false);
      currentStep.value = 0;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PROCESS CLAIM (from ScanController)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> processClaim({
    required ScanModel scanResult,
    required String claimType,
  }) async {
    isProcessing(true);
    currentStep.value = 1;

    try {
      // For private claims, check active policy
      final farmerId = _auth.currentUser?.uid ?? '';
      String? policyId;

      if (claimType == 'private') {
        final policy = await _policyService.getActivePolicyForCrop(farmerId, scanResult.cropName);
        if (policy == null) {
          Get.snackbar('🏦 Policy Required',
              'Pehle ${scanResult.cropName} ke liye insurance policy kharidein.',
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
          Get.to(() => const BuyPolicyView());
          isProcessing(false); currentStep.value = 0; return;
        }
        policyId = policy.policyId;
      }

      // ═══════ STEP 2: GPS ═══════
      currentStep.value = 2;
      Position? position;
      String locationStr = 'Location unavailable';
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          Get.snackbar('📍 Location Required', 'GPS permission needed',
              snackPosition: SnackPosition.BOTTOM);
          isProcessing(false); currentStep.value = 0; return;
        }
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 15));
        locationStr = '${position.latitude}, ${position.longitude}';
      } catch (e) {
        Get.snackbar('📍 GPS Error', 'Enable GPS and try again.', snackPosition: SnackPosition.BOTTOM);
        isProcessing(false); currentStep.value = 0; return;
      }

      // ═══════ STEP 3: AI already done ═══════
      currentStep.value = 3;
      final enrollmentId = _storage.read('enrollment_id') ?? '';
      final timestamp = DateTime.now().toIso8601String();
      final damagePercent = (100 - scanResult.healthScore).clamp(0, 100);

      final aiReport = {
        'crop_name': scanResult.cropName,
        'disease': scanResult.disease,
        'disease_cause': scanResult.diseaseCause,
        'health_score': scanResult.healthScore,
        'health_status': scanResult.healthStatus,
        'damage_percent': damagePercent,
        'treatment': scanResult.treatment,
        'confidence': scanResult.confidence,
      };

      // ═══════ STEP 4: IPFS Upload ═══════
      currentStep.value = 4;
      final ipfsHash = await _insuranceService.uploadToBlockchain(
        aiReport: aiReport, enrollmentId: enrollmentId,
        latitude: position.latitude, longitude: position.longitude, timestamp: timestamp,
      );

      if (ipfsHash == null) {
        Get.snackbar('❌ Blockchain Error', 'IPFS upload failed.', snackPosition: SnackPosition.BOTTOM);
        isProcessing(false); currentStep.value = 0; return;
      }

      // ═══════ STEP 5: Save to Firebase ═══════
      currentStep.value = 5;
      lastHash.value = ipfsHash;

      final claimDocId = await _insuranceService.saveClaimToFirestore(
        farmerId: farmerId, enrollmentId: enrollmentId,
        cropName: scanResult.cropName, disease: scanResult.disease,
        damagePercent: damagePercent.toString(), blockchainHash: ipfsHash,
        location: locationStr, claimType: claimType, aiReport: aiReport, policyId: policyId,
      );

      // ═══════ STEP 6: Auto-Trigger ═══════
      currentStep.value = 6;

      if (claimDocId != null) {
        if (claimType == 'government') {
          await _insuranceService.submitToGovt(claimDocId);
          lastStatus.value = 'Submitted_to_Govt';
          Get.snackbar('🏛️ Submitted to Government!',
              'Hash: ${ipfsHash.substring(0, 12)}...',
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        } else if (claimType == 'private') {
          final scResult = await _insuranceService.executeSmartContract(
            claimDocId: claimDocId,
            damagePercent: damagePercent.toDouble(),
            claimEnrollmentId: enrollmentId,
            claimLocation: locationStr,
            policyId: policyId,
          );

          if (scResult['approved'] == true) {
            lastStatus.value = 'Smart_Contract_Approved';
            Get.snackbar('✅ Smart Contract Approved!',
                'All 3 checks passed! Payout auto-approved.\nDamage: $damagePercent%',
                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
          } else {
            lastStatus.value = 'Verification_Failed';
            Get.snackbar('❌ Verification Failed',
                scResult['reason'] ?? 'Verification failed',
                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
          }
        } else {
          lastStatus.value = 'Pending Verification';
          Get.snackbar('🔗 Claim Submitted!', 'Hash: ${ipfsHash.substring(0, 12)}...',
              snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        }

        Get.to(() => DigitalCertificateView(
              enrollmentId: enrollmentId, ipfsHash: ipfsHash,
              cropName: scanResult.cropName, disease: scanResult.disease,
              damagePercent: damagePercent.toString(), claimType: claimType,
              status: lastStatus.value, timestamp: timestamp, location: locationStr,
            ));
      } else {
        Get.snackbar('❌ Save Failed', 'Could not save claim to Firebase.',
            snackPosition: SnackPosition.BOTTOM);
      }

      await fetchClaims();
    } catch (e) {
      Get.snackbar('❌ Error', 'Something went wrong: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing(false);
      currentStep.value = 0;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FETCH DATA
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> fetchClaims() async {
    isLoadingClaims(true);
    try {
      final farmerId = _auth.currentUser?.uid ?? '';
      if (farmerId.isNotEmpty) {
        final result = await _insuranceService.getClaimsForFarmer(farmerId);
        claims.value = result;
      }
    } catch (e) {
      print('[Claims] ❌ Fetch error: $e');
    } finally {
      isLoadingClaims(false);
    }
  }

  Future<void> fetchPolicies() async {
    try {
      final farmerId = _auth.currentUser?.uid ?? '';
      if (farmerId.isNotEmpty) {
        final result = await _policyService.getActivePolicies(farmerId);
        activePolicies.value = result;
      }
    } catch (e) {
      print('[Policies] ❌ Fetch error: $e');
    }
  }

  String getStepLabel(int step) {
    switch (step) {
      case 1: return '📷 Capturing image...';
      case 2: return '📍 Fetching GPS location...';
      case 3: return '🤖 Processing AI diagnostics...';
      case 4: return '🔗 Uploading to blockchain (IPFS)...';
      case 5: return '✅ Generating hash & saving claim...';
      case 6: return '🏛️ Smart Contract verification...';
      default: return '';
    }
  }
}
