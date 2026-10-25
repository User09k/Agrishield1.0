import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/govt_schemes_controller.dart';
import '../controllers/language_controller.dart';

class GovtSchemesView extends StatelessWidget {
  const GovtSchemesView({super.key});

  /// Launch a URL — works on Web, Android & iOS
  static Future<void> _openLink(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      // Try externalApplication first; fall back to platformDefault for web
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open: $url'),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<GovtSchemesController>()
        ? Get.find<GovtSchemesController>()
        : Get.put(GovtSchemesController());
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.govtSchemes),
        centerTitle: true,
        backgroundColor: const Color(0xFFE65100),
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
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => c.filterSearch(val),
              decoration: InputDecoration(
                hintText: l10n.searchSchemes,
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE65100)),
                filled: true,
                fillColor: const Color(0xFFFFF3E0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // ── Schemes List ──
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFE65100)),
                      const SizedBox(height: 16),
                      Text(l10n.loadingSchemes, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              if (c.filteredSchemes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏛️', style: TextStyle(fontSize: 50)),
                      const SizedBox(height: 12),
                      Text(l10n.noSchemesFound,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => c.fetchSchemes(),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => c.fetchSchemes(),
                color: const Color(0xFFE65100),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: c.filteredSchemes.length,
                  itemBuilder: (ctx, i) => _schemeCard(ctx, c.filteredSchemes[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard(BuildContext context, Map<String, dynamic> scheme) {
    final title = scheme['title'] ?? 'N/A';
    final desc = scheme['description'] ?? '';
    final source = scheme['source'] ?? '';
    final date = scheme['date'] ?? '';
    final link = scheme['link'] ?? '';
    final benefit = scheme['benefit'] ?? '';
    final category = scheme['category'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card body (tappable to open link) ──
          InkWell(
            onTap: link.isNotEmpty ? () => _openLink(context, link) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🏛️', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  if (desc.isNotEmpty)
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Benefit + Category badges
                  if (benefit.isNotEmpty || category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(category,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1A237E),
                                      fontWeight: FontWeight.w600)),
                            ),
                          if (benefit.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('💰 $benefit',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),

                  // Source + date
                  Row(
                    children: [
                      if (source.isNotEmpty) ...[
                        Icon(Icons.language, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            source,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (date.isNotEmpty) ...[
                        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── "View on Govt Website" button (separate tappable row) ──
          if (link.isNotEmpty)
            InkWell(
              onTap: () => _openLink(context, link),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE65100).withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFFE65100)),
                    const SizedBox(width: 6),
                    const Text(
                      'View on Govt Website',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
