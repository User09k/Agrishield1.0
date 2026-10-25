import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/policy_model.dart';
import '../insurance/policy_service.dart';
import '../controllers/language_controller.dart';

/// Buy Policy View — Phase 1 of Private Insurance
/// Step 1: Select crop type + enter area (acres)
/// Step 2: See premium breakdown + GPS auto-capture
/// Step 3: Pay Premium & Activate → blockchain policy record
class BuyPolicyView extends StatefulWidget {
  const BuyPolicyView({super.key});

  @override
  State<BuyPolicyView> createState() => _BuyPolicyViewState();
}

class _BuyPolicyViewState extends State<BuyPolicyView> {
  final _policyService = PolicyService();
  final _storage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _areaController = TextEditingController(text: '5');

  String _selectedCrop = 'Wheat';
  double _premium = 0;
  bool _isLoading = false;
  bool _isPurchased = false;
  String _gpsLocation = '';
  Map<String, dynamic>? _policyResult;

  @override
  void initState() {
    super.initState();
    _calculatePremium();
    _fetchGPS();
  }

  void _calculatePremium() {
    final area = double.tryParse(_areaController.text) ?? 0;
    setState(() {
      _premium = PolicyModel.calculatePremium(_selectedCrop, area);
    });
  }

  Future<void> _fetchGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      setState(() {
        _gpsLocation = '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      print('[GPS] Error: $e');
    }
  }

  Future<void> _purchasePolicy() async {
    if (_gpsLocation.isEmpty) {
      Get.snackbar('📍 GPS Required', 'Location needed to set khet boundary',
          snackPosition: SnackPosition.BOTTOM);
      await _fetchGPS();
      return;
    }

    final area = double.tryParse(_areaController.text) ?? 0;
    if (area <= 0) {
      Get.snackbar('⚠️ Invalid Area', 'Please enter valid area in acres',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final farmerId = _auth.currentUser?.uid ?? '';
      final enrollmentId = _storage.read('enrollment_id') ?? '';

      final result = await _policyService.createPolicy(
        farmerId: farmerId,
        enrollmentId: enrollmentId,
        cropType: _selectedCrop,
        areaAcres: area,
        premiumAmount: _premium,
        gpsLocation: _gpsLocation,
      );

      if (result != null) {
        setState(() {
          _isPurchased = true;
          _policyResult = result;
        });
        Get.snackbar('✅ Policy Activated!',
            'Premium ₹${_premium.toInt()} paid. Policy is now Active.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
      } else {
        Get.snackbar('❌ Error', 'Policy creation failed. Try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('❌ Error', 'Something went wrong: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('🏦 ${l10n.buyInsurance}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: l10n.language,
            onPressed: () => LanguageController.showLanguageBottomSheet(context),
          ),
        ],
      ),
      body: _isPurchased ? _buildSuccessView() : _buildFormView(),
    );
  }

  // ==========================================
  // FORM VIEW
  // ==========================================
  Widget _buildFormView() {
    final area = double.tryParse(_areaController.text) ?? 0;
    final riskLevel = PolicyModel.getCropRiskLevel(_selectedCrop);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Private Crop Insurance',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Smart Contract powered — automatic payout',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🔗 Blockchain Verified • 🤖 AI-Powered',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Step 1: Crop Type ──
          _sectionTitle('Step 1', 'Select Crop Type', Icons.eco, Colors.green),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCrop,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: PolicyModel.supportedCrops.map((crop) {
                  return DropdownMenuItem(
                    value: crop,
                    child: Row(
                      children: [
                        const Text('🌾 ', style: TextStyle(fontSize: 18)),
                        Text(crop, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          PolicyModel.getCropRiskLevel(crop),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PolicyModel.getCropRiskColor(crop),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCrop = val);
                    _calculatePremium();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Step 2: Area ──
          _sectionTitle('Step 2', 'Enter Farm Area (Acres)', Icons.landscape, Colors.brown),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g., 5',
                suffixText: 'Acres',
                suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              onChanged: (_) => _calculatePremium(),
            ),
          ),
          const SizedBox(height: 20),

          // ── GPS Location ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _gpsLocation.isNotEmpty ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gpsLocation.isNotEmpty ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _gpsLocation.isNotEmpty ? Icons.location_on : Icons.location_searching,
                  color: _gpsLocation.isNotEmpty ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gpsLocation.isNotEmpty ? '📍 GPS Captured' : '📍 Fetching GPS...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _gpsLocation.isNotEmpty ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                      if (_gpsLocation.isNotEmpty)
                        Text(_gpsLocation,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                if (_gpsLocation.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    onPressed: _fetchGPS,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Premium Breakdown ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰 Premium Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _premiumRow('Base Rate', '₹500/acre'),
                _premiumRow('Crop', _selectedCrop),
                _premiumRow('Risk Level', riskLevel),
                _premiumRow('Area', '${area.toStringAsFixed(1)} acres'),
                _premiumRow('Trigger Point', '> 70% damage'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Premium',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${_premium.toInt()}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Smart Contract Terms ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Smart Contract Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[800], fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  '• Enrollment ID locked to your account\n'
                  '• GPS boundary set to your current khet location\n'
                  '• Trigger: If AI detects damage > 70%, payout auto-approved\n'
                  '• Contract uploaded to blockchain (IPFS) for tamper-proof record',
                  style: TextStyle(fontSize: 12, height: 1.6, color: Colors.indigo[900]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Pay Button ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _purchasePolicy,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lock, size: 22),
              label: Text(
                _isLoading ? 'Processing...' : 'Pay ₹${_premium.toInt()} & Activate Policy',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // SUCCESS VIEW
  // ==========================================
  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text('🎉 Policy Activated!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('Your ${_selectedCrop} crop is now insured',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 24),

            // Policy details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  _detailRow('Policy ID', _policyResult?['policyId'] ?? 'N/A'),
                  _detailRow('Crop', _selectedCrop),
                  _detailRow('Area', '${_areaController.text} acres'),
                  _detailRow('Premium Paid', '₹${_premium.toInt()}'),
                  _detailRow('Status', '✅ Active'),
                  _detailRow('Trigger', '> 70% damage'),
                  if ((_policyResult?['blockchainHash'] ?? '').isNotEmpty)
                    _detailRow('Chain Hash',
                        (_policyResult!['blockchainHash'] as String).substring(0, 16) + '...'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Whenever your crop is damaged, just Scan it.\nAI will detect the damage and if it exceeds 70%, payout will be auto-approved.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900], height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String step, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(step, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _premiumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
}
