import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../controllers/language_controller.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.reports),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => LanguageController.showLanguageBottomSheet(context),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green))
            : RefreshIndicator(
                onRefresh: () => controller.loadAllData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Overview Stats ──
                      _buildOverviewStats(controller),
                      const SizedBox(height: 20),

                      // ── Last Scan Summary ──
                      _buildLastScanCard(controller),
                      const SizedBox(height: 20),

                      // ── Alert Timeline ──
                      _buildAlertTimeline(controller),
                      const SizedBox(height: 20),

                      // ── Crop Scan History ──
                      _buildCropHistory(controller),
                      const SizedBox(height: 20),

                      // ── Soil History ──
                      _buildSoilHistory(controller),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewStats(ReportsController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Dashboard Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                    '🔍',
                    'Scans',
                    c.totalScans.value.toString(),
                    Colors.white),
              ),
              Expanded(
                child: _miniStat(
                    '❤️',
                    'Avg Health',
                    '${c.avgHealthScore.value.toStringAsFixed(0)}%',
                    c.avgHealthScore.value >= 60
                        ? Colors.greenAccent
                        : Colors.redAccent),
              ),
              Expanded(
                child: _miniStat(
                    '🦠',
                    'Diseases',
                    c.diseasesDetected.value.toString(),
                    Colors.white),
              ),
              Expanded(
                child: _miniStat(
                    '🔔',
                    'Alerts',
                    c.totalAlerts.value.toString(),
                    Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildLastScanCard(ReportsController c) {
    final scan = c.lastScan.value;
    if (scan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          children: [
            Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No scans done yet',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final health = scan['health_score'] ?? 0;
    final crop = scan['crop_name'] ?? 'Unknown';
    final disease = scan['disease'] ?? 'No disease';
    final harvDays = scan['harvest_days'] ?? 0;

    Color healthColor = health >= 70
        ? Colors.green
        : health >= 40
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌿 Last Crop Scan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Health circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: healthColor.withOpacity(0.1),
                  border: Border.all(color: healthColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '$health',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: healthColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('🦠 $disease',
                        style: TextStyle(
                            fontSize: 13,
                            color: disease.toLowerCase() ==
                                    'no disease detected'
                                ? Colors.green
                                : Colors.red)),
                    Text('📅 Harvest in $harvDays days',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTimeline(ReportsController c) {
    if (c.alertHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔔 Alert Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...c.alertHistory.take(10).map((alert) {
            final level = alert['alert_level'] ?? 'INFO';
            final type = alert['type'] ?? '';
            final crop = alert['crop_name'] ?? alert['soil_type'] ?? '';
            final time = alert['timestamp'] ?? '';
            final actions = (alert['actions'] as List?)?.join(', ') ?? '';

            Color levelColor = level == 'CRITICAL'
                ? Colors.red
                : level == 'WARNING'
                    ? Colors.orange
                    : Colors.green;
            IconData levelIcon = level == 'CRITICAL'
                ? Icons.error
                : level == 'WARNING'
                    ? Icons.warning_rounded
                    : Icons.check_circle;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: levelColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(levelIcon, color: levelColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$level • $type ${crop.isNotEmpty ? "— $crop" : ""}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: levelColor,
                          ),
                        ),
                        if (actions.isNotEmpty)
                          Text('📤 $actions',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                        Text(
                          time.length > 16 ? time.substring(0, 16) : time,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCropHistory(ReportsController c) {
    if (c.cropScans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌾 Crop Scan History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...c.cropScans.take(5).map((scan) {
            final crop = scan['crop_name'] ?? 'Unknown';
            final health = scan['health_score'] ?? 0;
            final disease = scan['disease'] ?? '';
            Color hc = health >= 70
                ? Colors.green
                : health >= 40
                    ? Colors.orange
                    : Colors.red;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('$health',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hc,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crop,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(disease,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSoilHistory(ReportsController c) {
    if (c.soilAnalyses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌍 Soil Analysis History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...c.soilAnalyses.take(5).map((soil) {
            final soilType = soil['soil_type'] ?? 'Unknown';
            final ph = soil['ph']?.toString() ?? 'N/A';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('🌍', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(soilType,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('pH: $ph',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
