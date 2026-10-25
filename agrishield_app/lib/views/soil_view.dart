import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/soil_controller.dart';
import '../controllers/language_controller.dart';
import '../models/soil_model.dart';

class SoilView extends StatelessWidget {
  final bool showAppBar;
  const SoilView({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<SoilController>()
        ? Get.find<SoilController>()
        : Get.put(SoilController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      appBar: showAppBar
          ? AppBar(
              title: Text(l10n.soilAnalysis),
              backgroundColor: const Color(0xFF3E2723),
              foregroundColor: Colors.white,
              elevation: 2,
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
            )
          : null,
      body: Obx(() {
        if (c.isLoading.value) return _loading(c.loadingMsg.value);
        if (c.soilResult.value == null) return _placeholder(c);
        if (c.showSeasonSelection.value) return _seasonSelection(c);
        if (c.showFieldCapture.value) return _fieldCapture(c);
        if (c.analysisType.value == null) return _soilResult(c);
        if (c.analysisType.value == 'plant') return _plantList(c);
        return _cropList(c);
      }),
    );
  }

  // ═══════════════ LOADING ═══════════════
  Widget _loading(String msg) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withAlpha(25),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2E7D32), strokeWidth: 3)),
          ),
          const SizedBox(height: 24),
          Text(msg.isNotEmpty ? msg : 'Analyzing...',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32)),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('AI is examining the soil',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ]),
      );

  // ═══════════════ PLACEHOLDER ═══════════════
  Widget _placeholder(SoilController c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withAlpha(20),
                  borderRadius: BorderRadius.circular(60)),
              child: const Icon(Icons.landscape,
                  size: 60, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 24),
            const Text('🌍 Soil Analysis',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 10),
            Text(
                'Take a soil photo and let AI tell you\nwhich plants & crops grow best in it',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => c.showImagePicker(),
                icon: const Icon(Icons.camera_alt, size: 22),
                label: const Text('Scan Soil',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 3),
              ),
            ),
          ]),
        ),
      );

  // ═══════════════ SOIL RESULT + OPTIONS ═══════════════
  Widget _soilResult(SoilController c) {
    final s = c.soilResult.value!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF2E7D32).withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.check_circle, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text('Soil Analysis Complete',
                  style: TextStyle(fontSize: 13, color: Colors.white70))
            ]),
            const SizedBox(height: 10),
            Text('${s.soilType} (${s.soilTypeHindi})',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: s.healthScore / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(s.healthScore >= 70
                        ? Colors.greenAccent
                        : s.healthScore >= 40
                            ? Colors.orangeAccent
                            : Colors.redAccent))),
            const SizedBox(height: 6),
            Text('Health: ${s.healthScore}% — ${s.soilHealth}',
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 14),

        // Details grid
        GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              _detailCard('pH Level', s.pHLevel, Icons.science, Colors.blue),
              _detailCard(
                  'Texture', s.soilTexture, Icons.grain, Colors.brown),
              _detailCard(
                  'Moisture', s.moistureLevel, Icons.water_drop, Colors.cyan),
              _detailCard(
                  'Organic Matter', s.organicMatter, Icons.eco, Colors.green),
            ]),
        const SizedBox(height: 10),

        // NPK
        Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🧪 NPK Levels',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _npk('N', s.nitrogenLevel, Colors.blue),
                        const SizedBox(width: 8),
                        _npk('P', s.phosphorusLevel, Colors.orange),
                        const SizedBox(width: 8),
                        _npk('K', s.potassiumLevel, Colors.purple),
                      ]),
                    ]))),
        const SizedBox(height: 10),

        // Advisory
        Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            color: Colors.blue.shade50,
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text('Advisory',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue))
                      ]),
                      const SizedBox(height: 8),
                      Text(s.advisory,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              height: 1.4)),
                    ]))),
        const SizedBox(height: 20),

        // Options
        const Text('What would you like to know?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20))),
        const SizedBox(height: 4),
        Text('Get plant or crop recommendations',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 14),
        _optionCard(
            '🌱',
            'Plants',
            'Find the best plants for this soil\nFull details — age, growth, water, care, diseases',
            const Color(0xFF2E7D32),
            () => c.getPlantRecommendations()),
        const SizedBox(height: 12),
        _optionCard(
            '🌾',
            'Crops',
            'Take 3+ field photos for best crop suggestions\nYield, profit, advantages, disadvantages & more',
            const Color(0xFFE65100),
            () => c.startCropFlow()),
        const SizedBox(height: 12),
        Center(
            child: TextButton.icon(
                onPressed: () => c.resetAnalysis(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('New Scan'),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.grey[600]))),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ═══════════════ SEASON SELECTION ═══════════════
  Widget _seasonSelection(SoilController c) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(
              onPressed: () => c.backToSoilResult(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700])),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF8F00)]),
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('🌾 Select Season',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 6),
              Text(
                  'Which season crop do you want to plant?\nChoose the season for crop recommendations',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 20),

          // Winter / Rabi
          _seasonCard(
            emoji: '❄️',
            title: 'Winter (Rabi)',
            titleHindi: 'सर्दी की फसल',
            subtitle: 'Wheat, Mustard, Gram, Peas, Barley,\nLentil, Potato, Onion, Garlic, Carrot...',
            months: 'Oct – March',
            gradientColors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
            iconColor: const Color(0xFF1565C0),
            onTap: () => c.selectSeason('winter'),
          ),
          const SizedBox(height: 14),

          // Summer / Zaid
          _seasonCard(
            emoji: '☀️',
            title: 'Summer (Zaid)',
            titleHindi: 'गर्मी की फसल',
            subtitle: 'Watermelon, Muskmelon, Cucumber,\nMoong, Sunflower, Okra, Pumpkin...',
            months: 'March – June',
            gradientColors: const [Color(0xFFE65100), Color(0xFFFFB300)],
            iconColor: const Color(0xFFE65100),
            onTap: () => c.selectSeason('summer'),
          ),
          const SizedBox(height: 14),

          // Rainy / Kharif
          _seasonCard(
            emoji: '🌧️',
            title: 'Rainy (Kharif)',
            titleHindi: 'बारिश की फसल',
            subtitle: 'Rice, Maize, Soybean, Cotton,\nSugarcane, Bajra, Jowar, Arhar...',
            months: 'June – October',
            gradientColors: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            iconColor: const Color(0xFF2E7D32),
            onTap: () => c.selectSeason('rainy'),
          ),
          const SizedBox(height: 20),
        ]),
      );

  Widget _seasonCard({
    required String emoji,
    required String title,
    required String titleHindi,
    required String subtitle,
    required String months,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [gradientColors[0].withAlpha(20), gradientColors[1].withAlpha(15)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradientColors[0].withAlpha(60), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: gradientColors[0].withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gradientColors[0])),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: gradientColors[0].withAlpha(20),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(months,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: gradientColors[0])),
                  ),
                ]),
                Text(titleHindi,
                    style: TextStyle(
                        fontSize: 12, color: gradientColors[0].withAlpha(180))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.3)),
              ])),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios,
              size: 16, color: gradientColors[0]),
        ]),
      ),
    );
  }

  // ═══════════════ FIELD CAPTURE ═══════════════
  Widget _fieldCapture(SoilController c) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(
              onPressed: () => c.backToSoilResult(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700])),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF8F00)]),
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌾 Add Field Photos',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text(
                  'Take at least 3 photos from different angles of your field',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 10),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: c.fieldImages.length >= 3
                            ? Colors.green.shade600
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        c.fieldImages.length >= 3
                            ? '✅ ${c.fieldImages.length} photos — Ready!'
                            : '📸 ${c.fieldImages.length}/3 (min 3 needed)',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  )),
            ]),
          ),
          const SizedBox(height: 16),
          Obx(() => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8),
                itemCount: c.fieldImages.length + 1,
                itemBuilder: (_, i) {
                  if (i == c.fieldImages.length) {
                    return InkWell(
                      onTap: () => c.showFieldImagePicker(),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withAlpha(60), width: 2)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 28, color: Colors.orange[700]),
                              const SizedBox(height: 4),
                              Text('Add',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700]))
                            ]),
                      ),
                    );
                  }
                  return Stack(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(c.fieldImages[i],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover)),
                    Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                            onTap: () => c.removeFieldImage(i),
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white)))),
                    Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))),
                  ]);
                },
              )),
          const SizedBox(height: 20),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: c.fieldImages.length >= 3
                      ? () => c.analyzeCropWithFieldPhotos()
                      : null,
                  icon: const Icon(Icons.analytics, size: 22),
                  label: Text(
                      c.fieldImages.length >= 3
                          ? 'Analyze Crops 🚀'
                          : '${3 - c.fieldImages.length} more photos needed',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                ),
              )),
          const SizedBox(height: 16),
        ]),
      );

  // ═══════════════ PLANT LIST ═══════════════
  Widget _plantList(SoilController c) => Column(children: [
        _topBar(c, '🌱 Plant Recommendations'),
        Expanded(
          child: c.plantRecommendations.isEmpty
              ? const Center(child: Text('No recommendations found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: c.plantRecommendations.length,
                  itemBuilder: (ctx, i) {
                    final p = c.plantRecommendations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _openPlantDetail(ctx, p),
                        borderRadius: BorderRadius.circular(14),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color:
                                          _sColor(p.suitability).withAlpha(25),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Center(
                                      child: Text(
                                          p.plantType.toLowerCase() == 'flower' ? '🌸' : '🌱',
                                          style: const TextStyle(fontSize: 24)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(p.plantName,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(
                                        '${p.plantType} • ${p.growthDays} days • ${p.bestSeason}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                    const SizedBox(height: 3),
                                    Text(p.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500])),
                                  ])),
                              const SizedBox(width: 8),
                              Column(children: [
                                _badge(p.suitability),
                                const SizedBox(height: 4),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ]),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]);

  // ═══════════════ CROP LIST ═══════════════
  Widget _cropList(SoilController c) => Column(children: [
        _topBar(c, '🌾 Crop Recommendations'),
        Expanded(
          child: c.cropRecommendations.isEmpty
              ? const Center(child: Text('No recommendations found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: c.cropRecommendations.length,
                  itemBuilder: (ctx, i) {
                    final cr = c.cropRecommendations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _openCropDetail(ctx, cr),
                        borderRadius: BorderRadius.circular(14),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Center(
                                      child: Text('🌾',
                                          style: TextStyle(fontSize: 24)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(cr.cropName,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(
                                        '${cr.season} • ${cr.growthDurationDays} days • ${cr.expectedProfit}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                    const SizedBox(height: 3),
                                    Text(cr.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500])),
                                  ])),
                              const SizedBox(width: 8),
                              Column(children: [
                                _badge(cr.suitability),
                                const SizedBox(height: 4),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ]),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]);

  // ═══════════════ PLANT DETAIL PAGE ═══════════════
  void _openPlantDetail(BuildContext ctx, PlantRecommendation p) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFFF5F7F0),
        appBar: AppBar(
          title: Text(p.plantName),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF43A047)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('🌱', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.plantName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (p.plantNameHindi.isNotEmpty)
                      Text(p.plantNameHindi, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ])),
                  _badge(p.suitability),
                ]),
                const SizedBox(height: 14),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _tagWhite(p.plantType),
                  _tagWhite('${p.growthDays} days'),
                  _tagWhite(p.difficultyLevel),
                  _tagWhite(p.bestSeason),
                ]),
                const SizedBox(height: 10),
                Text(p.description, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 16),

            _section('📅 Growth Timeline & Age', p.plantAgeInfo),
            _section('☀️ Sunlight Needs', p.sunlightNeeds),
            _section('💧 Water Requirements', p.waterNeeds),
            _section('🧪 Fertilizer', p.fertilizerNeeds),
            _section('🌱 Soil Preparation', p.soilPreparation),
            _section('🌿 How to Plant', p.plantingMethod),
            _section('🦠 Common Diseases', p.commonDiseases),
            _section('🌾 Harvest Info', p.harvestInfo),

            if (p.careSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('📋 Care Steps'),
              ...p.careSteps.asMap().entries.map((e) => _listItem('${e.key + 1}. ${e.value}', Icons.check_circle, const Color(0xFF2E7D32))),
            ],

            if (p.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('✅ Advantages'),
              ...p.benefits.map((b) => _listItem(b, Icons.thumb_up, Colors.green)),
            ],

            const SizedBox(height: 24),
          ]),
        ),
      ),
    ));
  }

  // ═══════════════ CROP DETAIL PAGE ═══════════════
  void _openCropDetail(BuildContext ctx, CropRecommendation cr) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFFF5F7F0),
        appBar: AppBar(
          title: Text(cr.cropName),
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFBF360C), Color(0xFFFF6D00)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('🌾', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cr.cropName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (cr.cropNameHindi.isNotEmpty)
                      Text(cr.cropNameHindi, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ])),
                  _badge(cr.suitability),
                ]),
                const SizedBox(height: 14),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _tagWhite(cr.season),
                  _tagWhite('${cr.growthDurationDays} days'),
                  _tagWhite(cr.expectedProfit),
                ]),
                const SizedBox(height: 10),
                Text(cr.description, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 16),

            _section('📅 Best Planting Month', cr.bestPlantingMonth),
            _section('🌱 Growth Stages & Age', cr.cropAgeStages),
            _section('🌾 Seed Quantity', cr.seedQuantity),
            _section('🧪 Fertilizer Schedule', cr.fertilizerSchedule),
            _section('💧 Irrigation Schedule', cr.irrigationSchedule),
            _section('🐛 Pesticide Needs', cr.pesticideNeeds),
            _section('🌿 Weed Management', cr.weedManagement),
            _section('📊 Expected Yield', cr.expectedYield),
            _section('💰 Expected Profit', cr.expectedProfit),
            _section('🌾 Harvest Method', cr.harvestMethod),
            _section('📈 Market Demand', cr.marketDemand),

            if (cr.soilPreparationSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('🚜 Soil Preparation Steps'),
              ...cr.soilPreparationSteps.asMap().entries.map((e) => _listItem('${e.key + 1}. ${e.value}', Icons.agriculture, const Color(0xFFE65100))),
            ],

            if (cr.growthRequirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('📝 Growth Requirements'),
              ...cr.growthRequirements.map((r) => _listItem(r, Icons.check_circle, Colors.blue)),
            ],

            if (cr.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('✅ Advantages'),
              ...cr.benefits.map((b) => _listItem(b, Icons.thumb_up, Colors.green)),
            ],

            if (cr.drawbacks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('⚠️ Disadvantages'),
              ...cr.drawbacks.map((d) => _listItem(d, Icons.warning_amber, Colors.red)),
            ],

            const SizedBox(height: 24),
          ]),
        ),
      ),
    ));
  }

  // ═══════════════ HELPERS ═══════════════
  Widget _topBar(SoilController c, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 4),
        child: Row(children: [
          IconButton(
              onPressed: () => c.backToSoilResult(),
              icon: const Icon(Icons.arrow_back)),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold))),
          TextButton.icon(
              onPressed: () => c.resetAnalysis(),
              icon: const Icon(Icons.refresh, size: 15),
              label:
                  const Text('New Scan', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600])),
        ]),
      );

  Widget _detailCard(
          String title, String value, IconData icon, Color color) =>
      Card(
        elevation: 1,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: color),
                  const SizedBox(height: 4),
                  Text(title,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ])),
      );

  Widget _npk(String label, String level, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(50))),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(level,
                style: TextStyle(fontSize: 11, color: color.withAlpha(200)))
          ]),
        ),
      );

  Widget _optionCard(String emoji, String title, String subtitle, Color color,
          VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50))),
          child: Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          height: 1.3)),
                ])),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ]),
        ),
      );

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _sColor(text), borderRadius: BorderRadius.circular(16)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );

  Color _sColor(String s) => s.toLowerCase() == 'excellent'
      ? const Color(0xFF2E7D32)
      : s.toLowerCase() == 'good'
          ? Colors.orange
          : Colors.amber.shade700;

  Widget _tagWhite(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      );

  Widget _section(String title, String value) {
    if (value == 'N/A' || value.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[700], height: 1.4)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF37474F))),
      );

  Widget _listItem(String text, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, height: 1.3))),
        ]),
      );
}
