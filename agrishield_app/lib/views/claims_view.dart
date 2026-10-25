import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/blockchain_controller.dart';
import '../controllers/language_controller.dart';
import '../l10n/app_localizations.dart';
import 'digital_certificate_view.dart';

class ClaimsView extends StatelessWidget {
  const ClaimsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlockchainController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Obx(() {
        // Show processing overlay
        if (controller.isProcessing.value) {
          return _buildProcessingView(controller, l10n);
        }

        // Show claims list
        if (controller.isLoadingClaims.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (controller.claims.isEmpty) {
          return _buildEmptyState(controller, l10n);
        }

        return _buildClaimsList(controller, l10n);
      }),
    );
  }

  // ==========================================
  // PROCESSING VIEW — 6 Step Progress
  // ==========================================
  Widget _buildProcessingView(BlockchainController c, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '🔗 ${l10n.blockchainNotarization}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),

            // Step progress (6 steps now)
            ...List.generate(6, (i) {
              final step = i + 1;
              final isActive = c.currentStep.value == step;
              final isDone = c.currentStep.value > step;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green
                            : isActive
                                ? Colors.orange
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '$step',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.getStepLabel(step),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFF1B5E20)
                              : isDone
                                  ? Colors.green
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState(BlockchainController c, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () => c.fetchClaims(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                borderRadius: BorderRadius.circular(55),
              ),
              child: const Icon(Icons.shield_rounded, size: 50, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.claims,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.scanCropDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 28),

          // ── File New Claim Buttons ──
          _buildNewClaimSection(c, l10n),
          const SizedBox(height: 24),

          // ── How It Works ──
          _buildHowItWorksCard(l10n),
        ],
      ),
    );
  }

  /// Reusable "File New Claim" section with photo + govt/private buttons
  Widget _buildNewClaimSection(BlockchainController c, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_a_photo_rounded, color: Color(0xFF1B5E20), size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.fileNewClaim,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.scanCropDesc,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // Government Claim Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => c.showClaimPhotoPicker('government'),
              icon: const Icon(Icons.account_balance, size: 22),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏛️ ${l10n.sarkariRahat}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(l10n.govtReliefClaim, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Private Insurance Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => c.showClaimPhotoPicker('private'),
              icon: const Icon(Icons.business, size: 22),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏦 ${l10n.privateInsurance}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(l10n.autoApproveHighDamage, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 ${l10n.howItWorks}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _stepItem('1', '📷 ${l10n.scanCropAiCamera}', Colors.blue),
          _stepItem('2', '📍 ${l10n.gpsLocationCaptured}', Colors.orange),
          _stepItem('3', '🤖 ${l10n.aiDetectsDisease}', Colors.purple),
          _stepItem('4', '🔗 ${l10n.reportUploadedBlockchain}', Colors.teal),
          _stepItem('5', '🛡️ ${l10n.digitalSaboot}', Colors.green),
          _stepItem('6', '🏛️ ${l10n.autoSubmitGovt}', Colors.indigo),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CLAIMS LIST
  // ==========================================
  Widget _buildClaimsList(BlockchainController c, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () => c.fetchClaims(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: c.claims.length + 2, // +1 for new claim, +1 for summary
        itemBuilder: (context, index) {
          if (index == 0) {
            // File new claim section
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildNewClaimSection(c, l10n),
            );
          }
          if (index == 1) {
            // Summary header
            return _buildSummaryHeader(c, l10n);
          }
          return _buildClaimCard(c.claims[index - 2]);
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BlockchainController c, AppLocalizations l10n) {
    final total = c.claims.length;
    final approved = c.claims.where((cl) =>
        cl['status'] == 'Approved' ||
        cl['status'] == 'Smart_Contract_Approved').length;
    final pending = c.claims.where((cl) =>
        cl['status'] == 'Pending Verification' ||
        cl['status'] == 'Submitted_to_Govt').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛡️ ${l10n.claims}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.blockchainVerified,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryChip('Total', '$total', Colors.white),
              const SizedBox(width: 10),
              _summaryChip(l10n.approved, '$approved', Colors.greenAccent),
              const SizedBox(width: 10),
              _summaryChip(l10n.pending, '$pending', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> claim) {
    final status = claim['status'] ?? 'Pending';
    final hash = claim['ipfsHash'] ?? '';
    final crop = claim['cropName'] ?? 'Unknown';
    final damage = claim['damagePercent'] ?? '0';
    final location = claim['location'] ?? '';
    final type = claim['claimType'] ?? 'government';
    final disease = claim['disease'] ?? '';
    final createdAt = claim['created_at'] ?? '';
    final enrollmentId = claim['enrollmentId'] ?? '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Approved':
      case 'Smart_Contract_Approved':
      case 'Payment_Disbursed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Submitted_to_Govt':
        statusColor = Colors.blue;
        statusIcon = Icons.send;
        break;
      case 'Govt_Inspection':
      case 'Under_Review':
        statusColor = Colors.purple;
        statusIcon = Icons.policy;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
    }

    // Calculate tracking stage
    int trackingStage;
    switch (status) {
      case 'Pending Verification':
        trackingStage = 0;
        break;
      case 'Submitted_to_Govt':
      case 'Blockchain_Verified':
        trackingStage = 1;
        break;
      case 'Govt_Inspection':
      case 'Under_Review':
        trackingStage = 2;
        break;
      case 'Approved':
      case 'Smart_Contract_Approved':
      case 'Payment_Disbursed':
        trackingStage = 3;
        break;
      default:
        trackingStage = 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (disease.isNotEmpty)
                      Text(
                        disease,
                        style: TextStyle(fontSize: 12, color: Colors.red[400]),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 4-STAGE TRACKING STEPPER ──
          _buildTrackingStepper(trackingStage),
          const SizedBox(height: 14),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Info rows
          _claimInfoRow(
            Icons.warning_amber,
            'Damage',
            '$damage%',
            int.tryParse(damage.toString()) != null && int.parse(damage.toString()) > 70
                ? Colors.red
                : Colors.orange,
          ),
          _claimInfoRow(
            Icons.category,
            'Type',
            type == 'government' ? '🏛️ Sarkari Rahat' : '🏦 Private Insurance',
            Colors.blue,
          ),
          _claimInfoRow(Icons.location_on, 'GPS', location, Colors.teal),

          // Hash row with copy
          if (hash.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blockchain Hash (IPFS CID)',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          hash.length > 20 ? '${hash.substring(0, 20)}...' : hash,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: hash));
                      Get.snackbar(
                        '📋 Copied!',
                        'IPFS Hash copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.copy, size: 16, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Timestamp
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📅 ${createdAt.length > 16 ? createdAt.substring(0, 16) : createdAt}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],

          // ── View Certificate Button ──
          if (hash.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.to(() => DigitalCertificateView(
                        enrollmentId: enrollmentId,
                        ipfsHash: hash,
                        cropName: crop,
                        disease: disease,
                        damagePercent: damage.toString(),
                        claimType: type,
                        status: status,
                        timestamp: createdAt,
                        location: location,
                      ));
                },
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: const Text('View Digital Certificate',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 4-STAGE TRACKING STEPPER
  // ==========================================
  Widget _buildTrackingStepper(int currentStage) {
    const labels = ['Submitted', 'Blockchain\nVerified', 'Govt\nInspection', 'Payment\nDisbursed'];
    const icons = ['📤', '🔗', '🏛️', '💰'];

    return Row(
      children: List.generate(4, (i) {
        final isCompleted = i <= currentStage;
        final isCurrent = i == currentStage;
        final color = isCompleted ? Colors.green : Colors.grey[300]!;

        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i <= currentStage ? Colors.green : Colors.grey[300],
                  ),
                ),
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(isCurrent ? 1 : 0.7)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.green.shade700, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Text(icons[i], style: const TextStyle(fontSize: 14))
                          : Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.green[800] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (i < 3 && i == 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i + 1 <= currentStage ? Colors.green : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Smart_Contract_Approved':
        return '✅ Auto-Approved';
      case 'Submitted_to_Govt':
        return '🏛️ Govt Submitted';
      case 'Pending Verification':
        return '⏳ Pending';
      case 'Approved':
        return '✅ Approved';
      case 'Rejected':
        return '❌ Rejected';
      case 'Payment_Disbursed':
        return '💰 Paid';
      default:
        return s;
    }
  }

  Widget _claimInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
