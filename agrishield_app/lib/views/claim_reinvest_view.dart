import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/blockchain_controller.dart';
import '../controllers/language_controller.dart';

class ClaimReinvestView extends StatelessWidget {
  final Map<String, dynamic>? claimData;

  const ClaimReinvestView({super.key, this.claimData});

  static const _gold = Color(0xFFFFD700);
  static const _darkBg = Color(0xFF0F1923);
  static const _cardBg = Color(0xFF192734);

  @override
  Widget build(BuildContext context) {
    final bc = Get.isRegistered<BlockchainController>()
        ? Get.find<BlockchainController>()
        : Get.put(BlockchainController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text(l10n.claimReinvestment),
        backgroundColor: const Color(0xFF15202B),
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
        if (bc.isLoadingClaims.value && bc.claims.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        if (bc.claims.isEmpty && claimData == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined,
                    size: 60, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('No claims yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('File a claim from the Scan tab to get started.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          );
        }

        // Use passed claim data or latest claim
        final claim = claimData ?? (bc.claims.isNotEmpty ? bc.claims.first : <String, dynamic>{});
        final cropName = claim['crop_name']?.toString() ?? 'Unknown';
        final disease = claim['disease']?.toString() ?? 'None';
        final damage = claim['damage_percent']?.toString() ?? '0';
        final status = claim['status']?.toString() ?? 'Pending';
        final hash = claim['blockchain_hash']?.toString() ?? '';
        final claimType = claim['claim_type']?.toString() ?? '';
        final payout = _calculatePayout(int.tryParse(damage) ?? 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Header Card ──
              _buildHeaderCard(cropName, disease, damage),
              const SizedBox(height: 24),

              // ── Vertical Stepper ──
              _buildStepper(status, damage, payout, claimType, hash),
              const SizedBox(height: 24),

              // ── Reinvestment Suggestion ──
              _buildReinvestCard(payout),
              const SizedBox(height: 24),

              // ── Blockchain Proof ──
              if (hash.isNotEmpty) _buildBlockchainCard(hash),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(String crop, String disease, String damage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardBg, _cardBg.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: const Center(
              child: Icon(Icons.shield, color: _gold, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          Text(crop,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text('🦠 $disease',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$damage% Damage',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(
      String status, String damage, int payout, String claimType, String hash) {
    final damageInt = int.tryParse(damage) ?? 0;

    // Determine step completion
    final isVerified = hash.isNotEmpty;
    final isPayoutDone = status.contains('Approved') || status.contains('Submitted');
    final isReinvest = isPayoutDone;

    final steps = [
      _StepData(
        title: '🤖 AI Verified Damage',
        subtitle: 'Crop damage: $damage% detected by AgriShield AI',
        isComplete: isVerified,
        isActive: !isVerified,
      ),
      _StepData(
        title: '💰 Insurance Payout',
        subtitle: '₹${_formatNum(payout)}',
        isComplete: isPayoutDone,
        isActive: isVerified && !isPayoutDone,
        isHighlighted: true,
      ),
      _StepData(
        title: '🔄 Suggested Re-investment',
        subtitle: _getSuggestion(damageInt),
        isComplete: isReinvest,
        isActive: isPayoutDone && !isReinvest,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Claim Progress',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) {
            final step = e.value;
            final isLast = e.key == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator + line
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step.isComplete
                            ? const Color(0xFF00E676)
                            : step.isActive
                                ? _gold
                                : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: step.isHighlighted
                            ? [BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 12)]
                            : null,
                      ),
                      child: Center(
                        child: step.isComplete
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text('${e.key + 1}',
                                style: TextStyle(
                                    color: step.isActive
                                        ? Colors.black
                                        : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 50,
                        color: step.isComplete
                            ? const Color(0xFF00E676).withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Step content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        if (step.isHighlighted)
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _gold,
                              shadows: [
                                Shadow(color: _gold.withOpacity(0.5), blurRadius: 20),
                              ],
                            ),
                          )
                        else
                          Text(step.subtitle,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReinvestCard(int payout) {
    final suggestions = [
      {'name': 'Poultry Farm', 'icon': '🐔', 'invest': (payout * 0.4).toInt(), 'roi': '85%'},
      {'name': 'Mushroom Unit', 'icon': '🍄', 'invest': (payout * 0.3).toInt(), 'roi': '120%'},
      {'name': 'Vermicompost', 'icon': '🪱', 'invest': (payout * 0.3).toInt(), 'roi': '90%'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_fix_high, color: Color(0xFF00E676), size: 20),
              SizedBox(width: 8),
              Text('🔄 Smart Re-investment Plan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(s['icon'].toString(), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'].toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text('Invest: ₹${_formatNum(s['invest'] as int)}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('ROI: ${s['roi']}',
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBlockchainCard(String hash) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text('🔗 Blockchain Proof',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hash,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculatePayout(int damage) {
    if (damage >= 80) return 45000;
    if (damage >= 60) return 30000;
    if (damage >= 40) return 20000;
    return 10000;
  }

  String _getSuggestion(int damage) {
    if (damage >= 80) return 'Convert to Poultry Farm + Vermicompost Unit';
    if (damage >= 60) return 'Start Mushroom Cultivation on affected area';
    return 'Diversify with high-value medicinal herbs';
  }

  String _formatNum(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final bool isComplete;
  final bool isActive;
  final bool isHighlighted;

  _StepData({
    required this.title,
    required this.subtitle,
    this.isComplete = false,
    this.isActive = false,
    this.isHighlighted = false,
  });
}
