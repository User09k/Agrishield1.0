import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/market_predictor_controller.dart';
import '../controllers/language_controller.dart';

class MarketPredictorView extends StatelessWidget {
  const MarketPredictorView({super.key});

  static const _neonGreen = Color(0xFF00FF87);
  static const _darkBg = Color(0xFF0A0E21);
  static const _cardBg = Color(0xFF1A1F38);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MarketPredictorController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_neonGreen.withOpacity(0.3), _neonGreen.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _neonGreen.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: _neonGreen.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_graph, color: _neonGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(l10n.marketPriceForecast,
                      style: const TextStyle(
                          color: _neonGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D1229),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white70),
            color: _cardBg,
            onSelected: (v) {
              if (v == 'demand') c.sortByDemand();
              if (v == 'growth') c.sortByGrowth();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'demand',
                child: Text('Sort by Demand', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'growth',
                child: Text('Sort by Growth', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          IconButton(
            onPressed: () => c.fetchPredictions(),
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
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: _neonGreen,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('AI predicting market trends...',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 6),
                Text('Analyzing demand for high-value crops',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ],
            ),
          );
        }

        if (c.predictions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📈', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                const Text('No predictions available',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => c.fetchPredictions(),
                  style: ElevatedButton.styleFrom(backgroundColor: _neonGreen),
                  child: const Text('Retry', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: c.predictions.length,
          itemBuilder: (context, index) {
            final crop = c.predictions[index];
            return _buildCropCard(crop, index);
          },
        );
      }),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop, int index) {
    final demandScore = (crop['demand_score'] ?? 0).toDouble();
    final growthPercent = (crop['price_growth_percent'] ?? 0).toDouble();
    final trend = (crop['quarterly_trend'] as List?)?.cast<num>() ?? [];
    final category = crop['category']?.toString() ?? '';

    // Category emoji
    String emoji = '🌾';
    if (category.contains('Fruit')) emoji = '🍎';
    if (category.contains('Spice')) emoji = '🌶️';
    if (category.contains('Herb') || category.contains('Medicinal')) emoji = '🌿';
    if (category.contains('Vegetable')) emoji = '🥬';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: _neonGreen.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Emoji Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _neonGreen.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),

              // Name + Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop['crop_name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (crop['crop_name_hindi'] != null)
                      Text(
                        crop['crop_name_hindi'].toString(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10)),
                    ),
                  ],
                ),
              ),

              // Demand Score Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _neonGreen.withOpacity(0.3),
                      _neonGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neonGreen.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: _neonGreen.withOpacity(0.15), blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      demandScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _neonGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('/10',
                        style: TextStyle(
                            color: _neonGreen.withOpacity(0.6), fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price Row
          Row(
            children: [
              _priceTag('Current', '₹${crop['current_price_per_kg'] ?? 0}/kg',
                  Colors.white70),
              const SizedBox(width: 12),
              _priceTag('Predicted',
                  '₹${crop['predicted_price_per_kg'] ?? 0}/kg', _neonGreen),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthPercent > 0
                      ? _neonGreen.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      growthPercent > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: growthPercent > 0 ? _neonGreen : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growthPercent > 0 ? '+' : ''}${growthPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: growthPercent > 0 ? _neonGreen : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini Line Graph
          if (trend.isNotEmpty)
            SizedBox(
              height: 40,
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _MiniGraphPainter(trend, _neonGreen),
              ),
            ),

          const SizedBox(height: 10),

          // Why Trending
          if (crop['why_trending'] != null)
            Text(
              crop['why_trending'].toString(),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),

          // Investment Info
          const SizedBox(height: 8),
          Row(
            children: [
              _miniStat('💰', '₹${_formatK(crop['investment_per_acre'] ?? 0)}/acre', 'Invest'),
              const SizedBox(width: 12),
              _miniStat('📈', '₹${_formatK(crop['profit_per_acre'] ?? 0)}/acre', 'Profit'),
              const SizedBox(width: 12),
              if (crop['best_states'] is List)
                Expanded(
                  child: Text(
                    '📍 ${(crop['best_states'] as List).join(', ')}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceTag(String label, String price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 10)),
        Text(price,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _miniStat(String icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatK(dynamic n) {
    final num = int.tryParse(n.toString()) ?? 0;
    if (num >= 100000) return '${(num / 100000).toStringAsFixed(1)}L';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(0)}K';
    return num.toString();
  }
}

/// Mini Line Graph Painter
class _MiniGraphPainter extends CustomPainter {
  final List<num> data;
  final Color color;

  _MiniGraphPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce(math.min).toDouble();
    final maxVal = data.reduce(math.max).toDouble();
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height * 0.8 - size.height * 0.1;
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = color);
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);
    }

    // Quarter labels
    final labels = ['Q1', 'Q2', 'Q3', 'Next'];
    for (int i = 0; i < math.min(labels.length, data.length); i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
