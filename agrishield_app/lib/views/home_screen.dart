import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agrishield_app/views/scan_view.dart';
import 'package:agrishield_app/views/wx.dart';
import 'package:agrishield_app/views/market_view.dart';
import 'package:agrishield_app/views/claims_view.dart';
import 'package:agrishield_app/views/soil_view.dart';
import 'package:agrishield_app/views/profile_view.dart';
import 'package:agrishield_app/views/reports_view.dart';
import 'package:agrishield_app/views/govt_schemes_view.dart';
import 'package:agrishield_app/views/buy_policy_view.dart';
import 'package:agrishield_app/views/recovery_dashboard_view.dart';
import 'package:agrishield_app/views/roi_calculator_view.dart';
import 'package:agrishield_app/views/market_predictor_view.dart';
import 'package:agrishield_app/views/claim_reinvest_view.dart';
import 'package:agrishield_app/views/chatbot_view.dart';
import 'package:agrishield_app/views/spray_advisor_view.dart';
import 'package:agrishield_app/views/fertilizer_prescription_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/language_controller.dart';
import '../config/app_config.dart';
import 'login_view.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final RxInt currentIndex = 0.obs;

  final List<Widget> pages = [
    const ScanView(),
    const Wx(),
    const ClaimsView(),
    const ProfileView(),
  ];

  final List<String> pageTitles = [
    'AgriShield AI',
    'Weather',
    'Claims',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<String> pageTitles = [
      'AgriShield AI',
      l10n.weather,
      l10n.claims,
      l10n.profile,
    ];

    return Obx(() => Scaffold(
          appBar: AppBar(
            title: Text(
              pageTitles[currentIndex.value],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            automaticallyImplyLeading: currentIndex.value == 0,
            actions: [
              IconButton(
                onPressed: () => LanguageController.showLanguageBottomSheet(context),
                icon: const Icon(Icons.translate_rounded, size: 20),
                tooltip: l10n.selectLanguage,
              ),
              IconButton(
                onPressed: () => AppConfig.showServerConfigDialog(context),
                icon: const Icon(Icons.dns_rounded, size: 20),
                tooltip: l10n.serverSettings,
              ),
              if (currentIndex.value == 0)
                IconButton(
                  onPressed: () {
                    currentIndex.value = 3;
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.person, size: 18),
                  ),
                  tooltip: l10n.profile,
                ),
            ],
          ),
          drawer: currentIndex.value == 0 ? _buildDrawer(context) : null,
          body: pages[currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex.value,
            onTap: (index) => currentIndex.value = index,
            selectedItemColor: const Color(0xFF2E7D32),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.camera_alt),
                label: l10n.scan,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.cloud),
                label: l10n.weather,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shield_rounded),
                label: l10n.claims,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: l10n.profile,
              ),
            ],
          ),
        ));
  }

  Widget _buildDrawer(BuildContext context) {
    final l10n = context.l10n;

    return Drawer(
      child: Column(
        children: [
          // ── Drawer Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.eco, size: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AgriShield AI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appTagline,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),

          // ── Menu Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(
                  icon: Icons.camera_alt_rounded,
                  label: l10n.cropScan,
                  emoji: '📷',
                  onTap: () {
                    currentIndex.value = 0;
                    Get.back();
                  },
                ),
                _drawerItem(
                  icon: Icons.cloud_rounded,
                  label: l10n.weather,
                  emoji: '🌤️',
                  onTap: () {
                    currentIndex.value = 1;
                    Get.back();
                  },
                ),
                _drawerItem(
                  icon: Icons.store_rounded,
                  label: l10n.marketRates,
                  emoji: '🏪',
                  onTap: () {
                    Get.back();
                    Get.to(() => const MarketView());
                  },
                ),
                _drawerItem(
                  icon: Icons.landscape_rounded,
                  label: l10n.soilAnalysis,
                  emoji: '🌍',
                  onTap: () {
                    Get.back();
                    Get.to(() => const SoilView(showAppBar: true));
                  },
                ),
                _drawerItem(
                  icon: Icons.account_balance_rounded,
                  label: l10n.govtSchemes,
                  emoji: '🏦',
                  onTap: () {
                    Get.back();
                    Get.to(() => const GovtSchemesView());
                  },
                ),
                _drawerItem(
                  icon: Icons.shield_rounded,
                  label: l10n.buyInsurance,
                  emoji: '🛡️',
                  onTap: () {
                    Get.back();
                    Get.to(() => const BuyPolicyView());
                  },
                ),
                const Divider(height: 20, indent: 16, endIndent: 16),
                _drawerItem(
                  icon: Icons.person_rounded,
                  label: l10n.profile,
                  emoji: '👤',
                  onTap: () {
                    currentIndex.value = 3;
                    Get.back();
                  },
                ),
                _drawerItem(
                  icon: Icons.analytics_rounded,
                  label: l10n.reports,
                  emoji: '📊',
                  onTap: () {
                    Get.back();
                    Get.to(() => const ReportsView());
                  },
                ),
                const Divider(height: 20, indent: 16, endIndent: 16),
                // ── AI Features ──
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                  child: Text(l10n.aiFeatures,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1)),
                ),
                _drawerItem(
                  icon: Icons.water_drop_rounded,
                  label: l10n.sprayAdvisor,
                  emoji: '🌦️',
                  onTap: () {
                    Get.back();
                    Get.to(() => const SprayAdvisorView());
                  },
                ),
                _drawerItem(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.fertilizerPrescription,
                  emoji: '📋',
                  onTap: () {
                    Get.back();
                    Get.to(() => const FertilizerPrescriptionView());
                  },
                ),
                _drawerItem(
                  icon: Icons.healing_rounded,
                  label: l10n.recoveryAdvisor,
                  emoji: '🔬',
                  onTap: () {
                    Get.back();
                    Get.to(() => const RecoveryDashboardView());
                  },
                ),
                _drawerItem(
                  icon: Icons.calculate_rounded,
                  label: l10n.roiCalculator,
                  emoji: '💰',
                  onTap: () {
                    Get.back();
                    Get.to(() => const RoiCalculatorView());
                  },
                ),
                _drawerItem(
                  icon: Icons.auto_graph_rounded,
                  label: l10n.marketPredictor,
                  emoji: '📈',
                  onTap: () {
                    Get.back();
                    Get.to(() => const MarketPredictorView());
                  },
                ),
                _drawerItem(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.claimReinvestment,
                  emoji: '🔗',
                  onTap: () {
                    Get.back();
                    Get.to(() => const ClaimReinvestView());
                  },
                ),
                _drawerItem(
                  icon: Icons.smart_toy_rounded,
                  label: l10n.agriBot,
                  emoji: '🤖',
                  onTap: () {
                    Get.back();
                    Get.to(() => const ChatbotView());
                  },
                ),
                const Divider(height: 20, indent: 16, endIndent: 16),

                // ── Language Switcher Option ──
                _drawerItem(
                  icon: Icons.translate_rounded,
                  label: '${l10n.language} (English / हिंदी)',
                  emoji: '🌐',
                  color: const Color(0xFF1B5E20),
                  onTap: () {
                    Get.back();
                    LanguageController.showLanguageBottomSheet(context);
                  },
                ),

                _drawerItem(
                  icon: Icons.dns_rounded,
                  label: l10n.serverSettings,
                  emoji: '⚙️',
                  color: Colors.blueGrey,
                  onTap: () {
                    Get.back();
                    AppConfig.showServerConfigDialog(context);
                  },
                ),
                const Divider(height: 20, indent: 16, endIndent: 16),

                _drawerItem(
                  icon: Icons.logout_rounded,
                  label: l10n.logout,
                  emoji: '🚪',
                  color: Colors.red,
                  onTap: () async {
                    Get.back();
                    final auth = Get.find<AuthController>();
                    await auth.logout();
                    Get.offAll(() => LoginView());
                  },
                ),
              ],
            ),
          ),

          // ── Footer ──
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AgriShield AI v1.0',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required String emoji,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: color?.withOpacity(0.5) ?? Colors.grey[400],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
