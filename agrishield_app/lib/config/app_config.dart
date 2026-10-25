import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// AgriShield AI — Central Backend Configuration
/// =============================================
/// Single source-of-truth for backend connectivity across the entire Flutter app.
class AppConfig {
  /// Local PC Wi-Fi IP (Accessible by physical phone on same Wi-Fi)
  static const String localWifiUrl = 'http://10.125.226.46:5000';

  /// Local USB port reverse (adb reverse tcp:5000 tcp:5000)
  static const String localUsbUrl = 'http://127.0.0.1:5000';

  /// Android Emulator Loopback
  static const String emulatorUrl = 'http://10.0.2.2:5000';

  /// Live Production Render Backend URL (HTTPS)
  static const String productionBaseUrl = 'https://agrishiedai-backend.onrender.com';

  /// Storage key for remembered working backend URL
  static const String _storageKey = 'agrishield_backend_base_url';

  /// Compile-time environment override
  static const String _backendBaseUrlOverride = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String? _resolvedBaseUrl;

  static const String _manualKey = 'agrishield_backend_is_manual';

  /// Candidate list to try during auto-discovery in priority order
  static List<String> get candidateUrls => [
    if (_backendBaseUrlOverride.isNotEmpty) _backendBaseUrlOverride,
    localUsbUrl,
    localWifiUrl,
    emulatorUrl,
    productionBaseUrl,
  ];

  /// Central base URL used by all controllers, views, and services.
  static String get baseUrl {
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      return _resolvedBaseUrl!;
    }
    if (_backendBaseUrlOverride.isNotEmpty) {
      return _backendBaseUrlOverride;
    }
    try {
      final box = GetStorage();
      final bool isManual = box.read<bool>(_manualKey) ?? false;
      if (isManual) {
        final saved = box.read<String>(_storageKey);
        if (saved != null && saved.isNotEmpty) {
          _resolvedBaseUrl = saved;
          return saved;
        }
      }
    } catch (_) {}

    return localUsbUrl;
  }

  /// Manually update the base URL at runtime (e.g. for testing / custom servers)
  static void setBaseUrl(String url, {bool isManual = false}) {
    _resolvedBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final box = GetStorage();
      box.write(_storageKey, _resolvedBaseUrl);
      if (isManual) {
        box.write(_manualKey, true);
      }
    } catch (_) {}
    debugPrint('[AppConfig] Backend URL active: $_resolvedBaseUrl');
  }

  /// Connection timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration requestTimeout = Duration(seconds: 45);
  static const Duration uploadTimeout = Duration(seconds: 90);

  /// Initializes and verifies connectivity to the backend.
  /// Prioritizes local PC backend (USB 127.0.0.1 or Wi-Fi 10.125.226.46)
  /// and only falls back to cloud Render if local is unreachable.
  static Future<String> autoDiscoverBackend() async {
    if (_backendBaseUrlOverride.isNotEmpty) {
      _resolvedBaseUrl = _backendBaseUrlOverride;
      return _backendBaseUrlOverride;
    }

    final box = GetStorage();
    final bool isManual = box.read<bool>(_manualKey) ?? false;
    if (isManual) {
      final saved = box.read<String>(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        try {
          final resp = await http
              .get(Uri.parse('$saved/'))
              .timeout(const Duration(milliseconds: 700));
          if (resp.statusCode == 200) {
            _resolvedBaseUrl = saved;
            debugPrint('[AppConfig] Using manually selected backend: $saved');
            return saved;
          }
        } catch (_) {
          debugPrint('[AppConfig] Saved manual backend ($saved) not reachable, discovering...');
        }
      }
    }

    debugPrint('[AppConfig] Probing for active backend...');

    // 1. Probe local servers (USB adb reverse first, then Wi-Fi, then Emulator)
    final localCandidates = [localUsbUrl, localWifiUrl, emulatorUrl];
    for (final candidate in localCandidates) {
      try {
        final resp = await http
            .get(Uri.parse('$candidate/'))
            .timeout(const Duration(milliseconds: 650));
        if (resp.statusCode == 200) {
          setBaseUrl(candidate, isManual: false);
          debugPrint('[AppConfig] 🟢 Connected to LOCAL PC backend: $candidate');
          return candidate;
        }
      } catch (_) {
        // Continue to next local candidate
      }
    }

    // 2. Only if local is unreachable, fallback to cloud Render
    try {
      final resp = await http
          .get(Uri.parse('$productionBaseUrl/'))
          .timeout(const Duration(milliseconds: 1500));
      if (resp.statusCode == 200) {
        setBaseUrl(productionBaseUrl, isManual: false);
        debugPrint('[AppConfig] ☁️ Local PC offline. Connected to Render Cloud: $productionBaseUrl');
        return productionBaseUrl;
      }
    } catch (_) {}

    setBaseUrl(localUsbUrl, isManual: false);
    debugPrint('[AppConfig] Defaulting to local USB backend: $localUsbUrl');
    return localUsbUrl;
  }

  /// Helper UI Dialog to view or switch backend URL anytime from inside the app
  static void showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.dns_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 10),
            Text('Backend Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Backend URL:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip(ctx, controller, 'Local Wi-Fi', localWifiUrl),
                _presetChip(ctx, controller, 'USB (adb)', localUsbUrl),
                _presetChip(ctx, controller, 'Cloud Render', productionBaseUrl),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                setBaseUrl(newUrl, isManual: true);
                Navigator.pop(ctx);
                Get.snackbar(
                  'Server Updated',
                  'Connecting to $newUrl',
                  backgroundColor: const Color(0xFF2E7D32),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save & Connect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Widget _presetChip(BuildContext ctx, TextEditingController ctrl, String label, String url) {
    final isSelected = ctrl.text == url;
    return InkWell(
      onTap: () => ctrl.text = url,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ),
    );
  }
}

