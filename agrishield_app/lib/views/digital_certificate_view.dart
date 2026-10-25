import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/language_controller.dart';

/// Digital Certificate — Farmer ko milega ye receipt after claim submission.
/// QR Code of IPFS CID hash + Enrollment ID + Claim details.
/// "Ye QR code kisi bhi sarkari office mein dikha sakte hain"
class DigitalCertificateView extends StatelessWidget {
  final String enrollmentId;
  final String ipfsHash;
  final String cropName;
  final String disease;
  final String damagePercent;
  final String claimType;
  final String status;
  final String timestamp;
  final String location;

  const DigitalCertificateView({
    super.key,
    required this.enrollmentId,
    required this.ipfsHash,
    required this.cropName,
    required this.disease,
    required this.damagePercent,
    required this.claimType,
    required this.status,
    required this.timestamp,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApproved = status == 'Smart_Contract_Approved' || status == 'Approved';
    final bool isGovt = claimType == 'government';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Digital Certificate'),
        backgroundColor: const Color(0xFF1B5E20),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Certificate Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isApproved ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isApproved
                            ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
                            : [const Color(0xFFE65100), const Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Icon(
                      isApproved ? Icons.verified : Icons.pending,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isApproved ? '✅ Claim Approved' : '⏳ Claim Submitted',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isApproved ? const Color(0xFF1B5E20) : Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isGovt ? '🏛️ Sarkari Rahat' : '🏦 Private Insurance',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // ── QR Code ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: ipfsHash,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1B5E20),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Blockchain Hash (IPFS CID)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: ipfsHash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('📋 Hash copied!')),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  ipfsHash.length > 24
                                      ? '${ipfsHash.substring(0, 24)}...'
                                      : ipfsHash,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Enrollment ID ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Enrollment ID: ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            enrollmentId.isNotEmpty ? enrollmentId : 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Claim Details ──
                  _infoRow('🌾 Crop', cropName),
                  _infoRow('🦠 Disease', disease),
                  _infoRow('⚠️ Damage', '$damagePercent%'),
                  _infoRow('📍 Location', location),
                  _infoRow('📅 Timestamp', _formatTimestamp(timestamp)),
                  _infoRow(
                    '📋 Status',
                    _statusLabel(status),
                    valueColor: isApproved ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Info Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ye QR code kisi bhi sarkari office mein dikha kar apna claim status check karwa sakte hain.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.length > 16) return ts.substring(0, 16).replaceAll('T', '  ');
    return ts;
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Smart_Contract_Approved':
        return '✅ Smart Contract Approved';
      case 'Submitted_to_Govt':
        return '🏛️ Submitted to Government';
      case 'Pending Verification':
        return '⏳ Pending Verification';
      case 'Approved':
        return '✅ Approved';
      case 'Rejected':
        return '❌ Rejected';
      default:
        return s;
    }
  }
}
