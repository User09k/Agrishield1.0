import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/policy_model.dart';

class PolicyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pinata JWT for policy contract hashing
  final String _pinataJwt =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJjNzE3ZDdjMS0zYzI4LTRmY2QtYjdiMi1mMDlkMDk4YjFkYjgiLCJlbWFpbCI6InRhcnVucGF0ZWw1Njc2QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaW5fcG9saWN5Ijp7InJlZ2lvbnMiOlt7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6IkZSQTEifSx7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6Ik5ZQzEifV0sInZlcnNpb24iOjF9LCJtZmFfZW5hYmxlZCI6ZmFsc2UsInN0YXR1cyI6IkFDVElWRSJ9LCJhdXRoZW50aWNhdGlvblR5cGUiOiJzY29wZWRLZXkiLCJzY29wZWRLZXlLZXkiOiIwNWQ1YTU5NWNmZWRkZDJmODA2ZSIsInNjb3BlZEtleVNlY3JldCI6Ijg0OWI0ODUyNTJkOGRmYjY5OGU2MTczNWFkOGY5MzBiNzY4MTkxODdiMGMxZjhlOTFhNjUwOGI5NTdhMGQwODAiLCJleHAiOjE4MDQxNjcyMDh9.4feOpxlysV6CaWyxzYIyNoROF2Cij-mvNqfkXyhbUDk";

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. CALCULATE PREMIUM
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  double calculatePremium(String cropType, double areaAcres) {
    return PolicyModel.calculatePremium(cropType, areaAcres);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. CREATE POLICY — Upload contract to IPFS + save to Firebase
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<Map<String, dynamic>?> createPolicy({
    required String farmerId,
    required String enrollmentId,
    required String cropType,
    required double areaAcres,
    required double premiumAmount,
    required String gpsLocation,
    double triggerDamagePercent = 70.0,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // ── Step 1: Upload policy contract to IPFS (blockchain proof) ──
      final contractData = {
        'type': 'INSURANCE_POLICY',
        'farmerId': farmerId,
        'enrollmentId': enrollmentId,
        'cropType': cropType,
        'areaAcres': areaAcres,
        'premiumAmount': premiumAmount,
        'gpsLocation': gpsLocation,
        'triggerDamagePercent': triggerDamagePercent,
        'activatedAt': timestamp,
        'terms': 'If AI-detected crop damage exceeds ${triggerDamagePercent.toInt()}%, payout will be auto-approved via Smart Contract.',
      };

      String? blockchainHash;
      try {
        final response = await http.post(
          Uri.parse('https://api.pinata.cloud/pinning/pinJSONToIPFS'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_pinataJwt',
          },
          body: jsonEncode({
            "pinataContent": contractData,
            "pinataMetadata": {
              "name": "AgriShield_Policy_${enrollmentId}_$timestamp",
            }
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          blockchainHash = jsonDecode(response.body)['IpfsHash'];
          print('[Policy] ✅ Policy hash: $blockchainHash');
        }
      } catch (e) {
        print('[Policy] ⚠️ IPFS upload failed, saving without hash: $e');
      }

      // ── Step 2: Save to Firebase ──
      final docRef = await _firestore.collection('Policies').add({
        'farmerId': farmerId,
        'enrollmentId': enrollmentId,
        'cropType': cropType,
        'areaAcres': areaAcres,
        'premiumAmount': premiumAmount,
        'gpsLocation': gpsLocation,
        'triggerDamagePercent': triggerDamagePercent,
        'status': 'Active',
        'blockchainHash': blockchainHash ?? '',
        'created_at': timestamp,
        'timestamp': FieldValue.serverTimestamp(),
        'premium_paid': true,
        'premium_paid_at': timestamp,
      }).timeout(const Duration(seconds: 15));

      print('[Policy] ✅ Policy created: ${docRef.id}');

      return {
        'policyId': docRef.id,
        'blockchainHash': blockchainHash ?? '',
        'premiumAmount': premiumAmount,
        'status': 'Active',
      };
    } catch (e) {
      print('[Policy] ❌ Create error: $e');
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. GET ACTIVE POLICIES for a farmer
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<List<PolicyModel>> getActivePolicies(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('Policies')
          .where('farmerId', isEqualTo: farmerId)
          .where('status', isEqualTo: 'Active')
          .get()
          .timeout(const Duration(seconds: 15));

      return snapshot.docs.map((doc) => PolicyModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('[Policy] ❌ Fetch error: $e');
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. CHECK IF FARMER HAS ACTIVE POLICY for crop type
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<PolicyModel?> getActivePolicyForCrop(String farmerId, String cropType) async {
    try {
      final snapshot = await _firestore
          .collection('Policies')
          .where('farmerId', isEqualTo: farmerId)
          .where('cropType', isEqualTo: cropType)
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isNotEmpty) {
        return PolicyModel.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      print('[Policy] ❌ Check error: $e');
    }
    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. GET ALL POLICIES for a farmer (all statuses)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<List<PolicyModel>> getAllPolicies(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('Policies')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(const Duration(seconds: 15));

      return snapshot.docs.map((doc) => PolicyModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('[Policy] ❌ Fetch all error: $e');
      return [];
    }
  }
}
