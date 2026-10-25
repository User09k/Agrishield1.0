import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../controllers/language_controller.dart';

class SprayAdvisorView extends StatefulWidget {
  const SprayAdvisorView({super.key});

  @override
  State<SprayAdvisorView> createState() => _SprayAdvisorViewState();
}

class _SprayAdvisorViewState extends State<SprayAdvisorView> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _advisorData;

  static const _primaryGreen = Color(0xFF1B5E20);
  static const _accentGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _fetchSprayAdvisory();
  }

  Future<void> _fetchSprayAdvisory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final lang = LanguageController.currentLang;
      final url = Uri.parse('${AppConfig.baseUrl}/spray-advisor?lat=22.7196&lon=75.8577&lang=$lang');
      final resp = await http.get(
        url,
        headers: {
          'Accept-Language': lang,
          'X-App-Language': lang,
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body['status'] == 'Success' && body['data'] != null) {
          setState(() {
            _advisorData = body['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = 'Unable to fetch weather forecast. Please check your connection and try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection error: $e';
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return _accentGreen;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              l10n.smartSprayAdvisor,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              l10n.sprayAdvisorSubtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: l10n.language,
            onPressed: () => LanguageController.showLanguageBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: _fetchSprayAdvisory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _accentGreen),
            const SizedBox(height: 16),
            Text(
              l10n.analyzingWeatherConditions,
              style: const TextStyle(color: _accentGreen, fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchSprayAdvisory,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final curr = _advisorData?['current_status'] ?? {};
    final nextWin = _advisorData?['next_best_window'] ?? {};
    final timeline = (_advisorData?['timeline'] as List?) ?? [];
    final guidelines = (_advisorData?['guidelines'] as List?) ?? [];

    final statusColor = _parseColor(curr['color']);
    final isSafe = curr['status'] == 'SAFE';

    return RefreshIndicator(
      onRefresh: _fetchSprayAdvisory,
      color: _accentGreen,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── 1. Hero Current Status Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSafe
                    ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
                    : (curr['status'] == 'DANGER'
                        ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
                        : [const Color(0xFFE65100), const Color(0xFFFB8C00)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            l10n.currentCondition,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      curr['icon'] ?? '🟢',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  curr['status_text'] ?? l10n.optimalForSpraying,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  curr['reason'] ?? l10n.calmConditions,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.92),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetric(Icons.thermostat, '${curr['temperature'] ?? '--'}°C', l10n.temp)),
                      Container(width: 1, height: 28, color: Colors.white24),
                      Expanded(child: _buildMetric(Icons.air, '${curr['wind_speed'] ?? '--'} km/h', l10n.wind)),
                      Container(width: 1, height: 28, color: Colors.white24),
                      Expanded(child: _buildMetric(Icons.water_drop, '${curr['humidity'] ?? '--'}%', l10n.humidity)),
                      Container(width: 1, height: 28, color: Colors.white24),
                      Expanded(child: _buildMetric(Icons.umbrella, '${curr['rain_prob'] ?? '0'}%', l10n.rainRisk)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Next Best Window Banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF81C784).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 26),
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
                              l10n.nextSafeWindow,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nextWin['badge'] ?? '🟢 ${l10n.optimalWindow}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextWin['title'] ?? 'Tomorrow 07:00 AM to 10:00 AM',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nextWin['description'] ?? l10n.calmConditions,
                        style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 3. 24-Hour Spray Timeline ──
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.hourlySprayTimeline,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final item = timeline[index];
                final itemColor = _parseColor(item['color']);
                final dayLabel = item['day_label'] ?? 'Today';
                return Container(
                  width: 136,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: itemColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$dayLabel ${item['hour_label']}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['icon'] ?? '🟢',
                        style: const TextStyle(fontSize: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['status_en'] ?? 'Safe',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: itemColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.air, size: 12, color: Colors.blueGrey),
                              const SizedBox(width: 2),
                              Text('${item['wind_speed']}k', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.umbrella, size: 12, color: Colors.blue),
                              const SizedBox(width: 2),
                              Text('${item['rain_prob']}%', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          // ── 4. Golden Guidelines for Spraying ──
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.goldenRulesForSpraying,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...guidelines.map((g) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['icon'] ?? '💡', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['title'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryGreen),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            g['desc'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
