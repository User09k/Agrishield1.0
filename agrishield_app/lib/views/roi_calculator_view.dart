import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/roi_controller.dart';
import '../controllers/language_controller.dart';

class RoiCalculatorView extends StatelessWidget {
  const RoiCalculatorView({super.key});

  // Colors
  static const _emerald = Color(0xFF2E7D32);
  static const _pieColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RoiController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(l10n.roiCalculator),
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: l10n.language,
            onPressed: () => LanguageController.showLanguageBottomSheet(context),
          ),
        ],
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Investment Slider ──
              _buildSliderCard(
                title: '💰 Investment Amount',
                value: c.investmentAmount.value,
                min: 10000,
                max: 500000,
                divisions: 49,
                format: '₹${c.investmentAmount.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                onChanged: (v) => c.updateInvestment(v),
                color: _emerald,
              ),
              const SizedBox(height: 12),

              // ── Land Size Slider ──
              _buildSliderCard(
                title: '🌾 Land Size (Acres)',
                value: c.landSize.value,
                min: 1,
                max: 50,
                divisions: 49,
                format: '${c.landSize.value.toStringAsFixed(1)} Acres',
                onChanged: (v) => c.updateLandSize(v),
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(height: 12),

              // ── Calculate Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: c.isLoading.value ? null : () => c.calculateRoi(),
                  icon: c.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.calculate_rounded),
                  label: Text(c.isLoading.value ? 'Calculating...' : 'Calculate ROI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── ROI Pie Chart ──
              if (c.hasData.value) ...[
                _buildPieChart(c),
                const SizedBox(height: 20),

                // ── Summary Stats ──
                _buildSummaryStats(c),
                const SizedBox(height: 20),

                // ── ROI Breakdown List ──
                _buildBreakdownList(c),
                const SizedBox(height: 20),

                // ── Tips ──
                _buildTips(c),
                const SizedBox(height: 30),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String format,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(format,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              inactiveTrackColor: color.withOpacity(0.15),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Custom Pie Chart
  Widget _buildPieChart(RoiController c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('📊 Profit Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _PieChartPainter(c.roiBreakdown, _pieColors),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${c.totalRoiPercent.value}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: _emerald)),
                        const Text('ROI',
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: c.roiBreakdown.asMap().entries.map((e) {
              final color = _pieColors[e.key % _pieColors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.value['category']?.toString().split('(').first.trim() ?? ''} (${e.value['allocation_percent'] ?? 0}%)',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Summary Stats
  Widget _buildSummaryStats(RoiController c) {
    return Row(
      children: [
        _summaryCard(
          '₹${_formatNum(c.totalExpectedReturn.value)}',
          'Expected Return',
          Icons.trending_up,
          _emerald,
        ),
        const SizedBox(width: 12),
        _summaryCard(
          '${c.paybackMonths.value} mo',
          'Payback Period',
          Icons.timer,
          const Color(0xFF1565C0),
        ),
        const SizedBox(width: 12),
        _summaryCard(
          c.riskLevel.value,
          'Risk Level',
          Icons.shield,
          c.riskLevel.value == 'Low'
              ? _emerald
              : c.riskLevel.value == 'High'
                  ? Colors.red
                  : Colors.orange,
        ),
      ],
    );
  }

  Widget _summaryCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Breakdown List
  Widget _buildBreakdownList(RoiController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Detailed Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...c.roiBreakdown.asMap().entries.map((e) {
            final item = e.value;
            final color = _pieColors[e.key % _pieColors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('${item['allocation_percent'] ?? 0}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['category']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                            'Invest: ₹${_formatNum(item['investment_amount'] ?? 0)} → Return: ₹${_formatNum(item['expected_return'] ?? 0)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item['roi_percent'] ?? 0}% ROI',
                      style: const TextStyle(
                          color: _emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
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

  /// Tips
  Widget _buildTips(RoiController c) {
    if (c.tips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Smart Tips',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...c.tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ ', style: TextStyle(fontSize: 12)),
                    Expanded(
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatNum(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

/// Custom Pie Chart Painter
class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final List<Color> colors;

  _PieChartPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final percent = (data[i]['allocation_percent'] ?? 0) / 100;
      final sweepAngle = 2 * math.pi * percent;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Neon border glow
      final borderPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
