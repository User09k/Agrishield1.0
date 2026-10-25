import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/weather_controller.dart';
import '../controllers/language_controller.dart';
import '../l10n/app_localizations.dart';
import 'spray_advisor_view.dart';

class Wx extends StatelessWidget {
  const Wx({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WeatherController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Obx(() {
        if (controller.isLoading.value && controller.weatherResult.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1565C0)),
                const SizedBox(height: 16),
                Text(l10n.connectingSatellite, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final data = controller.weatherResult.value;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(l10n.weatherUnavailable, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.fetchWeather,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchWeather,
          color: const Color(0xFF1565C0),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              // Live status bar
              _buildLiveBar(data.status, data.timestamp, controller),
              const SizedBox(height: 12),

              // Main Temperature Card
              _buildTempCard(data),
              const SizedBox(height: 14),

              // ── SMART SPRAY ADVISOR PROMO CARD ──
              GestureDetector(
                onTap: () => Get.to(() => const SprayAdvisorView()),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.smartSprayAdvisor,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('🌦️', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.safeSprayTimes,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Weather Stats Grid (4 tiles)
              _buildStatsGrid(data, l10n),
              const SizedBox(height: 14),

              // Weather Alerts
              if (data.alerts.isNotEmpty) ...[
                _buildAlertsSection(data.alerts, l10n),
                const SizedBox(height: 14),
              ],

              // Crop Impact
              _buildCropImpact(data.cropImpact, l10n),
              const SizedBox(height: 14),

              // Advisory
              _buildAdvisory(data.advisory, l10n),
              const SizedBox(height: 14),

              // Footer
              Center(
                child: Text(
                  "Powered by NASA POWER API • Auto-updates every 30s",
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ===================== LIVE BAR =====================
  Widget _buildLiveBar(String status, String time, WeatherController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ctrl.fetchWeather(),
            child: Icon(Icons.refresh, size: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ===================== MAIN TEMP CARD =====================
  Widget _buildTempCard(data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D47A1), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(
            data.condition,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "${data.temperature.toStringAsFixed(1)}°C",
            style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, height: 1),
          ),
          const SizedBox(height: 8),
          Text(
            data.date,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tempChip("🔺 Max", "${data.tempMax}°C"),
              const SizedBox(width: 20),
              _tempChip("🔻 Min", "${data.tempMin}°C"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tempChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ===================== STATS GRID =====================
  Widget _buildStatsGrid(data, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            _statTile("💧", l10n.humidity, "${data.humidity}%", Colors.blue),
            const SizedBox(width: 10),
            _statTile("🌧️", l10n.rainfall, "${data.rainfall.toStringAsFixed(1)} mm", Colors.indigo),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile("☀️", l10n.solar, "${data.solarRadiation.toStringAsFixed(1)} kWh/m²", Colors.orange),
            const SizedBox(width: 10),
            _statTile("💨", l10n.wind, "${data.windSpeed.toStringAsFixed(1)} m/s", Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String emoji, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ALERTS =====================
  Widget _buildAlertsSection(List alerts, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(l10n.weatherAlerts, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map((a) => _alertRow(a)),
        ],
      ),
    );
  }

  Widget _alertRow(alert) {
    Color color;
    IconData icon;
    switch (alert.type) {
      case 'danger':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'safe':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== CROP IMPACT =====================
  Widget _buildCropImpact(cropImpact, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, size: 18, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(l10n.cropImpactAssessment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _impactTile(l10n.growth, cropImpact.growthSpeed, _getImpactColor(cropImpact.growthSpeed)),
              const SizedBox(width: 8),
              _impactTile(l10n.diseaseRisk, cropImpact.diseaseRisk, _getRiskColor(cropImpact.diseaseRisk)),
              const SizedBox(width: 8),
              _impactTile(l10n.irrigation, cropImpact.irrigationNeed, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Color _getImpactColor(String val) {
    switch (val) {
      case 'Optimal': return Colors.green;
      case 'Good': return Colors.lightGreen;
      case 'Stressed': return Colors.red;
      default: return Colors.orange;
    }
  }

  Color _getRiskColor(String val) {
    switch (val) {
      case 'High': return Colors.red;
      case 'Moderate': return Colors.orange;
      default: return Colors.green;
    }
  }

  Widget _impactTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ===================== ADVISORY =====================
  Widget _buildAdvisory(String advisory, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                l10n.smartAdvisory,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber[800]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            advisory,
            style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }
}
