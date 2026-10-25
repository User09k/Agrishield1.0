import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceService {
  // ✅ Pinata JWT — for IPFS blockchain notarization
  final String pinataJwt =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJjNzE3ZDdjMS0zYzI4LTRmY2QtYjdiMi1mMDlkMDk4YjFkYjgiLCJlbWFpbCI6InRhcnVucGF0ZWw1Njc2QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaW5fcG9saWN5Ijp7InJlZ2lvbnMiOlt7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6IkZSQTEifSx7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6Ik5ZQzEifV0sInZlcnNpb24iOjF9LCJtZmFfZW5hYmxlZCI6ZmFsc2UsInN0YXR1cyI6IkFDVElWRSJ9LCJhdXRoZW50aWNhdGlvblR5cGUiOiJzY29wZWRLZXkiLCJzY29wZWRLZXlLZXkiOiIwNWQ1YTU5NWNmZWRkZDJmODA2ZSIsInNjb3BlZEtleVNlY3JldCI6Ijg0OWI0ODUyNTJkOGRmYjY5OGU2MTczNWFkOGY5MzBiNzY4MTkxODdiMGMxZjhlOTFhNjUwOGI5NTdhMGQwODAiLCJleHAiOjE4MDQxNjcyMDh9.4feOpxlysV6CaWyxzYIyNoROF2Cij-mvNqfkXyhbUDk";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. UPLOAD TO BLOCKCHAIN (Pinata IPFS) — with retry
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<String?> uploadToBlockchain({
    required Map<String, dynamic> aiReport,
    required String enrollmentId,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) async {
    final url = Uri.parse('https://api.pinata.cloud/pinning/pinJSONToIPFS');

    final jsonBundle = {
      "enrollmentId": enrollmentId,
      "gpsLocation": {"latitude": latitude, "longitude": longitude},
      "timestamp": timestamp,
      "aiDiagnostics": aiReport,
    };

    final body = jsonEncode({
      "pinataContent": jsonBundle,
      "pinataMetadata": {
        "name": "AgriShield_Claim_${enrollmentId}_$timestamp",
      }
    });

    // Retry up to 3 times with 15s timeout each
    for (int attempt = 1; attempt <= 3; attempt++) {
      final client = http.Client();
      try {
        print('[Blockchain] 🔄 Attempt $attempt/3 — uploading to IPFS...');
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $pinataJwt',
          },
          body: body,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final hash = jsonDecode(response.body)['IpfsHash'];
          print('[Blockchain] ✅ IPFS Hash: $hash');
          return hash;
        } else {
          print('[Blockchain] ❌ Attempt $attempt failed: HTTP ${response.statusCode} — ${response.body}');
        }
      } on TimeoutException {
        print('[Blockchain] ⏳ Attempt $attempt timed out (15s)');
      } catch (e) {
        print('[Blockchain] ❌ Attempt $attempt error: $e');
      } finally {
        client.close();
      }

      // Wait 2s before retry (except on last attempt)
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print('[Blockchain] ❌ All 3 attempts failed — IPFS upload unsuccessful');
    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. SAVE CLAIM TO FIREBASE → Returns docId
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<String?> saveClaimToFirestore({
    required String farmerId,
    required String enrollmentId,
    required String cropName,
    required String disease,
    required String damagePercent,
    required String blockchainHash,
    required String location,
    required String claimType,
    required Map<String, dynamic>? aiReport,
    String? policyId,
  }) async {
    final String status = 'Pending Verification';

    try {
      final docRef = await _firestore.collection('Claims').add({
        'farmerId': farmerId,
        'enrollmentId': enrollmentId,
        'cropName': cropName,
        'disease': disease,
        'damagePercent': damagePercent,
        'ipfsHash': blockchainHash,
        'location': location,
        'claimType': claimType,
        'status': status,
        'aiReport': aiReport,
        'policyId': policyId ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(),
        'blockchain_verified': true,
        'smart_contract_executed': false,
      }).timeout(const Duration(seconds: 15));

      print('[Insurance] ✅ Claim saved: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[Insurance] ❌ Error saving claim: $e');
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. SUBMIT TO GOVERNMENT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> submitToGovt(String claimDocId) async {
    try {
      await _firestore.collection('Claims').doc(claimDocId).update({
        'status': 'Submitted_to_Govt',
        'govt_submitted_at': DateTime.now().toIso8601String(),
        'govt_notification': true,
      }).timeout(const Duration(seconds: 15));
      print('[Insurance] ✅ Submitted to Govt: $claimDocId');
    } catch (e) {
      print('[Insurance] ❌ Govt submit error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. SMART CONTRACT — 3-Point Verification
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Verifies: 1) Enrollment ID match 2) GPS within 500m 3) Damage > trigger%
  Future<Map<String, dynamic>> executeSmartContract({
    required String claimDocId,
    required double damagePercent,
    required String claimEnrollmentId,
    required String claimLocation,
    String? policyId,
  }) async {
    final result = <String, dynamic>{
      'approved': false,
      'checks': <String, dynamic>{},
      'reason': '',
    };

    try {
      // ── Fetch the policy for this farmer ──
      Map<String, dynamic>? policy;
      if (policyId != null && policyId.isNotEmpty) {
        final policyDoc = await _firestore
            .collection('Policies')
            .doc(policyId)
            .get()
            .timeout(const Duration(seconds: 10));
        if (policyDoc.exists) {
          policy = policyDoc.data();
        }
      }

      if (policy == null) {
        result['reason'] = 'No active policy found';
        await _firestore.collection('Claims').doc(claimDocId).update({
          'status': 'Verification_Failed',
          'smart_contract_executed': true,
          'smart_contract_timestamp': DateTime.now().toIso8601String(),
          'verification_result': result,
        }).timeout(const Duration(seconds: 10));
        return result;
      }

      // ═══ CHECK 1: Enrollment ID Match ═══
      final policyEnrollmentId = policy['enrollmentId'] ?? '';
      final enrollmentMatch = policyEnrollmentId == claimEnrollmentId;
      result['checks']['enrollment_id_match'] = enrollmentMatch;

      // ═══ CHECK 2: GPS Location Match (within 500m) ═══
      bool gpsMatch = false;
      try {
        final policyGps = policy['gpsLocation'] ?? '';
        if (policyGps.toString().contains(',') && claimLocation.contains(',')) {
          final policyParts = policyGps.toString().split(',').map((s) => double.tryParse(s.trim())).toList();
          final claimParts = claimLocation.split(',').map((s) => double.tryParse(s.trim())).toList();

          if (policyParts.length >= 2 && claimParts.length >= 2 &&
              policyParts[0] != null && policyParts[1] != null &&
              claimParts[0] != null && claimParts[1] != null) {
            final latDiff = (policyParts[0]! - claimParts[0]!).abs();
            final lonDiff = (policyParts[1]! - claimParts[1]!).abs();
            // ~0.0045 degrees ≈ 500m
            gpsMatch = latDiff < 0.0045 && lonDiff < 0.0045;
          }
        }
      } catch (_) {}
      result['checks']['gps_location_match'] = gpsMatch;

      // ═══ CHECK 3: Damage > Trigger Percentage ═══
      final triggerPercent = (policy['triggerDamagePercent'] ?? 70).toDouble();
      final damageExceeds = damagePercent > triggerPercent;
      result['checks']['damage_exceeds_trigger'] = damageExceeds;
      result['checks']['trigger_percent'] = triggerPercent;
      result['checks']['actual_damage'] = damagePercent;

      // ═══ VERDICT ═══
      final allPassed = enrollmentMatch && gpsMatch && damageExceeds;
      result['approved'] = allPassed;

      if (allPassed) {
        result['reason'] = 'All 3 checks passed — Auto-Approved by Smart Contract';
        await _firestore.collection('Claims').doc(claimDocId).update({
          'status': 'Smart_Contract_Approved',
          'smart_contract_executed': true,
          'smart_contract_timestamp': DateTime.now().toIso8601String(),
          'auto_approved': true,
          'payout_eligible': true,
          'verification_result': result,
          'payout_reason': 'Damage ${damagePercent.toStringAsFixed(0)}% > ${triggerPercent.toStringAsFixed(0)}% trigger — Smart Contract verified',
        }).timeout(const Duration(seconds: 10));

        // Mark policy as claimed
        await _firestore.collection('Policies').doc(policyId).update({
          'status': 'Claimed',
          'claimed_at': DateTime.now().toIso8601String(),
          'claim_doc_id': claimDocId,
        }).timeout(const Duration(seconds: 10));

        print('[SmartContract] ✅ AUTO-APPROVED! All 3 checks passed.');
      } else {
        // Build failure reason
        final failures = <String>[];
        if (!enrollmentMatch) failures.add('Enrollment ID mismatch');
        if (!gpsMatch) failures.add('GPS location out of range');
        if (!damageExceeds) failures.add('Damage ${damagePercent.toStringAsFixed(0)}% below ${triggerPercent.toStringAsFixed(0)}% trigger');
        result['reason'] = 'Verification failed: ${failures.join(", ")}';

        await _firestore.collection('Claims').doc(claimDocId).update({
          'status': 'Verification_Failed',
          'smart_contract_executed': true,
          'smart_contract_timestamp': DateTime.now().toIso8601String(),
          'auto_approved': false,
          'payout_eligible': false,
          'verification_result': result,
        }).timeout(const Duration(seconds: 10));

        print('[SmartContract] ❌ FAILED: ${result['reason']}');
      }
    } catch (e) {
      print('[SmartContract] ❌ Error: $e');
      result['reason'] = 'Execution error: $e';
    }

    return result;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. FETCH CLAIMS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<List<Map<String, dynamic>>> getClaimsForFarmer(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('Claims')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(const Duration(seconds: 15));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[Insurance] ❌ Fetch error: $e');
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. VERIFY BY HASH
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<Map<String, dynamic>?> verifyByHash(String ipfsHash) async {
    try {
      final snapshot = await _firestore
          .collection('Claims')
          .where('ipfsHash', isEqualTo: ipfsHash)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isNotEmpty) return snapshot.docs.first.data();
    } catch (e) {
      print('[Insurance] ❌ Verify error: $e');
    }
    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7. INSURANCE ELIGIBILITY CHECK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Map<String, dynamic> checkInsuranceEligibility({
    required int healthScore,
    required String disease,
    required String weatherCondition,
    required String diseaseRisk,
  }) {
    final bool hasDisease = disease.toLowerCase() != 'no disease detected' &&
        disease.toLowerCase() != 'healthy' &&
        disease.toLowerCase() != 'n/a';

    final int damagePercent = (100 - healthScore).clamp(0, 100);
    final bool significantDamage = damagePercent >= 40;

    final bool weatherSupports = weatherCondition.toLowerCase().contains('rain') ||
        weatherCondition.toLowerCase().contains('storm') ||
        weatherCondition.toLowerCase().contains('hail') ||
        weatherCondition.toLowerCase().contains('flood') ||
        weatherCondition.toLowerCase().contains('drought') ||
        weatherCondition.toLowerCase().contains('extreme') ||
        weatherCondition.toLowerCase().contains('overcast') ||
        weatherCondition.toLowerCase().contains('cloud') ||
        diseaseRisk.toLowerCase() == 'high' ||
        diseaseRisk.toLowerCase() == 'critical';

    if (!hasDisease && !significantDamage) {
      return {
        'eligible': false,
        'reason': 'Fasal healthy hai — koi bimari ya nuksan detect nahi hua',
        'reason_en': 'Crop is healthy — no disease or significant damage detected',
        'damage_percent': damagePercent,
        'has_disease': false,
        'weather_supports': weatherSupports,
      };
    }

    if (hasDisease && significantDamage) {
      return {
        'eligible': true,
        'reason': 'Fasal mein bimari detect hui hai aur nuksan $damagePercent% hai — Insurance ke liye eligible',
        'reason_en': 'Disease detected with $damagePercent% damage — Eligible for insurance',
        'damage_percent': damagePercent,
        'has_disease': true,
        'weather_supports': weatherSupports,
      };
    }

    if (hasDisease && !significantDamage) {
      return {
        'eligible': true,
        'reason': 'Bimari detect hui hai ($disease) — monitoring ke liye insurance eligible',
        'reason_en': 'Disease detected ($disease) — eligible for insurance monitoring',
        'damage_percent': damagePercent,
        'has_disease': true,
        'weather_supports': weatherSupports,
      };
    }

    return {
      'eligible': true,
      'reason': 'Fasal mein $damagePercent% nuksan detect hua — Insurance eligible',
      'reason_en': 'Crop shows $damagePercent% damage — Eligible for insurance',
      'damage_percent': damagePercent,
      'has_disease': false,
      'weather_supports': weatherSupports,
    };
  }
}