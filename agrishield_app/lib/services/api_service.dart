/// AgriShield AI — Centralized Backend API Service
/// ==================================================
/// Single source-of-truth for all HTTP calls to the
/// Flask backend (powered by Google Gemini API).
///
/// Backend base URL is read from AppConfig (app_config.dart).
/// All methods return parsed JSON or throw descriptive exceptions.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../controllers/language_controller.dart';

class ApiService {
  // ─── Singleton ────────────────────────────────────────────────
  ApiService._();
  static final ApiService instance = ApiService._();

  String get _base => AppConfig.baseUrl;

  String get _currentLang => LanguageController.currentLang;

  // ─── Headers & Tracing ────────────────────────────────────────
  Map<String, String> get _standardHeaders {
    final lang = _currentLang;
    return {
      'Accept-Language': lang == 'hi' ? 'hi-IN, hi;q=0.9, en;q=0.8' : 'en-US, en;q=0.9, hi;q=0.8',
      'X-App-Language': lang,
      'X-Request-ID': 'flt_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    ..._standardHeaders,
  };

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final sw = Stopwatch()..start();
    final allParams = {
      if (params != null) ...params,
      if (params == null || !params.containsKey('lang')) 'lang': _currentLang,
    };
    final uri = Uri.parse('$_base$path').replace(queryParameters: allParams);
    final headers = _standardHeaders;

    if (kDebugMode) {
      debugPrint('[ApiService] ➡️ GET $_base$path | Lang: $_currentLang | ReqID: ${headers['X-Request-ID']}');
    }

    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      sw.stop();
      if (kDebugMode) {
        debugPrint('[ApiService] ⬅️ [${response.statusCode}] GET $_base$path (${sw.elapsedMilliseconds}ms)');
      }
      return _handleResponse(response);
    } on SocketException {
      sw.stop();
      if (kDebugMode) debugPrint('[ApiService] ❌ Network error reaching $_base$path');
      throw Exception('Network error: Could not reach server. Please check your internet connection.');
    } on TimeoutException {
      sw.stop();
      if (kDebugMode) debugPrint('[ApiService] ❌ Timeout reaching $_base$path (${sw.elapsedMilliseconds}ms)');
      throw Exception('Server took too long to respond. Render free servers may take ~30s to wake up on first request.');
    } catch (e) {
      sw.stop();
      if (e is FormatException) {
        throw Exception('Invalid server response format.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final sw = Stopwatch()..start();
    final enrichedBody = {
      ...body,
      if (!body.containsKey('language') && !body.containsKey('lang')) 'language': _currentLang,
    };
    final headers = _jsonHeaders;

    if (kDebugMode) {
      debugPrint('[ApiService] ➡️ POST $_base$path | Lang: $_currentLang | ReqID: ${headers['X-Request-ID']}');
    }

    try {
      final response = await http
          .post(Uri.parse('$_base$path'), headers: headers, body: json.encode(enrichedBody))
          .timeout(timeout);
      sw.stop();
      if (kDebugMode) {
        debugPrint('[ApiService] ⬅️ [${response.statusCode}] POST $_base$path (${sw.elapsedMilliseconds}ms)');
      }
      return _handleResponse(response);
    } on SocketException {
      sw.stop();
      if (kDebugMode) debugPrint('[ApiService] ❌ Network error posting to $_base$path');
      throw Exception('Network error: Could not reach server. Please check your internet connection.');
    } on TimeoutException {
      sw.stop();
      if (kDebugMode) debugPrint('[ApiService] ❌ Timeout posting to $_base$path (${sw.elapsedMilliseconds}ms)');
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      sw.stop();
      if (e is FormatException) {
        throw Exception('Invalid server response format.');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded, 'status': 'Success'};
      }
      final errMsg = (decoded is Map)
          ? (decoded['error'] ?? decoded['message'] ?? 'Server error')
          : 'Unknown server error';
      throw Exception('Backend error ${response.statusCode}: $errMsg');
    } on FormatException {
      throw Exception('Backend returned status ${response.statusCode} with non-JSON body.');
    }
  }

  // ─── 1. Health Check ──────────────────────────────────────────
  /// GET /
  Future<Map<String, dynamic>> healthCheck() => _get('/');

  // ─── 2. Crop Analysis (Vision AI) ────────────────────────────
  /// POST /predict   multipart image upload → Gemini vision
  Future<Map<String, dynamic>> analyzeCrop(File imageFile, {String? language}) async {
    final sw = Stopwatch()..start();
    final targetLang = language ?? _currentLang;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_base/predict'));
      request.headers.addAll(_standardHeaders);
      request.fields['language'] = targetLang;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      if (kDebugMode) {
        debugPrint('[ApiService] ➡️ Uploading Crop Image to $_base/predict | Lang: $targetLang');
      }

      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      sw.stop();
      if (kDebugMode) {
        debugPrint('[ApiService] ⬅️ [${response.statusCode}] /predict completed in ${sw.elapsedMilliseconds}ms');
      }
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Network error during image upload. Check internet connectivity.');
    } on TimeoutException {
      throw Exception('Crop analysis timed out. Gemini AI vision inference took too long, please retry.');
    }
  }

  // ─── 3. Last Scan ─────────────────────────────────────────────
  /// GET /last-scan
  Future<Map<String, dynamic>> getLastScan() => _get('/last-scan');

  // ─── 4. Weather Advisory ──────────────────────────────────────
  /// GET /weather-advisory?lat=&lon=&lang=
  Future<Map<String, dynamic>> getWeather({
    double lat = 22.7196,
    double lon = 75.8577,
    String? language,
  }) =>
      _get('/weather-advisory', params: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'lang': language ?? _currentLang,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

  // ─── 5. Mandi Prices ──────────────────────────────────────────
  /// GET /mandi-prices
  Future<Map<String, dynamic>> getMandiPrices() => _get('/mandi-prices');

  // ─── 6. Soil Analysis (Vision AI) ────────────────────────────
  /// POST /analyze-soil   multipart image upload → Gemini vision
  Future<Map<String, dynamic>> analyzeSoil(File imageFile, {String? language}) async {
    final sw = Stopwatch()..start();
    final targetLang = language ?? _currentLang;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_base/analyze-soil'));
      request.headers.addAll(_standardHeaders);
      request.fields['language'] = targetLang;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      if (kDebugMode) {
        debugPrint('[ApiService] ➡️ Uploading Soil Image | Lang: $targetLang');
      }

      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      sw.stop();
      if (kDebugMode) {
        debugPrint('[ApiService] ⬅️ [${response.statusCode}] /analyze-soil completed in ${sw.elapsedMilliseconds}ms');
      }
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Network error during soil image upload. Check internet connectivity.');
    } on TimeoutException {
      throw Exception('Soil analysis timed out. Please retry with a clearer photo.');
    }
  }

  // ─── 7. Soil Plant Recommendations ───────────────────────────
  /// POST /soil-plant-recommendations   body: soil_data JSON
  Future<Map<String, dynamic>> getSoilPlantRecommendations(Map<String, dynamic> soilData, {String? language}) =>
      _post('/soil-plant-recommendations', {
        ...soilData,
        'language': language ?? _currentLang,
      });

  // ─── 8. Recovery Advice ───────────────────────────────────────
  /// POST /recovery-advice   body: scan data JSON → Gemini LLM
  Future<Map<String, dynamic>> getRecoveryAdvice(Map<String, dynamic> scanData, {String? language}) =>
      _post('/recovery-advice', {
        ...scanData,
        'language': language ?? _currentLang,
      }, timeout: const Duration(seconds: 60));

  // ─── 9. ROI Calculator ────────────────────────────────────────
  /// POST /roi-calculate   body: investment_amount, land_size, crop_name
  Future<Map<String, dynamic>> calculateRoi({
    required int investmentAmount,
    required double landSize,
    String cropName = 'General',
    String? language,
  }) =>
      _post('/roi-calculate', {
        'investment_amount': investmentAmount,
        'land_size': landSize,
        'crop_name': cropName,
        'language': language ?? _currentLang,
      }, timeout: const Duration(seconds: 60));

  // ─── 10. Market Predictions ───────────────────────────────────
  /// GET /market-predictions → Gemini LLM
  Future<Map<String, dynamic>> getMarketPredictions({String? language}) =>
      _get('/market-predictions', params: {'lang': language ?? _currentLang}, timeout: const Duration(seconds: 60));

  // ─── 11. AgriBot Chat ─────────────────────────────────────────
  /// POST /agri-chat   body: message, language, history → Gemini LLM
  Future<Map<String, dynamic>> agriChat({
    required String message,
    String? language,
    List<Map<String, String>> history = const [],
  }) =>
      _post('/agri-chat', {
        'message': message,
        'language': language ?? _currentLang,
        'history': history,
      }, timeout: const Duration(seconds: 45));

  // ─── 12. Government Schemes ───────────────────────────────────
  /// GET /govt-schemes
  Future<Map<String, dynamic>> getGovtSchemes() => _get('/govt-schemes');

  // ─── 13. Send Alert (Twilio + Gemini Voice) ───────────────────
  /// POST /send-alert
  Future<Map<String, dynamic>> sendAlert({
    String? phone,
    Map<String, dynamic>? scanData,
    String? message,
    String level = 'INFO',
  }) =>
      _post('/send-alert', {
        if (phone != null) 'phone': phone,
        if (scanData != null) 'scan_data': scanData,
        if (message != null) 'message': message,
        'level': level,
      });

  // ─── 14. Alert History ────────────────────────────────────────
  /// GET /alert-history?limit=50
  Future<Map<String, dynamic>> getAlertHistory({int limit = 50}) =>
      _get('/alert-history', params: {'limit': limit.toString()});

  // ─── 15. AI Model Info ────────────────────────────────────────
  /// GET /ai-info → returns active Gemini model details
  Future<Map<String, dynamic>> getAiInfo() => _get('/ai-info');
}
