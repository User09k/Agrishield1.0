import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/recovery_controller.dart';
import '../controllers/language_controller.dart';

class RecoveryDashboardView extends StatelessWidget {
  const RecoveryDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RecoveryController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text(l10n.recoveryAdvisor),
        backgroundColor: const Color(0xFF1A2A44),
        foregroundColor: Colors.white,
        elevation: 0,
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
          IconButton(
            onPressed: () => c.fetchRecoveryAdvice(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00E676)),
                const SizedBox(height: 16),
                Text(l10n.aiAnalyzingRecovery,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        if (!c.hasData.value && c.damagePercent.value <= 50) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cropHealthGood,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recovery Advisor activates when crop damage exceeds 50%.\nCurrent damage: ${c.damagePercent.value}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (!c.hasData.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔄', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                const Text('Loading recovery data...',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => c.fetchRecoveryAdvice(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676)),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Damage Gauge ──
              _buildDamageGauge(c),
              const SizedBox(height: 20),

              // ── AI Pivot Card (Glassmorphism) ──
              _buildPivotCard(c),
              const SizedBox(height: 20),

              // ── Loss vs Profit Bar Chart ──
              _buildComparisonChart(c),
              const SizedBox(height: 20),

              // ── Alternative Options ──
              _buildAlternatives(c),
              const SizedBox(height: 20),

              // ── Immediate Steps ──
              _buildSteps(c),
              const SizedBox(height: 20),

              // ── Govt Schemes ──
              _buildSchemes(c),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  /// Semi-circular gauge meter
  Widget _buildDamageGauge(RecoveryController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A44),
            const Color(0xFF0D2137).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            '⚠️ Crop Damage Assessment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(c.damagePercent.value.toDouble()),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${c.damagePercent.value}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: c.damagePercent.value > 70
                              ? const Color(0xFFFF1744)
                              : const Color(0xFFFF9100),
                        ),
                      ),
                      const Text(
                        'Crop Damage',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip('🌾', c.cropName.value, const Color(0xFF00E676)),
              const SizedBox(width: 12),
              _infoChip('🦠', c.disease.value, const Color(0xFFFF5252)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$emoji $text',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Glassmorphism Pivot Card
  Widget _buildPivotCard(RecoveryController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high,
                    color: Color(0xFF00E676), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🤖 AI Business Pivot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00E676).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.pivotTitle.value,
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.pivotDescription.value,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox('⏱️', '${c.recoveryDays.value} days', 'Recovery Time'),
              const SizedBox(width: 10),
              _statBox('📊', c.damageLevel.value, 'Damage Level'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  /// Comparison Bar Chart
  Widget _buildComparisonChart(RecoveryController c) {
    final maxVal = math.max(
            c.lossWithoutPivot.value, c.projectedProfit.value)
        .toDouble();
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Financial Comparison',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Loss bar
          _animatedBar(
            label: 'Loss without Pivot',
            value: c.lossWithoutPivot.value,
            maxValue: maxVal,
            color: const Color(0xFFFF1744),
            icon: '📉',
          ),
          const SizedBox(height: 16),
          // Profit bar
          _animatedBar(
            label: 'Projected Profit with Pivot',
            value: c.projectedProfit.value,
            maxValue: maxVal,
            color: const Color(0xFF00E676),
            icon: '📈',
          ),
        ],
      ),
    );
  }

  Widget _animatedBar({
    required String label,
    required int value,
    required double maxValue,
    required Color color,
    required String icon,
  }) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$icon $label',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 32,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    '₹$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Alternative Options
  Widget _buildAlternatives(RecoveryController c) {
    if (c.alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔄 Alternative Options',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...c.alternatives.map((alt) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alt['name']?.toString() ?? '',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(alt['description']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _altStat(
                        '💰', '₹${alt['investment_required'] ?? 0}', 'Invest'),
                    _altStat(
                        '📈', '₹${alt['monthly_income'] ?? 0}/mo', 'Income'),
                    _altStat(
                        '⏱️', '${alt['setup_days'] ?? 0} days', 'Setup'),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _altStat(String icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
      ),
    );
  }

  /// Immediate Steps
  Widget _buildSteps(RecoveryController c) {
    if (c.immediateSteps.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚀 Immediate Steps',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...c.immediateSteps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Govt Schemes
  Widget _buildSchemes(RecoveryController c) {
    if (c.govtSchemes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏛️ Government Schemes',
              style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...c.govtSchemes.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFFFFD600), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Custom painter for semi-circular gauge
class _GaugePainter extends CustomPainter {
  final double percent;
  _GaugePainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: const [
          Color(0xFFFFD600),
          Color(0xFFFF9100),
          Color(0xFFFF1744),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepAngle = math.pi * (percent / 100).clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
