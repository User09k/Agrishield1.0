import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../controllers/language_controller.dart';

class FertilizerPrescriptionView extends StatefulWidget {
  const FertilizerPrescriptionView({super.key});

  @override
  State<FertilizerPrescriptionView> createState() => _FertilizerPrescriptionViewState();
}

class _FertilizerPrescriptionViewState extends State<FertilizerPrescriptionView> {
  final _landController = TextEditingController(text: '2.0');
  double _cropAgeDays = 25.0;
  String _selectedCrop = 'Wheat';
  String _selectedUnit = 'Acre';

  final List<String> _cropOptions = [
    'Wheat',
    'Rice / Paddy',
    'Soybean',
    'Cotton',
    'Maize (Corn)',
    'Mustard',
  ];

  final List<String> _unitOptions = [
    'Acre',
    'Bigha',
    'Hectare',
  ];

  bool _isGenerating = false;
  Map<String, dynamic>? _prescriptionData;

  static const _primaryGreen = Color(0xFF1B5E20);
  static const _accentGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _generatePrescription();
  }

  @override
  void dispose() {
    _landController.dispose();
    super.dispose();
  }

  String _cleanCropName(String raw) {
    if (raw.contains('/')) return raw.split('/')[0].trim().toLowerCase();
    if (raw.contains('(')) return raw.split('(')[0].trim().toLowerCase();
    return raw.trim().toLowerCase();
  }

  Future<void> _generatePrescription() async {
    setState(() {
      _isGenerating = true;
    });

    final landVal = double.tryParse(_landController.text) ?? 1.0;
    final cropClean = _cleanCropName(_selectedCrop);

    try {
      final lang = LanguageController.currentLang;
      final url = Uri.parse('${AppConfig.baseUrl}/fertilizer-prescription');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': lang,
          'X-App-Language': lang,
        },
        body: json.encode({
          'crop_name': cropClean,
          'land_size': landVal,
          'unit': _selectedUnit,
          'crop_age_days': _cropAgeDays.toInt(),
          'language': lang,
        }),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body['status'] == 'Success' && body['data'] != null) {
          setState(() {
            _prescriptionData = body['data'];
            _isGenerating = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _isGenerating = false;
    });
  }

  void _shareOnWhatsApp() async {
    if (_prescriptionData == null) return;
    final rxId = _prescriptionData!['prescription_id'];
    final cropInfo = _prescriptionData!['farmer_crop'] ?? {};
    final bagSummary = _prescriptionData!['bag_summary'] ?? {};
    final curStage = _prescriptionData!['current_active_stage'] ?? '';

    final text = '📋 *AgriShield AI — Fertilizer Prescription*\n'
        'Rx ID: $rxId\n'
        'Crop: ${cropInfo['name']}\n'
        'Land Area: ${cropInfo['land_size_input']}\n'
        'Crop Age: ${cropInfo['age_days']} Days\n\n'
        '👉 *Current Stage Dosage:* $curStage\n\n'
        '📦 *Total Season Bags:*\n'
        '• Urea: ${bagSummary['urea_bags']} Bags (45kg)\n'
        '• DAP: ${bagSummary['dap_bags']} Bags (50kg)\n'
        '• MOP (Potash): ${bagSummary['mop_bags']} Bags (50kg)\n'
        '• Estimated Subsidized Cost: ₹${bagSummary['estimated_cost_inr']}\n\n'
        '🌱 _AgriShield AI — Smart Farm Advisory_';

    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    try {
      await launchUrl(uri);
    } catch (_) {
      Get.snackbar('WhatsApp', 'Unable to open WhatsApp.', backgroundColor: Colors.white);
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
              l10n.fertilizerPrescriptionTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              l10n.fertilizerPrescriptionSubtitle,
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
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.shareOnWhatsApp,
            onPressed: _shareOnWhatsApp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1. Input Form Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: _primaryGreen, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.cropAndFieldSpecs,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryGreen),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Crop Dropdown
                Text(l10n.selectCrop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCrop,
                      items: _cropOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCrop = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Land Size & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.landArea, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _landController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 2.0',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAF8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedUnit,
                                items: _unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedUnit = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Crop Age Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.cropAge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    Text(
                      '${_cropAgeDays.toInt()} ${l10n.days}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _accentGreen),
                    ),
                  ],
                ),
                Slider(
                  value: _cropAgeDays,
                  min: 0,
                  max: 120,
                  divisions: 24,
                  activeColor: _accentGreen,
                  inactiveColor: _accentGreen.withOpacity(0.2),
                  onChanged: (val) => setState(() => _cropAgeDays = val),
                ),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generatePrescription,
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.receipt_rounded, size: 20),
                    label: Text(_isGenerating ? l10n.calculatingDosage : l10n.calculatePrescription),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Prescription Result View ──
          if (_prescriptionData != null) _buildPrescriptionCard(),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    final l10n = context.l10n;
    final rx = _prescriptionData!;
    final rxId = rx['prescription_id'] ?? 'AGRI-RX';
    final date = rx['date'] ?? '';
    final crop = rx['farmer_crop'] ?? {};
    final bags = rx['bag_summary'] ?? {};
    final stages = (rx['stages'] as List?) ?? [];
    final currentStage = rx['current_active_stage'] ?? '';
    final organicTip = rx['organic_booster_tip'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Clinic Prescription Header (Overflow-proof) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(color: _primaryGreen, shape: BoxShape.circle),
                  child: const Text('℞', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AgriShield Farm Clinic',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryGreen),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rx ID: $rxId • $date',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
                  ),
                  child: const Text('ICAR Validated', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop & Land Summary
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildChip('Crop', '${crop['name']}')),
                      Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.2)),
                      Expanded(child: _buildChip('Land Area', '${crop['land_size_input']}')),
                      Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.2)),
                      Expanded(child: _buildChip('Crop Age', '${crop['age_days']} Days')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Bag Summary Header
                Text(
                  l10n.totalSeasonFertilizer,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryGreen),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(child: _buildBagBox(l10n.urea, '${bags['urea_bags']}', '${l10n.bags} (45kg)', const Color(0xFF1976D2))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBagBox(l10n.dap, '${bags['dap_bags']}', '${l10n.bags} (50kg)', const Color(0xFFE65100))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBagBox(l10n.mop, '${bags['mop_bags']}', '${l10n.bags} (50kg)', const Color(0xFF6A1B9A))),
                  ],
                ),
                const SizedBox(height: 8),

                // Cost estimate bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.estimatedCost,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF57F17)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('₹${bags['estimated_cost_inr']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Active Stage Callout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentGreen.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_circle_right, color: _primaryGreen, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.applyThisDosageNow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            Text(currentStage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryGreen)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Stage-by-Stage Timeline
                Text(
                  l10n.stepByStepSchedule,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryGreen),
                ),
                const SizedBox(height: 10),

                ...stages.map((st) {
                  final isCurrent = st['status'] == 'CURRENT';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFF1F8E9) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? _accentGreen : Colors.grey.withOpacity(0.2),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                st['stage_name'] ?? '',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCurrent ? _primaryGreen : Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrent ? _accentGreen : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                st['days_range'] ?? '',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Fertilizers in this stage
                        ...((st['items'] as List?) ?? []).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.check_circle_outline, size: 14, color: _accentGreen),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        children: [
                                          TextSpan(text: '${item['name']}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          TextSpan(text: '${item['total_qty']}', style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryGreen)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        const SizedBox(height: 6),
                        Text(
                          '💡 ${st['instructions']}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic, height: 1.3),
                        ),
                      ],
                    ),
                  );
                }),

                // Organic Booster Tip
                if (organicTip.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.organicBoosterTip, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                              const SizedBox(height: 3),
                              Text(organicTip, style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons (Overflow-proof)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareOnWhatsApp,
                        icon: const Icon(Icons.share, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.snackbar(l10n.fertilizerPrescriptionTitle, 'Prescription saved to farm records.', backgroundColor: Colors.white);
                        },
                        icon: const Icon(Icons.save_alt_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(l10n.saveCopy, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: const BorderSide(color: _primaryGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryGreen)),
        ),
      ],
    );
  }

  Widget _buildBagBox(String title, String count, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
          Text(unit, style: const TextStyle(fontSize: 9, color: Colors.black54), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
