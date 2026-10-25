import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. CROP SCAN — Save to 'crop_scans'
  // ==========================================
  static Future<void> saveCropScan(Map<String, dynamic> scanData) async {
    try {
      scanData['timestamp'] = FieldValue.serverTimestamp();
      scanData['created_at'] = DateTime.now().toIso8601String();

      await _db.collection('crop_scans').add(scanData).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore timeout'),
      );
      print('[Firestore] ✅ Crop scan saved successfully');
    } catch (e) {
      print('[Firestore] ❌ Error saving crop scan: $e');
    }
  }

  // ==========================================
  // 2. SOIL ANALYSIS — Save to 'soil_analyses'
  // ==========================================
  static Future<String?> saveSoilAnalysis(Map<String, dynamic> soilData) async {
    try {
      soilData['timestamp'] = FieldValue.serverTimestamp();
      soilData['created_at'] = DateTime.now().toIso8601String();

      final docRef = await _db.collection('soil_analyses').add(soilData).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore timeout'),
      );
      print('[Firestore] ✅ Soil analysis saved: ${docRef.id}');
      return docRef.id; // Return doc ID so we can link recommendations
    } catch (e) {
      print('[Firestore] ❌ Error saving soil analysis: $e');
      return null;
    }
  }

  // ==========================================
  // 3. RECOMMENDATIONS — Save to 'recommendations'
  // ==========================================
  static Future<void> saveRecommendations({
    required String type, // 'plant' or 'crop'
    required List<Map<String, dynamic>> items,
    String? soilDocId,
    String? soilType,
    String? season,
  }) async {
    try {
      final data = {
        'type': type,
        'soil_doc_id': soilDocId,
        'soil_type': soilType ?? 'Unknown',
        'season': season ?? 'all',
        'items': items,
        'item_count': items.length,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _db.collection('recommendations').add(data).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore timeout'),
      );
      print('[Firestore] ✅ $type recommendations saved (${items.length} items)');
    } catch (e) {
      print('[Firestore] ❌ Error saving recommendations: $e');
    }
  }

  // ==========================================
  // QUERY HELPERS (for future Twilio alerts)
  // ==========================================

  /// Get all crop scans with low health (for alert triggers)
  static Future<List<Map<String, dynamic>>> getCriticalCropScans({
    int healthThreshold = 40,
  }) async {
    try {
      final snapshot = await _db
          .collection('crop_scans')
          .where('health_score', isLessThanOrEqualTo: healthThreshold)
          .orderBy('health_score')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[Firestore] ❌ Error querying critical scans: $e');
      return [];
    }
  }

  /// Get recent soil analyses
  static Future<List<Map<String, dynamic>>> getRecentSoilAnalyses({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _db
          .collection('soil_analyses')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[Firestore] ❌ Error querying soil analyses: $e');
      return [];
    }
  }

  /// Get all disease-detected scans (for Twilio disease alert)
  static Future<List<Map<String, dynamic>>> getDiseaseAlertScans() async {
    try {
      final snapshot = await _db
          .collection('crop_scans')
          .where('disease', isNotEqualTo: 'No disease detected')
          .orderBy('disease')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[Firestore] ❌ Error querying disease scans: $e');
      return [];
    }
  }

  // ==========================================
  // 4. CLAIMS — Save & Fetch Insurance Claims
  // ==========================================
  static Future<void> saveClaim(Map<String, dynamic> claimData) async {
    try {
      claimData['timestamp'] = FieldValue.serverTimestamp();
      claimData['created_at'] = DateTime.now().toIso8601String();

      await _db.collection('Claims').add(claimData).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore timeout'),
      );
      print('[Firestore] ✅ Claim saved successfully');
    } catch (e) {
      print('[Firestore] ❌ Error saving claim: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getClaims({
    String? farmerId,
    int limit = 20,
  }) async {
    try {
      var query = _db.collection('Claims').orderBy('timestamp', descending: true).limit(limit);
      if (farmerId != null && farmerId.isNotEmpty) {
        query = _db
            .collection('Claims')
            .where('farmerId', isEqualTo: farmerId)
            .orderBy('timestamp', descending: true)
            .limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[Firestore] ❌ Error fetching claims: $e');
      return [];
    }
  }
}
